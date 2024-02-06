---
layout: post
title:  "When Automation Meets Authentication"
date:   "2024-02-06"
author: Richard Fan
toc:    true
---

![Cover image](/assets/images/039c0459-151e-43eb-bb3b-d342fef0330c.jpeg){:style="display:block; margin-left:auto; margin-right:auto"}

## Background

This post is not about sharing my success story or lecturing you about some new things. It's more about summarizing my questions about the conflict between automation and authentication.

### The Recent Trends

Over the past decades, there have been more and more _XxxOps_: **DevOps**, **CloudOps**, **GitOps**, **AIOps**. Recently, I even heard **NoOps**.

The common theme of them is to **Automate everything**. We want people to do as little ops work as possible. We shouldn't even allow people to touch the system in the ideal state.

But at the same time, we have another trend: everything should be verifiable and traceable, and people should be accountable.

We are getting rid of shared accounts and long-term credentials. Use MFA and even hardware keys to prevent spoofing.

But aren't they contradicting? We don't want humans to be involved, but we want humans to be accountable.

### My recent story

As a cybersecurity practitioner, I'm a fan of hardware keys. I have my own Yubikey, and I use it to sign all my git commits so people can verify my works are done by me.

As an engineer, I'm also a fan of automation. I often use IaC and CI/CD to help me deploy stuff.

**But recently, I'm facing a dilemma.**

One of my projects is using the IaC repository as the single deployment point. We also use it to deploy application configuration.

But the question is that there is another repository generating the application configuration.

So I have these options:

1. Merge two repositories.

   But it will make the repository too big and difficult to maintain.

1. Deploy the configurations separately.

   However, it will make my AWS resources fragmented and difficult to track the state of my environment.

   _i.e., No single point of truth on how the current environment state looks like_

1. Have the application repository generate the configuration and push it to the IaC repository for deployment.

   This one looks pretty reasonable to me. So, I picked this route.

## The Problems Come

### How do I sign the git commit?

If the app repository is pushing files, it has to make a commit. As a security engineer, I would like to see all the commits in my repository to be signed.

#### Use GitHub's key?

Now you may say, GitHub bot can sign the commit for me.

But as a security engineer _(Or you can say I'm too paranoid)_, I don't trust the GitHub.com GPG key because who knows how many accounts I'm sharing that same key with?

#### Use stored key?

You may also say, I can put the GPG private key into the GitHub Actions and use it to sign the commit. But this is prone to spoofing because people can sniff the key and use it to sign other things.

#### Hardware key?

Hardware keys can prevent private key leaks, but I can't plug my Yubikey into the GitHub data center and use it in my GitHub actions.

#### Cloud services?

There are many Cloud HSM/KMS offerings, but I can't find any that provide an easy way to integrate with git.

I see HashiCorp Vault support acting as a [PKCS#11 provider](https://developer.hashicorp.com/vault/docs/enterprise/pkcs11-provider){:target="_blank"} and use it as a hardware key with gpg.

I also found an [open-source project](https://github.com/hf/kmspgp){:target="_blank"} wrapping pgp with AWS KMS.

But both options look premature to me, and I'm not sure how the security model should look like, so it behaves as similar as an actual hardware key.

## Who can access the IaC repository?

If the app repository workflow wants to push files to the IaC repository, it must have access to it.

How can I grant it access?

### Interesting GitHub access model

GitHub Actions supports [OIDC authentication](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect){:target="_blank"}, so we can grant the workflow access over other cloud environments (e.g., AWS account) as the workflow itself. (**Without** long-term credentials)

You may think the same should apply to accessing other repositories. Well, the answer is **No**.

To programmatically access a GitHub repository, we can use [Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens){:target="_blank"} or [GitHub App](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/about-authentication-with-a-github-app){:target="_blank"}.

Guess what? Both methods involve long-term credentials.

And unlike OIDC, both methods are not directly tied to the workflow itself.

I even made a joke with my colleague that GitHub workflow integrates better with other cloud providers than itself.

### GitLab is better in this area

GitLab provides two methods for cross-repository workflow.

1. [Multi-project pipelines](https://docs.gitlab.com/ee/ci/pipelines/downstream_pipelines.html#multi-project-pipelines){:target="_blank"}

   This method allows a pipeline to trigger another pipeline in the other project.

1. [Job token allowlist](https://docs.gitlab.com/ee/ci/jobs/ci_job_token.html#add-a-project-to-the-job-token-allowlist){:target="_blank"}

   This method allows the job token from other projects to access itself.

   So the pipeline from other projects can access it.

## This is not unique to GitOps but critical to GitOps

The automation vs authentication issue is not unique to GitOps. There are many companies using automation to sign their software build.

The reasons I think this issue is more critical for GitOps are:

* Git commit is the first step of defense

   The first step a code (whether for software or infrastructure) goes to the codebase is when developers commit it.

   No matter how much defense we build around the system. All other defenses are useless if we cannot verify who created the code.

* The scope is broader

   We may have ten software release pipelines.
   
   But we may also have thousands of developers committing code and hundreds of workflows around them.

   Managing the keys and validating them is more challenging than other use cases.

* Git is everything nowadays

   With the rise of DevOps, IaC, GitOps, etc. We now have more and more kinds of stuff written in code.

   We have application code, configuration, infrastructure, access control list, etc.

   We may face a total system breakdown or takeover if unauthorized code is injected into the repository.

## Wrap up

While I was asking all these questions and doing research. I realized it's not about which method to use, but more about **"Who is the automation"**

One of the differences between 2 GitLab cross-repository workflow methods is that:

**Multi-project pipelines** requires the user triggering the first workflow to have permission on the second repository. And **Job token allowlist** requires the first repository's job to have permission on the second repository.

This also triggers me to think: "Is the automation just a representative of the user? Or it has its own identity?"

Nowadays, we are discouraging shared accounts because we want clear accountability and responsibility. But in the end, automation is still a different form of shared account.

So, what is the line between a shared account and an automation? I don't have a clear answer.

What do you think?
