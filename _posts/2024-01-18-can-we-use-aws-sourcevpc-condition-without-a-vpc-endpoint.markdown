---
layout: post
title:  "Can We Use aws:SourceVpc Condition Without a VPC Endpoint?"
date:   "2024-01-18"
author: Richard Fan
toc:    true
---

## Background

Yesterday, I had an intense discussion with a guy on Slack about "Does IAM [`aws:SourceVpc` condition](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_condition-keys.html#condition-keys-sourcevpc){:target="_blank"} requires a VPC endpoint to work?".

Although the documentation states that _This key is included in the request context only if the requester uses a VPC endpoint to make the request_, it's not obvious that a request originated from a VPC doesn't always have the source VPC information.

It's not mentioned in any AWS documentation about how network context is added to an AWS API request and how it works with IAM policy. But I attended a chalk talk session in last year's AWS re:Inforce on this topic. So, I think it's time to share what I've learned.

![The Chalk Talk session about IAM that I attended in AWS re:Inforce](/assets/images/63374aa3-5367-4183-b489-c7d484039f52.jpg)
_The Chalk Talk session about IAM that I attended in AWS re:Inforce_

## Why is VPC Endpoint required?

The reason is based on 2 things I know about AWS:

1. The way IAM knows the API request's context

1. The route of a network request goes within AWS

### The way IAM knows the API request's context

AWS IAM policy allows us to define permission based on different criteria, like _"Who is making the request?"_, _"Where is the request coming from?"_, _"How is the requester authenticated in the first place?"_, etc.

But AWS IAM service doesn't magically know all these contexts on every API request; it relies on the context that is attached to the request to perform IAM policy evaluation.

According to the chalk talk session, the `aws:SourceVpc` context is added when the API call goes through the VPC endpoint.

![Request contexts are added at different stages of the traffic path](/assets/images/85d12612-0bb7-45c9-9bab-3d03d445dd1e.jpg)
_Request contexts are added at different stages of the traffic path_

## How AWS documentation fails to make its users understand
