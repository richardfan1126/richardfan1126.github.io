---
layout: post
title:  "Breaking change on GitHub Actions pull_request_target"
date:   "2025-11-17"
author: Richard Fan
toc:    true
---

From 8 Dec 2025, GitHub will introduce a [breaking change](https://github.blog/changelog/2025-11-07-actions-pull_request_target-and-environment-branch-protections-changes/){:target="_blank"} on GitHub Actions `pull_request_target` event, here is what you need to know.

## What is `pull_request_target`

GitHub Actions has a family of events triggered by Pull Requests (`pull_request`, `pull_request_review`, `pull_request_review_comment`).

The workflow triggered by these events are running on the workflow definition from the head branch.

In a PR from a fork branch, it means someone who is not the owner of the base repository can run arbitrary workflow in the base repo, which is a security issue.

To mitigate this, those workflows would only have **read access** to the repository and **no access to the repository secrets**.

![pull_request GitHub Actions workflow run](/assets/images/4388bffd-5384-4a6b-a2f0-cd4321485eee.png)

For workflow that need to have write access or secret access, we need to have a trigger that runs on workflow definition from the base branch, so that attackers can't simply raise a PR from a fork repo and inject malicious command into the workflow definition from the head branch.

That's why GitHub introduced `pull_request_target` event trigger.

When a workflow is triggered by `pull_request_target`, the workflow definition is **always from the base branch**, which is in the original repository.

![pull_request_target GitHub Actions workflow run](/assets/images/ec1c71c7-e78e-414d-a231-fbd47124756d.png)

## What is the coming change?

_tl;dr_ The change on `pull_request_target` is that the GitHub Actions workflow triggered by it will **always use the default branch** as base ref instead of the PR base branch.

To understand why GitHub makes such changes, we need to understand the security issue behind.

Imagine we have a repository:

1. It was found that one of its GitHub Actions workflow has a vulnerability. And it is triggered by `pull_request_target`.
1. The maintainer fixed it and merge it to the main branch.
1. However, a branch (`dev`) that was created before the fix still doesn't have the fixed code.
1. An attacker fork the repo, raise a PR to the `dev` branch.
1. The PR trigger a workflow run, using the **unfixed code** from the `dev` branch.
1. And this **trigger the vulnerability**.

![pull_request_target before the change](/assets/images/a9942389-ba86-4b97-9b0e-0c74d76fb59c.png)

This is very common because an active GitHub repo can have hundreds of branches and maintainer can't easily push the fix to all of them.

After the change on 8 Dec 2025, all the workflow triggered by `pull_request_target` will always reference the default branch, so attackers can no longer trigger vulnerable workflow once it's fixed in the default branch.

![pull_request_target after the change](/assets/images/60935818-88d1-4ff4-b79b-13d13c6b05a8.png)

## How does the change affect me?

There are 2 ways this change may affect you:
1. If you reference the `GITHUB_REF` (or `github.ref`) in your workflow, this may affect you

   Because the base ref will always be the default branch after the change, you need to expect all the `pull_request_target` workflow run on the **definition and context of the default branch** regardless of the PR target.

1. If the workflow use GitHub environment with [branch protection](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments){:target="_blank"}

   Because `pull_request_target` workflow will run on the context of the default branch, those run won't unlock environment that **exclude default branch**.

   E.g., if you have a environment only allow `develop` branch to use, the `pull_request_target` workflow from the PR targeting `develop` branch cannot unlock it, because it's running on `main` (the default branch).

### Check your workflows

_(Click to view full diagram)_
[![Check your workflows flowchart](/assets/images/bbbcccd7-987b-4126-9044-832b8ea1d5ce.png)](/assets/images/bbbcccd7-987b-4126-9044-832b8ea1d5ce.png){:target="_blank"}

There is another blog post explaining what you should do to this change: [https://bybowu.com/article/github-actions-pull-request-target-fix-it-by-dec-8](https://bybowu.com/article/github-actions-pull-request-target-fix-it-by-dec-8){:target="_blank"}