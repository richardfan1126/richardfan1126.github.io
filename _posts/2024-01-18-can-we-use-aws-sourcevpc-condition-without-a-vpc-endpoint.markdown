---
layout: post
title:  "Can We Use aws:SourceVpc Condition Without a VPC Endpoint?"
date:   "2024-01-18"
author: Richard Fan
toc:    true
---

![Cover Image](/assets/images/5ad214ee-912e-4ae1-bb2f-c448af1b2c99.png){:style="display:block; margin-left:auto; margin-right:auto"}

## Background

Yesterday, I had a discussion with a guy on Slack about "Does IAM [`aws:SourceVpc` condition](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_condition-keys.html#condition-keys-sourcevpc){:target="_blank"} requires a VPC endpoint to work?".

Although the documentation states that _This key is included in the request context only if the requester uses a VPC endpoint to make the request_, it's not obvious that a request originated from a VPC doesn't always have the source VPC information.

![The documentation states that VPC endpoint is required, but the story doens't stop here](/assets/images/429bc301-b282-47b9-a94d-01ee7adb55ca.jpg)

_The documentation states that a VPC endpoint is required, but the story doesn't stop here_

Although the documentation states the pre-requisite of `aws:SourceVpc`, there are still some confusion. Luckily, I attended a chalk talk session in last year's AWS re:Inforce about this topic. So, I think it's time to share what I've learned.

![The Chalk Talk session about IAM that I attended in AWS re:Inforce](/assets/images/63374aa3-5367-4183-b489-c7d484039f52.jpg)
_The Chalk Talk session about IAM that I attended in AWS re:Inforce_

## Why is VPC Endpoint required?

The reason is based on 2 aspects:

1. The route of a network request goes within AWS

1. The way IAM knows the API request's context

### The route of a network request goes within AWS

![AWS API endpoint is outside the VPC](/assets/images/a209cff0-beec-453d-bd81-1257febbd0ed.jpg)
_AWS API endpoint is outside the VPC_

Many AWS services can be deployed in a VPC (e.g., EC2 instance, RDS instance, ECS task, Elasticache cluster, etc.)

For those resources, we can configure the VPC so that the network traffic should route through or entirely within the VPC to reach the resources. For example, a SQL connection from an EC2 instance to an RDS instance within the same VPC (The green line in the above diagram).

But when it comes to AWS API calls (Let's say an AWS CLI call `aws rds stop-db-instance` from the EC2 instance), it cannot stay within the VPC.

The AWS API call is not going to the resource itself (i.e., _The CLI is not talking to the RDS instance "Hey! I want to stop you"_). Instead, the API is going to an AWS API endpoint (_in this case, `rds.us-east-1.amazonaws.com`_), which is owned by AWS and sits outside of the VPC. (i.e., _The CLI is talking to AWS, "Hey! I want to stop that instance, please do it"_).

To reach the AWS API endpoint, the traffic must either go through the Internet or a VPC endpoint inside the VPC. (The blue line in the above diagram).

We CANNOT create an AWS API endpoint inside a VPC, so there is no such "AWS API call within a VPC" (The red line in the above diagram doesn't exist)

### The way IAM knows the API request's context

AWS IAM policy allows us to define permission based on different criteria, like _"Who is making the request?"_, _"Where is the request coming from?"_, _"How is the requester authenticated in the first place?"_, etc.

But AWS IAM service doesn't magically know all these contexts on every API request; it relies on the context attached to the request to perform IAM policy evaluation.

Those contexts are not attached in one place. It depends on what the context is.

For example, the `aws:MultiFactorAuthPresent` is added inside the session token because when we sign in, the STS service knows if we have MFA authentication and injects this information into the session token.

The `aws:SourceIp` is added when the request reaches the API endpoint because the endpoint can inspect the IP header and determine which IP the request is coming from.

We cannot expect the API endpoint to add the `aws:MultiFactorAuthPresent` because it doesn't know how the user login in the first place. We also cannot expect the STS service to add `aws:SourceIp` into the session token because it won't know where it will be copied and used to sign subsequent API requests.

So, let's come back to the `aws:SourceVpc` context. Who should add this to the request?

Can the EC2 instance do it? It seems possible because AWS knows where the EC2 instance sits. But is it trustworthy? What if the user generates the API request in the EC2 instance, copies it into the laptop, and sends it through the Internet? Should AWS still treat it as "Coming from the VPC"? It seems not feasible.

Can Internet Gateway add this context? But the API request is inside an HTTPS request; how can Internet Gateway decrypt it, add the context, and then re-encrypt it? This is also not feasible.

Can the AWS API endpoint check if the request comes from the EC2 instance's public IP? It seems possible, but keeping track of all public IP addresses is a considerable overhead and would cause performance issues. So this is also not feasible.

So, the only possible way to do it is to let the VPC endpoint add this context to the request.

And according to the chalk talk session, the `aws:SourceVpc` context is added when the API call goes through the VPC endpoint.

![Request contexts are added at different stages of the traffic path](/assets/images/85d12612-0bb7-45c9-9bab-3d03d445dd1e.jpg)
_Request contexts are added at different stages of the traffic path_

## How AWS documentation fails to make its users understand

### Does it really mean the source VPC?

Now we know the `aws:SourceVpc` context is added by the VPC endpoint. So does it really mean "Source VPC"?

Consider the following scenario:

![VPC endpoint sharing](/assets/images/dbde9353-9842-4f1c-ac81-0620eae7bc5e.jpg)
_VPC endpoint sharing_

I have 2 VPCs (`vpc-aaaaaaa` and `vpc-bbbbbbb`) with VPC peering. An STS VPC endpoint in `vpc-aaaaaaa`, and an EC2 instance in `vpc-bbbbbbb`.

Now, I want to restrict an IAM role only to be assumed through the blue route; what should I specify in the IAM policy?

Imagine if I didn't attend the chalk talk session and just read the AWS documentation, which states _Use this key to check whether the request comes from the VPC that you specify in the policy._. I would definitely write my policy as follows:

```json
"Condition": {
    "StringEquals": {
        "aws:SourceVpc": "vpc-bbbbbbb"
    }
}
```

But does it work? I did an experiment:

1. I created an EC2 instance in `vpc-05c07e7f`

   ![](/assets/images/84a706bf-459e-4be8-83ae-7fb64c05d21d.png)

1. I created an STS VPC endpoint in another VPC, `vpc-0c3610a65f744e73f`, which is peered with the first VPC.

   Its private IP address is `10.0.0.186`

   ![](/assets/images/aadd01b8-d839-491e-b112-ecfbb7196528.png)

   ![](/assets/images/18e21b8d-63e6-49cd-bd44-d9f6755bd57b.png)

1. Then I attached an IAM policy into the EC2 IAM role, using `vpc-05c07e7f`, which is the VPC containing the EC2 instance

   ![](/assets/images/0b9b4e21-c66d-4261-8ccb-ff5f95d8b0e8.png)

1. I logged into the EC2 instance and verified the STS request will go to the VPC endpoint IP address.

   Then my `sts:assumeRole` CLI command was denied

   ![](/assets/images/f6f206b4-3b55-4f21-b039-2d29108aa814.png)

1. Then I changed the IAM policy to use `vpc-0c3610a65f744e73f`, which contains the VPC endpoint

   The CLI command was successful this time.

   ![](/assets/images/00fe33ce-c499-47ef-b76e-4851d8ac3f73.png)

   ![](/assets/images/e1a980e4-e34b-48b2-bc18-84b60c59872e.png)

Of course, after learning how request contexts are added, I know why `aws:SourceVpc` is not where the request is really coming from.

The context is added by the VPC endpoint, it doesn't care where the request comes from. As long as the request is going through the VPC endpoint, it will add the VPC ID of itself.

But it clearly doesn't match the documentation description.

## Call for action to AWS

1. **Make the documentation more accurate**

   Clearly, the `aws:SourceVpc` doesn't actually represent _whether the request comes from the VPC...._. So, the IAM team must change the wording.

1. **Publish the process under the hood**

   AWS environment is complex, and it's difficult to explain something within a few lines.

   If someone really wants to customize the AWS environment, the best way to let them understand is to publish the system details.

   I believe if I can learn the request context and IAM condition matching process from a chalk talk session, it's not a secret. So why doesn't AWS publish the whole process in their documentation and let the architect read and decide what their IAM policy and VPC configuration should look like?

1. **Let the appropriate team write the documentation**

   One of the arguing points I had in the discussion is: "Does this `aws:SourceVpc` condition only works on S3?"

   The reason for this argument is that when we read the documentation and want to see more details, it directs us to the S3 documentation: [Restricting Access to a Specific VPC](https://docs.aws.amazon.com/AmazonS3/latest/dev/example-bucket-policies-vpc-endpoint.html#example-bucket-policies-restrict-access-vpc){:target="_blank"}

   Then I asked myself, VPC endpoint is the VPC team's product, and IAM policy is managed by the IAM team, especially when this is a global condition key. So why would the responsibility of explaining it go to the S3 team?

   I understand that maybe the S3 team has written an excellent documentation and the IAM team wants to borrow it.

   But can the IAM team at least give it a stamp and move it into the IAM documentation? So we, as AWS users, can be less confused about whether some features are specific to one service? Or is it common to all services?
