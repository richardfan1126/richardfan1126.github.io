---
layout: post
title:  "My thoughts on AWS re:Invent 2023 announcements"
date:   "2023-12-07"
---

1. [Preface](#preface)
1. [Good ones](#good-ones)
   1. [AWS Security Hub central configuration](#aws-security-hub-central-configuration)
   1. [AWS Security Hub custom control parameters](#aws-security-hub-custom-control-parameters)
   1. [Amazon GuardDuty ECS Runtime Monitoring](#amazon-guardduty-ecs-runtime-monitoring)
   1. [Amazon Inspector agentless vulnerability assessments](#amazon-inspector-agentless-vulnerability-assessments)
1. [Still good ones, but just ... disappointed](#still-good-ones-but-just--disappointed)
   1. [AWS Config periodic recording](#aws-config-periodic-recording)
   1. [Amazon S3 Access Grants](#amazon-s3-access-grants)
1. [GenAI](#genai)
   1. [Guardrails for Amazon Bedrock](#guardrails-for-amazon-bedrock)
   1. [Responsible AI - Amazon Titan image watermark](#responsible-ai---amazon-titan-image-watermark)
   1. [GenAI help cybersecurity](#genai-help-cybersecurity)

![Cover Photo](/assets/images/4f85ce7b-f188-4bbf-a274-69a75d35619a.webp)

## Preface

This year is all about GenAI, and AWS re:Invent is no exception, almost half of the announcements are about GenAI, especially [Amazon Q](https://aws.amazon.com/blogs/aws/introducing-amazon-q-a-new-generative-ai-powered-assistant-preview/){:target="_blank"} _(I still don't like this name)_

However, as a cloud security guy, some other announcements also interest me, and here are my thoughts.

## Good ones

### AWS Security Hub central configuration

Yes! This one! It's not a fancy one, you probably didn't notice it, but this one tops my list.

![Werner Vogels Keynote - Non-functional Requirements](/assets/images/e237ddba-323a-45e3-820d-5f6f70345e66.jpg)

This is the photo I took from Werner Vogels Keynote. Security is one of the non-functional requirements, it's not a feature we can choose, it's about coverage.

I always find it challenging to maintain the security posture within an AWS Organization, there are so many accounts and regions to take care of.

With [AWS Security Hub central configuration](https://aws.amazon.com/blogs/security/introducing-new-central-configuration-capabilities-in-aws-security-hub/){:target="_blank"}, we can now configure security controls across accounts, across regions, all in the same place.

What I love to see in the future is the same feature in Amazon Inspector, GuardDuty, and AWS Config.

### AWS Security Hub custom control parameters

It's Security Hub again. The [custom control parameters](https://aws.amazon.com/about-aws/whats-new/2023/11/customize-security-controls-aws-security-hub/){:target="_blank"} is also a feature that I love to see.

Before this, all Security Hub controls were hard-coded and mostly followed industry standards like CIS, PCI-DSS, and NIST 800-53. 

However, most standards only outline the minimum security requirements, and many organizations want to do better. E.g., the [IAM user password policy](https://docs.aws.amazon.com/securityhub/latest/userguide/iam-controls.html#iam-7){:target="_blank"} is set to a minimum of 8 characters because of the NIST 800-53 standard. But I think most organizations would like their employees to use a longer password.

Now, we can customize the control to check if all the AWS accounts meet the stronger password policy that we set.

### Amazon GuardDuty ECS Runtime Monitoring

The EKS runtime monitoring has already been available since early this year. This time, it's [expanded to ECS](https://aws.amazon.com/blogs/aws/introducing-amazon-guardduty-ecs-runtime-monitoring-including-aws-fargate/){:target="_blank"}.

Many companies don't have the talent to set up threat detection systems themselves, nor the skill to use Kubernetes. Having GuardDuty monitor the ECS workloads would be a nice feature to increase their monitoring coverage.

Besides this, the runtime monitoring for EC2 is also in preview now!

### Amazon Inspector agentless vulnerability assessments

Historically, if we want Amazon Inspector to scan the EC2 instances for software vulnerability, we need to install an SSM agent into it. The agent also uses some of the instance's resources to perform the scanning.

[Agentless scanning](https://aws.amazon.com/about-aws/whats-new/2023/11/amazon-inspector-agentless-assessments-ec2-preview/){:target="_blank"} allows Amazon Inspector to scan the instances without impacting the running instance.

This is not a new feature and has been offered by several 3rd party cloud security vendors. But having an AWS-native tool to do it makes it more accessible to customers.

## Still good ones, but just ... disappointed

### AWS Config periodic recording

The high cost has always been my major complaint to AWS Config. Last week, when AWS announced [AWS Config periodic recording](https://aws.amazon.com/about-aws/whats-new/2023/11/aws-config-periodic-recording/){:target="_blank"}, I thought it would alleviate some of our pain. But after digging deep into the details, I found it probably won't.

First, most of the cost incurred by AWS Config is from the amount of resources we have in the account, not the frequency of changes. So, having a lower recording frequency doesn't really help reduce the cost.


![AWS Config recording price](/assets/images/07469ab4-e76a-4fec-9f4c-b7f8cf299268.png)

Second, the price of every periodic recording is 4x higher than continuous recording. So, if the average change frequency of your resources is at a certain level, periodic recording can cost you even more.

### Amazon S3 Access Grants

I am having issues granting data access through AWS IAM Identity Center (i.e. AWS SSO). The problem is that permission can only be assigned to [Permission Set](https://docs.aws.amazon.com/singlesignon/latest/userguide/permissionsetsconcept.html){:target="_blank"}, and the more granular I want the data access control to be, the more Permission Set I will be creating.

When I saw [Amazon S3 Access Grants](https://aws.amazon.com/blogs/storage/scaling-data-access-with-amazon-s3-access-grants/){:target="_blank"} announcement last week, I thought it would be my savior.

However, after a few trials, I discovered it's quite difficult to set up.

First, we need to create an app in AWS IAM Identity Center to perform some token exchanges and then assume a temporary role to further assume the S3 grant that finally gives you access to the data. (Doc is [here](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-grants-directory-ids.html){:target="_blank"})

Second, all these steps are unavailable in the console, so I'll need my data analysts to do all the complex CLI commands to get the data.

This is a good feature on access control, but it's just too difficult to use.

## GenAI

GenAI is cool. It's the focus this year. But I think we are still uncertain about how it would relate to cybersecurity.

### Guardrails for Amazon Bedrock

With [Guardrails for Amazon Bedrock](https://aws.amazon.com/blogs/aws/guardrails-for-amazon-bedrock-helps-implement-safeguards-customized-to-your-use-cases-and-responsible-ai-policies-preview/){:target="_blank"}, we can set policies to restrict our Bedrock model from using certain topic or contents. We can also use it to redact PII.

I would love to try out how accurate and robust it is. And how it compares to ChatGPT against all the bypass tricks out on the Internet.

### Responsible AI - Amazon Titan image watermark

Last week, AWS announced a new foundation model, [AWS Titan Image Generator](https://aws.amazon.com/blogs/aws/amazon-titan-image-generator-multimodal-embeddings-and-text-models-are-now-available-in-amazon-bedrock/){:target="_blank"}.

AWS claimed that all images generated by this model will have an invisible watermark on them. And we can use it to detect if AI generates that image. It is a great feature to help fight against fake information.

However, to date, I still can't find any details on how we can verify a given image, and how the watermark can withstand image distortion.

### GenAI help cybersecurity

There were many announcements last week on GenAI integrated with different services, like [CloudWatch log query generation](https://aws.amazon.com/about-aws/whats-new/2023/11/amazon-cloudwatch-ai-powered-natural-language-query-generation-preview/){:target="_blank"}, [AWS Config query generation](https://aws.amazon.com/about-aws/whats-new/2023/11/aws-config-generative-ai-powered-natural-language-querying-preview/){:target="_blank"}. I think these capabilities lower the bar of being a security operator on AWS. With more help from GenAI, we no longer need all the engineers to know different query languages to investigate security incidents. With Amazon Q, we can now easily find out what security controls we can or cannot do on AWS without digging into the documents.

But still, I would love to see how AWS can use GenAI to improve cloud security in a more proactive way.
