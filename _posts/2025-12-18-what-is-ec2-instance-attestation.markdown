---
layout: post
title:  "What is EC2 Instance Attestation"
date:   "2025-12-18"
author: Richard Fan
toc:    true
---

![Cover Image](/assets/images/0c08d035-f801-4c32-9dfe-e6600f81007e.png)

In September, AWS announced a new feature, [EC2 Instance Attestation](https://aws.amazon.com/about-aws/whats-new/2025/09/aws-announces-ec2-instance-attestation/){:target="_blank"}.

In this post, we will see what it is and how we can use it.

## What is EC2 Instance Attestation

AWS has another similar feature, Nitro Enclaves, introduced in late 2020 ([News blog post](https://aws.amazon.com/about-aws/whats-new/2020/10/announcing-general-availability-of-aws-nitro-enclaves/){:target="_blank"}). If you don’t know about it yet, you can read my blog post series [#nitro-enclaves](/tag/nitro-enclaves){:target="_blank"}

_tl;dr_ Nitro Enclaves is a trusted execution environment where users can verify, by **Attestation Document**, that it is boot from a said image.

EC2 Instance Attestation is similar to Nitro Enclaves, but instead of running in a container-like environment within the instance, it extends the attestable scope to the entire EC2 instance.

## Differences from Nitro Enclaves

Due to the change of attestation scope, there are a few things we need to understand when using EC2 Instance Attestation:

### 1. More capability

While Nitro Enclaves is a specialized compute environment with limited access to resources, EC2 Instance Attestation is basically the same as a standard EC2 instance.

In Nitro Enclaves, some straightforward tasks may need complex solutions (e.g., deploying a proxy to have outbound connections), or it may even be impossible (e.g., utilizing GPUs)

When using EC2 Instance Attestation, all these limitations are gone since it's just a standard EC2 instance.

### 2. Harder to prove security

In Nitro Enclaves, the environment is **secure by default** (e.g., No admin access, no network connection, no persisten storage), unless we explicitly install something inside (e.g., installed an SSH server so we can have remote access)

But in EC2 Instance Attestation, since it's just another standard EC2 instance, it's **insecure by default**, unless we proactively harden it.

So, when using EC2 Instance Attestation, we need to do more to ensure the instance is secure and tamper-resistant. This can be done by [KIWI NG](https://osinside.github.io/kiwi/overview.html){:target="_blank"}, a descriptive OS appliance builder.

### 3. More complex deployment

To deploy a Nitro Enclave instance, there are only two steps:
1. Build the Enclave Image File (EIF)
1. Run the `nitro-cli` command in a supported EC2 instance to launch the enclave from the EIF

But since EC2 instances are launched from AMIs, we can't simply launch an Attestable EC2 instance from the raw image file. Instead, we need to create the [Attestable AMI](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/attestable-ami.html){:target="_blank"} first.

To deploy an Attestable EC2 Instance, there will be three steps:
1. Build the raw disk image using KIWI NG
1. Build an Attestable AMI from the raw disk image
1. Launch an EC2 instance from the Attestable AMI

Despite the extra step, the [PCR measurements](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/nitrotpm-attestation-document-content.html){:target="_blank"} (i.e., the fingerprints of the image which users use to verify the Attestable EC2 Instance) are tied to the raw disk image. So, the attestation verification step remains the same as Nitro Enclaves.

## Demo

**Demo code is available at: [https://github.com/richardfan1126/ec2-instance-attestation-demo](https://github.com/richardfan1126/ec2-instance-attestation-demo){:target="_blank"}**

This demo project is modified from my [Nitro Enclaves EIF Build Action](/2024/03/03/what-you-see-is-what-you-get-building-a-verifiable-enclave-image.html){:target="_blank"}

I also had a talk about it in JAWS PANKRATION 2024 ([recording](https://www.youtube.com/watch?v=RCIkrTpvNJ4){:target="_blank"})

---

[![Demo architecture](/assets/images/d01975f9-4d27-4ce9-b25b-de0a33a03101.png)](/assets/images/d01975f9-4d27-4ce9-b25b-de0a33a03101.png){:target="_blank"}

The purpose of this demo is to show:
* How a service provider can build and deploy a service that can be verified from source code, build, to deploy stage; and
* How a service consumer can verify those claims by the provider

The demo has 5 parts:
1. Code repository
   * Application code
      * A simple API server providing [NitroTPM attestation document](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/attestation-get-doc.html){:target="_blank"} to users
   * KIWI NG description file
      * Specifying how to build the OS image for the Attestable EC2 instance (e.g., Removing SSH server, etc.)
   * GitHub Actions workflow definition
      * Defining the workflow of building and attesting the raw disk image
1. GitHub Actions workflow
   * Build the raw disk image using KIWI NG
   * Compute the PCR measurements of the raw disk image
   * Push the image and PCR measurments (Artifact) to GitHub Container Registry
   * Attest the artifact using [GitHub Attestation](https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations/use-artifact-attestations){:target="_blank"}
      * This step is **crucial** as it gives users confidence that the PCR measurements used to verify a running EC2 instance is coming from a legitimate source code and build pipeline.
1. Build an Attestable AMI from the artifact
1. Launch an Attestable EC2 instance from the AMI
1. A client app demonstrates the attestation process, retrieves and validates the NitroTPM attestation document from the instance

![Attestation document verification demo](/assets/images/deacbb68-6bfb-49b9-bda3-ce6afb764e08.png)

## My prediction

### More use cases unlocked
With greater capabilities than Nitro Enclaves, I believe EC2 Instance Attestation can unlock more use cases for trusted execution environments.

One of the examples would be LLM since we can utilize GPU features that were not possible in Nitro Enclaves.

### More adoption

Unlike the restrictions on Nitro Enclaves, deploying software on Attestable EC2 Instances would be much easier. We don't need to set up a proxy to expose an API endpoint.

With these conveniences, EC2 Instance Attestation would be adopted by engineers who were previously intimidated by Nitro Enclaves.

Companies that treat security as the utmost priority would still utilize Nitro Enclaves due to its default restrictions, trading convenience for smaller attack surfaces, and better security.
