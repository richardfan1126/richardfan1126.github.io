---
layout: post
title:  "Reusable workflow is good ... Until you realize your identity is also reusable by anyone (2)"
date:   "2024-10-20"
author: Richard Fan
toc:    true
---

In my [previous blog post](/2024/08/02/reusable-workflow-is-good-until-you-realize-your-identity-is-also-reusable-by-anyone.html){:target="_blank"}, we discussed how a GitHub reusable workflow can be used by others to sign their software artifact.

This is interesting but not exciting enough. So, this time, I'm going to show you how a similar misconfiguration can unexpectedly open the door to the cloud environment.

## How OIDC authentication works on the cloud

First, let's revisit how we usually use GitHub OIDC tokens to authenticate into cloud environments.

![GitHub Actions authentication flow with AWS](/assets/images/6bcfa47f-8505-456e-9e16-9a117c57b176.jpg)

Let's use AWS as an example.

1. The GitHub Actions workflow presents the OIDC token to the AWS STS endpoint and requests authentication as an IAM role.
1. AWS STS validates the token and checks if the IAM role trust policy matches the OIDC token claims.
1. If all the checks are passed, AWS STS returns a session token to the GitHub Actions workflow.
1. The workflow uses the session token to access resources in the AWS account.

![AWS IAM role trust policy match GitHub actions OIDC token sub claim](/assets/images/ee2df25d-4f4b-4adf-9965-a2287ad1ca06.jpg)

The most commonly used OIDC claim to identify the calling workflow is the `sub` (i.e. subject), which includes the GitHub organization, repository, branch, and the GitHub Actions environment being used.

The processes in other public cloud providers are similar: validating the token authenticity and then checking the token identity using the `sub` claim.

## Customizing subject claim

We can see that the subject claim of a GitHub Actions OIDC token only contains limited information about the workflow. If we want to get more information about the workflow (e.g., who triggers it), we need to use [other claims](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/about-security-hardening-with-openid-connect#understanding-the-oidc-token){:target="_blank"} (e.g. `actor`).

Unfortunately, most of the cloud providers don't allow us to use those non-standard claims for authentication purposes, which means we can't write our IAM role trust policy to verify if the authenticating workflow is triggered by `richardfan`, as follows:

```json
"Condition": {
  "StringEquals": {
    "token.actions.githubusercontent.com:actor": "richardfan"
 }
}
```

Luckily, in GitHub, we can customize the OIDC subject claim to include other claims.

![Customizing OIDC subject claim](/assets/images/170b456d-9aa7-4924-a44c-0d6a7c9a268d.jpg)

We can use [API call or GitHub CLI](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/about-security-hardening-with-openid-connect#customizing-the-subject-claims-for-an-organization-or-repository){:target="_blank"} to configure what information to include in the subject claim of our GitHub Actions OIDC tokens.

After that, the subject claim of OIDC tokens will look like this:

E.g., If we include `repo` and `actor` in the subject

```json
{
  ...
  "sub": "repo:octo-org/octo-repo:actor:richardfan"
  ...
}
```

And now, we can achieve the access control in the previous example by the following IAM role trust policy:

```json
"Condition": {
  "StringEquals": {
    "token.actions.githubusercontent.com:sub": "repo:octo-org/octo-repo:actor:richardfan"
 }
}
```

## What can go wrong?

As we can see, the subject claim of the OIDC token can be customized to include and **not include** specific claims.

What if someone customizes their OIDC token to include only generic information and uses it as the cloud access control?

E.g., If someone includes only `ref` and `environment` in the OIDC subject claim and uses the following trust policy in the IAM role:

```json
"Condition": {
  "StringEquals": {
    "token.actions.githubusercontent.com:sub": "ref:refs/heads/main:environment:prod"
 }
}
```

Anyone can now create their own GitHub Actions environment called `prod`, a GitHub Actions workflow to assume this IAM role, and push it to the `main` branch.

Then, we can log in to that AWS account.

## Real-world misconfiguration examples

In the previous blog post, we talked about utilizing others' GitHub reusable workflow to sign our artifact.

I was wondering if the same misconception on the `job_workflow_ref` claim can be found on other tasks, and the answer is yes. _(If you want to learn more, read my [previous blog post](/2024/08/02/reusable-workflow-is-good-until-you-realize-your-identity-is-also-reusable-by-anyone.html){:target="_blank"})_

Just like an access control that relies only on `ref` and `environment` claims can be abused, an access control that relies only on `job_workflow_ref` claims can be abused, too.

After some Google search, I found a few blog posts and tutorials guiding people to use `job_workflow_ref` as the condition to authenticate a GitHub Actions workflow to the cloud environment.

Here are some examples:

* [Using OIDC with Reusable Workflows to Securely Access Cloud Resources](https://josh-ops.com/posts/github-actions-oidc-reusable-workflows/){:target="_blank"}
* [How to setup GitHub Actions authentication with AWS using OIDC](https://mymakerspace.substack.com/p/how-to-setup-github-actions-authentication){:target="_blank"}
* [Azure Deployment Using GitHub Actions Reusable Workflows From Central Repo With OIDC](https://medium.com/@tajinder.singh1985/azure-deployment-using-github-actions-reusable-workflows-from-central-repo-with-oidc-8de4cc5a6612){:target="_blank"}


### Using reusable workflow to enforce CI/CD governance

These 3 examples have a similar reason for their design: to enforce CI/CD governance.

In an organization having multiple teams building their own workloads, using the same standard to deploy resources is critical.

Using `job_workflow_ref` as one of the authentication conditions can force all teams to use the same reusable workflow to access cloud environments.

The DevOps team can then implement best practices in the centralized reusable workflow.

![Using reusable workflow to enforce CI/CD governance](/assets/images/0788a4fa-14f8-45d1-b0cd-9a93334e3356.jpg)

### Confused deputy problem

However, using only the `job_workflow_ref` as the access control condition causes a confused deputy situation.

`job_workflow_ref` indicates the location of the GitHub Actions workflow. In a reusable workflow scenario, this would be the location of the reusable workflow.

In the previous example, the OIDC token may look like this:

```json
{
  ...
  "sub": "repo:octo-org/app-team2-repo:...",
  "job_workflow_ref": "octo-org/devops-repo/.github/workflows/deployment-workflow.yml@refs/heads/main"
  ...
}
```

If the repository owner customized the subject claim to include `job_workflow_ref`, it may look like this:

```json
{
  ...
  "sub": "job_workflow_ref:octo-org/devops-repo/.github/workflows/deployment-workflow.yml@refs/heads/main",
  "job_workflow_ref": "octo-org/devops-repo/.github/workflows/deployment-workflow.yml@refs/heads/main"
  ...
```

Now, the cloud authentication system (i.e., AWS STS) can only see which workflow requests a session token but can't see where it is initially triggered.

Is it `app-team1-repo`? Is it `app-team2-repo`? Or is it something else?

Imagine the reusable workflow is called someone else (which can be anyone if the reusable workflow is publicly readable); that person can also authenticate to the cloud environment!

![Broken access control caused by confused deputy problem](/assets/images/9c80e51b-99ba-4c9d-9a52-ceb9aca0f5a6.jpg)

### Try to ... hack

To prove my theory, I followed one of the blog posts I found and tried to access its demo environment.

In that blog post, the author created a reusable workflow to log in to a Microsoft Azure account using OIDC tokens.

![A reusable workflow to access Azure account](/assets/images/dfe769c4-13a7-4d3b-af42-bf82561798ff.jpg)

---

In his demo Azure account, he used `job_workflow_ref` as the only Subject identifier condition and put the location of the reusable workflow hosted in his GitHub repository.

![Using job_workflow_ref as the only condition to authenticate](/assets/images/8eeaf5c5-4378-4c68-b01d-831f2aecad9d.jpg)

---

I created a simple GitHub Actions workflow just to call his reusable workflow.

![I created a simple GitHub Actions workflow to call the reusable workflow](/assets/images/73a28f00-a062-454a-b17f-047e8f82cf46.jpg)

From the screenshot, we can see that my GitHub Actions run can successfully log in to his demo account.

![Successfully login to the Azure account](/assets/images/79f60490-8c73-4a13-b719-984efc419bfe.png)

---

Luckily, this workflow only lists the available secrets in the Azure account and does nothing else. So, even though I can log in to the account, I can't do any damage to it.

However, I found [another blog post](https://medium.com/@tajinder.singh1985/azure-deployment-using-github-actions-reusable-workflows-from-central-repo-with-oidc-8de4cc5a6612){:target="_blank"} suggests using reusable workflow to log in to Azure account and do webapps deployment.

This workflow takes the webapp name and package path as inputs. So, in theory, everyone can put their package in their own repository and use this reusable workflow to deploy it to the owner's Azure account.

![Reusable workflow for Azure webapps deploy](/assets/images/1cf97df9-31c8-4165-be72-edc42336e0ca.png)

I can't verify if that's the case because the demo repository of this blog post has been deleted already.

But whoever follows this blog post ... good luck!

## Wrap up

GitHub Actions reusable workflow is a great way to centralize and standardize CI/CD pipelines.

Having authentication between CI/CD pipelines and cloud environments aware of which reusable workflow is being used helps enforce the standards.

But we need to be careful, using `job_workflow_ref` as the only authentication condition is dangerous.

At the end of the day, we want to know **who** is trying to login, not just **how** they login.

If you are implementing GitHub Actions authentication workflow on cloud, make sure the condition on `sub` claim is restricted as specific as who you want to access your cloud account.

**In most cases, you would always want to check the `repo` claim. So keep it as your access control condition unless you know what you are doing.**
