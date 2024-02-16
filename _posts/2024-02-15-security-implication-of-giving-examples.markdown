---
layout: post
title:  "Security Implication of Giving Examples"
date:   "2024-02-15"
author: Richard Fan
toc:    true
---

![Cover image](/assets/images/c3d9d805-f7da-497e-96b1-817f7b1503c5.png){:style="display:block; margin-left:auto; margin-right:auto"}

In this post, I want to share my thoughts on giving examples in technical writing and the security implications behind it, no matter whether the impact is real or not.

## Background

We will likely give examples when writing technical documents, formal or informal, from user manuals to personal blog posts.

And it's inevitable that the examples contain sensitive or even secret values.

There are many ways we deal with those values (e.g., redacting, modifying, etc.)

I also have many ways of dealing with them throughout my journey, but I slowly build my own convention.

And it all started with this [Linkedin post](https://www.linkedin.com/posts/richardfan1126_aws-activity-7163779862250373121-iybZ?utm_source=share&utm_medium=member_desktop){:target="_blank"}:

AWS rolled back its managed IAM policy **AmazonEC2ReadOnlyAccess**, but it turned out it's because [Scott Piper](https://www.linkedin.com/in/scott-piper-security/){:target="_blank"}, Principal Cloud Security Researcher at Wiz, mistakenly thought the **ec2:GetPasswordData** permission allows users to get the EC2 instance password. And it's due to the poor example AWS gives in their [documentation](https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_GetPasswordData.html){:target="_blank"}.

But instead of blaming AWS for their poor example, I think I should also formalize my own convention and get feedback from others.

## What I am confident that we should follow

The following rules are those I'm pretty confident:

### Do not use mosaic to hide secret

When we want to hide the secrets (i.e., password) on the screenshot, simply redact it with a solid box, **DON'T** use mosaic.

There are many techniques and tools available to reveal text under the mosaic.

* [https://www.toolify.ai/ai-news/avoid-this-password-blur-mistake-95545](https://www.toolify.ai/ai-news/avoid-this-password-blur-mistake-95545){:target="_blank"}

* [https://github.com/HypoX64/DeepMosaics](https://github.com/HypoX64/DeepMosaics){:target="_blank"}

You don't want to reveal your password through your blog post, so just redact it; don't trust the mosaic anymore.

### Do not show a fake secret

If we want to show the secret on the screenshot or example code, without redacting it.

Do not make a confusing fake. Make it evident that it's a fake.

E.g., when we want to give an example of an OAuth token request call

Instead of using this:

```
https://example.com/v1/oauth/token?grant_type=authorization_code
  &code=b87c3c60ca2b54ae
  &client_id=9af83a008718df9b
  &client_secret=af8c86cb8bca211d
  &redirect_uri=https://example.com/callback
```

Try using this:

```
https://example.com/v1/oauth/token?grant_type=authorization_code
  &code=b87c3c60ca2b54ae
  &client_id=9af83a008718df9b
  &client_secret=<your_client_secret>
  &redirect_uri=https://example.com/callback
```

Or this:

```
https://example.com/v1/oauth/token?grant_type=authorization_code
  &code=b87c3c60ca2b54ae
  &client_id=9af83a008718df9b
  &client_secret=****************
  &redirect_uri=https://example.com/callback
```

Although all 3 examples do no harm to ourselves because the `client_secret` are all fake.

But the readers with little knowledge of OAuth may not know that `client_secret` is something they shouldn't expose.

And by seeing us showing the secret in the example, they may just follow and show their **REAL** secret to others.

The other implication I believe is that, many people _(including me)_ is generous to inform people when they find something sensitive is posted online _(Not just technical stuff, I've DM many people on social media to take down the photos of their boarding pass)_.

If I message a blog owner to be careful of their secret and get a reply that it's fake. I would feel being fooled and may have less willingness to do the same thing next time, even though it may be the true secret.

## What I am doing but you may have better options

The following rules are what I am following, but not quite sure if they are the best options.

You may argue that my reasons are wrong and have better options.

### Use common pattern for personal values

This is similar to [Do not show a fake secret](#do-not-show-a-fake-secret), but for some personal data (e.g. AWS account ID, AWS resource ARN).

These data are not secrets, but we still don't want to expose them to the public.

We can use the same method as dealing with secrets, but it may make the example difficult to read.

So, I would use some common patterns to replace those data.

E.g., If I were to give an AWS CLI command example of creating an EC2 instance, I can write:

```
aws ec2 run-instances \
   --image-id <ami_id> \
   --subnet-id <subnet_id> \
   --instance-type <instance_type> \
   --key-name <key_pair_name>
```

It's still useful, but if I use the following format, it would be more useful because the reader can understand the format of each value and find them more easily.

```
aws ec2 run-instances \
   --image-id ami-11111111111111111 \
   --subnet-id subnet-22222222 \
   --instance-type c5.xlarge \
   --key-name my-key-pair-01
```

### Dealing with encoded values

For encoded or even encrypted values, I still don't have a good option to make the example similar to the real one yet obvious to the reader that it's fake.

E.g., If I use the same method as dealing with secret values, I may write this:

```
password_b64: <your_password>
```

But then the reader doesn't know it's a base64-encode value.

If I use the base64-encode `<your_password>`, like this:

```
password_b64: PHlvdXJfcGFzc3dvcmQ+
```

Then, the users may not know it's a secret, and they shouldn't expose theirs.

So right now, what I would write is:

```
password_b64: <base64_encoded_password>
```

If you have more explanatory options, please let me know.

## Wrap up

These are just the rules I found easy for readers to understand yet not making security concerns.

I see many ways of making examples, even across AWS service teams.

I really hope we'll have a more standardized way of giving examples (especially when secrets are involved) on technical writing, like the one for [Git commit message](https://www.conventionalcommits.org/en/v1.0.0/){:target="_blank"}.

Please feel free to share your thoughts.
