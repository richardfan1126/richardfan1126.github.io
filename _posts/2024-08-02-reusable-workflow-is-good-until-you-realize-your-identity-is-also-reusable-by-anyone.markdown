---
layout: post
title:  "Reusable workflow is good ... Until you realize your identity is also reusable by anyone (1)"
date:   "2024-08-02"
author: Richard Fan
toc:    true
---

![Cover image](/assets/images/34416564-5355-4060-999c-5284caea04b0.png){:style="display:none"}

In this post, I want to share a way people can use our GitHub Actions workflow to sign their own artifacts and confuse consumers into thinking they're signed by us.

## Keyless signing

First of all, let's talk about keyless signing.

Usually, when we want to prove that a software artifact is produced by us, we sign it with a known private key and let the consumer verify it with the corresponding public key.

### Sigstore

In recent years, [sigstore](https://www.sigstore.dev/){:target="_blank"} has become more and more popular, and the concept of keyless signing is being used more broadly.

The idea of sigstore is to establish a Certificate Authority we all trust (i.e., [Fulcio](https://docs.sigstore.dev/certificate_authority/overview/){:target="_blank"}). When we want to sign something, we request a signing certificate from Fulcio to sign it.

In this way, we don't need to worry about keeping a long-term signing key and distributing the public key to consumers. We just need to trust Fulcio's Public Key Infrastructure (PKI).

### Use of OIDC token

To prove the identity of the signing entity, sigstore uses the OIDC token.

In the scenario of this post, the signing entity would be the GitHub Actions workflow, which builds and signs the artifact. The workflow presents the [GitHub Actions OIDC token](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect){:target="_blank"} to Fulcio. Fulcio then generates a short-lived signing certificate using the token's information and responds to the workflow.

As consumers, we verify the software artifact against the signing certificate and check the certificate's identity to decide whether to trust it.

---

![Oversimplified diagram of sigstore keyless signing](/assets/images/4be1e1aa-f03c-43af-963a-7ac0dc5dd401.jpg)

<div align="center">
An oversimplified diagram of sigstore keyless signing
</div>

## GitHub Actions reusable workflow

Now, let's talk about the other part: GitHub Actions reusable workflow.

You may already know what is [GitHub Actions](https://github.com/features/actions){:target="_blank"}. It is a CI/CD platform on GitHub that we can use to build software based on the workflow we create.

In GitHub actions, a workflow is a set of steps performed in the build environment. A CI/CD pipeline may consist of multiple workflows that run independently in separate build environments. For example, a software build pipeline may consist of build workflows for building its Windows and Linux versions on 2 different workflows.

Some workflows are quite common, like building and pushing docker images into Docker Hub. Instead of rewriting the same workflow on every repository, we can use [reusable workflow](https://docs.github.com/en/actions/using-workflows/reusing-workflows){:target="_blank"}. A reusable workflow is basically a modified workflow definition, which can be called by another workflow, regardless of whether it's in the same repository.

![GitHub reusable workflow](/assets/images/864365b4-9feb-4e10-bb39-0318819aa70c.jpg)

## What is the identity of a reusable workflow?

Now let's ask a question: **If we use sigstore to sign an artifact in a reusable workflow from the other repository, who is actually signing the artifact?**

### Signing certificate for GitHub Actions

First, let's take a look at how a Fulcio signing certificate for a GitHub Actions workflow looks like.

In my [sample app repository](https://github.com/richardfan1126/how-high-is-my-salary-enclave-app){:target="_blank"}, I use GitHub Actions and sigstore to sign the artifact, here is the snippet of the signing certificate (Full certificate can be found [here](https://search.sigstore.dev/?logIndex=93699852){:target="_blank"}):

```
Signature:
  Issuer: O=sigstore.dev, CN=sigstore-intermediate
  ...
  X509v3 extensions:
  Subject Alternative Name (critical):
    url:
      - https://github.com/richardfan1126/how-high-is-my-salary-enclave-app/.github/workflows/build-and-sign-eif.yaml@refs/heads/main
  OIDC Issuer: https://token.actions.githubusercontent.com
  GitHub Workflow Repository: richardfan1126/how-high-is-my-salary-enclave-app
  ...
```

* `OIDC Issuer`: This is the identifier of the GitHub OIDC issuer, which can be used to verify the signing certificate is issued to a GitHub Actions workflow
* `GitHub Workflow Repository`: This is the name of the repository **triggering the workflow**
* `Subject Alternative Name`: This is the entity which the signing certificate issued to. It is the **location of the workflow definition**

Because I'm using a workflow I wrote to sign the artifact, **GitHub Workflow Repository** and **Subject Alternative Name** point to the same repository in this case.

### How about reusable workflow from another repository?

Now, let's take a look at a more interesting case.

In the same repository, I also have another workflow signing the artifact using a reusable workflow hosted on [slsa-framework/slsa-github-generator](https://github.com/slsa-framework/slsa-github-generator){:target="_blank"}.

This time, the signing certificate looks like this (full certificate can be found [here](https://search.sigstore.dev/?logIndex=93701584){:target="_blank"}):

```
Signature:
  Issuer: O=sigstore.dev, CN=sigstore-intermediate
  ...
  X509v3 extensions:
  Subject Alternative Name (critical):
    url:
      - https://github.com/slsa-framework/slsa-github-generator/.github/workflows/generator_container_slsa3.yml@refs/tags/v2.0.0
  OIDC Issuer: https://token.actions.githubusercontent.com
  GitHub Workflow Repository: richardfan1126/how-high-is-my-salary-enclave-app
  ...
```

We can see the **GitHub Workflow Repository** is still my repository, but the **Subject Alternative Name** now points to another repository, which is the one hosting the reusable workflow.

## Impacts

### Repository owner

If you own a public GitHub repository that uses reusable workflows to sign artifacts, you need to prepare when someone uses the identity of **your workflow** to sign something.

What makes things worse is the lack of access control on reusable workflows. GitHub provides an [option](https://docs.github.com/en/actions/using-workflows/reusing-workflows#access-to-reusable-workflows){:target="_blank"} to restrict **what reusable workflow a repository can use**, but there is no option on **who can use my reusable workflow**. So your reusable workflow can only be public or private, depending on the repository visibility.

### Artifact consumer

You may ask: The signing certificate has the **GitHub Workflow Repository** field showing who is actually triggering the workflow. Can't we just check that to verify the signature authenticity?

You are right ... partially.

In fact, the tool which performs signing and verification, [cosign](https://docs.sigstore.dev/signing/quickstart/){:target="_blank"}, provides a flag `--certificate-github-workflow-repository` for the consumer to check which repository actually triggered the signing workflow.

E.g., We can run the following command to check if an artifact is signed by my app repo:

```bash
cosign verify "<image_uri>" \
    --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
    --certificate-github-workflow-repository "richardfan1126/how-high-is-my-salary-enclave-app"
```

But the sad truth is that I can find many use cases where the verification only relies on the certificate identity (i.e., using the `--certificate-identity` or `--certificate-identity-regexp` flag).

In this case, if the software producer uses a reusable workflow that can be called by other repositories, attackers can call that workflow to sign their artifact. The malicious artifact can still pass the verification process because the identity of the signing certificate **is still the same legitimate workflow**.

---

![Diagram of the attack path](/assets/images/7a93f9f7-6f6d-4260-a076-d1055ac4f061.jpg)

<div align="center">
Diagram of the attack path
</div>

## How serious is this issue?

The short answer is: Not so serious.

### Public reusable workflow is not always callable

Simply publishing a reusable workflow doesn't always mean anyone can call it.

E.g. if the reusable workflow has a step checking the `github.repository` variable, it can detect who is calling the workflow and may reject any workflow call from unintended repositories.

In my research, I've also found another interesting way (*I don't know if it's intended or not*) to prevent calls from external repositories

### Signature is just one part of the defense

Just like putting a checksum of a malicious binary onto the software homepage doesn't make people download that binary, creating a new signed artifact doesn't mean it can go to the package repository.

Most of the sigstore signing workflows I found are designed to sign the container images or software binaries that are hosted on container registries or GitHub Release.

So unless you also obtain their registry credentials, simply signing your artifact using their workflow doesn't cause actual harm to them.

However, the purpose of artifact signing is to protect the artifact's authenticity. If we fall back to package repository access control, the whole idea of artifact signing would be meaningless. So, I would still say it's a real problem.

## Is this issue common?

After discussion on theory, so is this issue common in the wild?

To answer this question, we can look into 2 aspects: Repository owners and artifact consumers.

### For repository owners

Searching on Sourcegraph, I can find ~80 public GitHub repositories using sigstore signing in reusable workflows.

Are they all vulnerable? No.

I've just tried using workflows on repositories with more than 1k stars to sign my dummy Hello World container image.

Some repositories failed because of non-security-related restrictions. Some failed because their workflows were not completed yet, although they are moving towards a vulnerable implementation, which is still not good.

But interestingly, I found 2 repositories vulnerable, and I can successfully sign my image using the identity of their reusable workflows. Although these 2 repositories are hosting their artifact in places I have no access, I still reported to their maintainer.

#### argo-cd

The first vulnerable repository I found is [**argoproj/argo-cd**](https://github.com/argoproj/argo-cd){:target="_blank"}.

In their **Publish and Sign Container Image** reusable workflow, there is a [**Sign container images**](https://github.com/argoproj/argo-cd/blob/f1105705126153674c79f69b5d9c9647360d16f5/.github/workflows/image-reuse.yaml#L161-L171){:target="_blank"} step.

In their [documentation](https://github.com/argoproj/argo-cd/blob/77899cb285ed078282406be12b8a2728a4d0f735/docs/operator-manual/signed-release-assets.md#verification-of-container-images){:target="_blank"}, they only suggest the following cosign command to verify their container images

```bash
cosign verify \
  --certificate-identity-regexp https://github.com/argoproj/argo-cd/.github/workflows/image-reuse.yaml@refs/tags/v \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  quay.io/argoproj/argocd:v2.7.0 | jq
```

I forked the repository and made 2 changes:

* Changing the parent GitHub Actions step to use the original reusable workflow ([git commit](https://github.com/argoproj/argo-cd/commit/10747890d9af8e320597b68690aac30a47bd8d63){:target="_blank"})

* Changing the **Dockerfile** content ([git commit](https://github.com/argoproj/argo-cd/commit/67f5e0be25393cc82588e02f7cae14c322092875){:target="_blank"})

After that, a GitHub Actions run created my own image signed with the identity `https://github.com/argoproj/argo-cd/.github/workflows/image-reuse.yaml` and can pass the verification.

![Modified image passing the image verification](/assets/images/9d2ceaff-5f39-474b-a604-5dcef2e5a0d0.png)

After contacting the maintainer, they have changed the suggested image verification step to include the flag `--certificate-GitHub-workflow-repository "argoproj/argo-cd"` ([git commit](https://github.com/argoproj/argo-cd/commit/587c5ba1c68681ef0ecfac5c4486868d6f14ffba){:target="_blank"})

#### bank-vaults

The other vulnerable repository I found is [**bank-vaults/bank-vaults**](https://github.com/bank-vaults/bank-vaults){:target="_blank"}

To demonstrate the vulnerability, I did the similar things as I did on argo-cd: [Changing the parent workflow to call the original workflow](https://github.com/bank-vaults/bank-vaults/commit/6c3376949550daba0522850fd07beeb89c9b4eda){:target="_blank"} and [Modify the Dockerfile](https://github.com/bank-vaults/bank-vaults/commit/2d560d14a67cb9fcc80a2fcd0351890b664ecf8e){:target="_blank"}

After that, I also got my modified image built and signed with the identity `https://github.com/bank-vaults/bank-vaults/.github/workflows/artifacts.yaml@refs/heads/main` and passed the verification.

![Modified image passing the image verification](/assets/images/661e87c0-946f-4818-8f95-e4f19f95310f.png)

After reporting to the maintainer and waiting a week without further follow-up, I created a PR myself.

The fix is quite simple; just check the caller identity before running the image signing step: [Pull request](https://github.com/bank-vaults/bank-vaults/pull/2826){:target="_blank"}. Eventually, they merged the PR and fixed the issue.

### For consumers

For consumers, we cannot predict how they will verify the signature and certificate, so it's hard to tell how common this issue is.

But let's look at how software providers suggest their users verify their software. Many of them suggest checking only the certificate identity instead of the repository triggering the signing workflow.

To be specific, they are suggesting the following command:

```bash
cosign verify <artifact_uri> \
    --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
    --certificate-identity "https://github.com/<owner>/<repo>/<signing_workflow_path>"
```

instead of

```bash
cosign verify <artifact_uri> \
    --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
    --certificate-github-workflow-repository "<owner>/<repo>"
```

Luckily, most of them are not using reusable workflow to sign their artifact, so the certificates bearing their repository name are almost guaranteed to be authentic.

Since it's not a real vulnerability, I'm going to list some of them here:

* Trufflehog ([Link](https://github.com/trufflesecurity/trufflehog/blob/main/scripts/install.sh#L349){:target="_blank"})
* Trivy ([Link](https://github.com/aquasecurity/trivy/blob/main/docs/getting-started/signature-verification.md#verifying-signed-container-images){:target="_blank"})
* OpenTelemetry Collector ([Link](https://github.com/open-telemetry/opentelemetry-collector?tab=readme-ov-file#verifying-the-images-signatures){:target="_blank"})
* Kong ([Link](https://docs.konghq.com/gateway/latest/kong-enterprise/signed-images/#minimal-example){:target="_blank"})
* Timoni ([Link](https://timoni.sh/cue/module/signing/){:target="_blank"})

Although their suggested verification process is not vulnerable now, they are simply sitting here waiting for their signing workflow to become callable one day, rendering the process meaningless.

## How can I protect my workflow?

### Do not use reusable workflow to perform sigstore signing

The root cause of the issue is reusable workflows being called by external repositories.

So the most effective way to protect your workflow is to perform signing on a normal workflow instead of a reusable workflow.

### Check the calling repository in the reusable workflow

If reusable workflow is your only option, include an extra checking step before the signing step.

The checking step can verify the `github.repository` variable to check if it is called by an intended repository.

This can prevent external actors from using your workflow to sign their artifacts.

### Checking repository when verifying artifact signing certificate

The certificate includes the name of the repository that triggers the signing action. So, when verifying the signature, include the flag `--certificate-github-workflow-repository` to check if it is the intended one.

## Wrap up

The issue discussed in this post is not serious nor widespread.

But considering the rising trend of keyless environments, software signing, cloud-based CI/CD pipeline, and the use of OIDC tokens, I foresee there will be more and more keyless signing use cases in the future.

My suggestion to security practitioners and DevOps engineers is to learn more about cloud-based identity and CI/CD security.

If your organization currently uses GitHub Actions, especially when using public reusable workflows, do the threat modeling on it. Consider how attackers may access and use it.

Lastly, for GitHub, I would strongly push for access control features on reusable workflow.

## What's next

Although this vulnerability helps attackers sign artifacts with victims' identities, it doesn't give attackers access to the actual cloud resources (e.g., image repositories, cloud environments, etc.).

But I was wondering if such mistakes also happen in cloud access control. Surprisingly, I can find some use cases where people mistakenly use the GitHub workflow identity as the sole principle for granting access to their cloud environment.

I will talk about it in my next blog post.
