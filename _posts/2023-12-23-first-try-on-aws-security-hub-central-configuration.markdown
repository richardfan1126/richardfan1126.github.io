---
layout: post
title:  "First Try on AWS Security Hub Central Configuration"
date:   "2023-12-23"
author: Richard Fan
toc:    true
---

In my previous [post](/2023/12/07/my-thoughts-on-aws-reInvent-2023-announcements.html#aws-security-hub-central-configuration){:target="_blank"}, I've mentioned the new AWS Security Hub Central Configuration feature. I thought AWS finally solve the headache we face when managing Security Hub in cross-account, cross-region environments. It's kind of true, but not a lot.

## Help us manage security controls in one place

Let's talk about the good first. Security Hub central configuration helps us manage the security controls on different accounts, different regions.

When we enable central configuration, we can pick the regions and the policy we create later will be deployed to the selected regions

![Select regions to deploy configuration](/assets/images/b1693d52-aba7-47d0-903b-6b70c267d01e.png)

We can then create different policy on:

* What security standards to deploy

* What controls to enable/disable

* Customize control parameters

![Setting configuration policy](/assets/images/f4bd32ea-5255-412a-8f94-a19b695b9f73.png)

These policies can be deployed to all accounts or the accounts we specify, so we can configure different accounts differently.

![Deploy policy to specified accounts](/assets/images/8a7d7a12-5151-40e8-a59d-79142fc1dd44.png)

## The caveats

OK, we've finished talking about the good part. Let's talk about the dark side.

### Don't forget to enable AWS Config if you want to get findings

So the AWS [blog post](https://aws.amazon.com/blogs/security/introducing-new-central-configuration-capabilities-in-aws-security-hub/){:target="_blank"} claimed we can _"using a single action to enable Security Hub across your organization"_

![AWS blog claimed we can enable Security Hub across organization using a single action](/assets/images/8827cf83-ce12-4996-b611-f488cd699889.png)

Right, but it only turns on Security Hub, if we want to get findings, we still need to enable AWS Config on all the accounts, ... manually.

![Enabling AWS Config is still manually](/assets/images/2f5d6826-345d-4ef9-9ef1-c4c32d7fc1fc.png)

OK, fine!! So I scrolled down a little bit and found this.

_"if AWS Config is not yet enabled in an account, the policy will have a failed status."_

![Failure when AWS Config is not enabled](/assets/images/f2fbee64-e81f-486f-813b-9cded119c0da.png)

I then tried to deploy Security Hub on my AWS Organization, which I only turned on Config on 1 account.

Guess what? I got the green lights for all 3 accounts.

![Deployment success even some accounts don't have Config enabled](/assets/images/b2da5bbb-631e-4aa1-8ecd-b4dd2a858abc.png)

I thought, maybe I forgot that I had enabled Config on these accounts, or maybe Security Hub helped my turned them on?

So I waited 2 days for the findings to come. But then, the account which had Config enabled already have many findings, but the 2 without Config only got 17 findings.

![Accounts without Config only got 17 findings](/assets/images/3e828951-ecc2-49d9-b360-a690d3d86af4.png)

So I went on and use CloudFormation StackSet to enable AWS Config for these 2 accounts.

And at that point, I was quite sure AWS Config was not enabled because the StackSet won't succeed if so.

I don't know what's going wrong, but after enabling AWS Config, the findings finally came.

![Findings started coming after enabling AWS Config](/assets/images/abaeb29b-0991-4dda-a43b-e59de511afe3.png)

I still don't understand why the error message didn't come.

But the main takeaway here is: **Make sure you have AWS Config enabled on all relevant accounts if you want to get findings from AWS Security Hub**

### Use the right template

Another interesting point (but not related to this new feature) is the template we use to enable AWS Config.

In the CloudFormation StackSet console, there is a sample template called "Enable AWS Config".

But if you only want to get AWS Security Hub findings, **DON'T** use it.

![Don't use the default StackSet template to enable AWS Config](/assets/images/4278c5ad-012d-48c1-a1fc-5152ac73b7e5.png)

There is another StackSet template [here](https://github.com/aws-samples/aws-cfn-for-optimizing-aws-config-for-aws-security-hub/blob/main/AWS-Config-optimized-for-AWS-Security-Hub.yaml){:target="_blank"}.

This template only enable configuration recording on resource types that Security Hub cares.

Using this one could save you money by not recording resource that Security Hub doesn't look at.

## Painful experiment

So, now I still can't figure out why my child accounts could pass the checking even AWS Config was not enabled.

I'll need to create another clean AWS Organization to test out.

Experimenting things on Cloud Governance is really a painful task.

I can't simply nuke the resources to restart because what I'm testing is the Organizations, the accounts.

And now, I need to restart everything again.
