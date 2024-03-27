---
layout: post
title:  "Running Python App on AWS Nitro Enclaves"
date:   "2020-11-03"
author: Richard Fan
toc:    true
tags:   nitro-enclaves
---

# What is AWS Nitro Enclaves

AWS Nitro Enclaves is an isolated compute environment running beside the EC2 instance. It uses the CPU and memory resources from your EC2 instance, but it is isolated from the instance on the hypervisor level so that your instance cannot access the enclave even on the OS-level. The only way you can communicate with the enclave is through the vsock channel.

[AWS News Blog: AWS Nitro Enclaves – Isolated EC2 Environments to Process Confidential Data](https://aws.amazon.com/blogs/aws/aws-nitro-enclaves-isolated-ec2-environments-to-process-confidential-data/){:target="_blank"}

![A high-level overview of AWS Nitro Enclaves (From AWS documentation)](/assets/images/1e74931d-99bb-453e-92fb-d9147e7c4ce7.png)

A high-level overview of AWS Nitro Enclaves (From AWS documentation)

## What's that mean?

To better understand the concept, we can treat the enclave as a docker container. We can bake our custom applications into an image and run it in the enclave just as we run docker image in a container.

The thing different is that you cannot access this special container's console, files, metrics, etc. It doesn't have a network interface nor persistent storage too.

The only thing you can do with it is:

1. Running application

1. Communicate with the outside world through the dedicated socket tunnel.

# Why we need AWS Nitro Enclaves

To protect confidential data, we always encrypt our data. But when we use the data, we need to decrypt it in somewhere.

Normally, we will decrypt the data as close as possible to the place we use it, so to minimise the chance of leaking plain-text data.

However, for separation of duty, we also don't want the secret handling process stay too close to other parts of the system.

Imagine if we put the payment processing system inside the e-shop web server. The web server admin can always use "god mode" (or what we called sudo) to access log files.

AWS Nitro Enclaves provides a safe environment (No one can access it) near the core application (Within the same instance). Solving the dilemma of putting secret handling process far away from or close to the main system.

# Why I am writing this Python demo?

[Link to GitHub Repository](https://github.com/richardfan1126/nitro-enclave-python-demo){:target="_blank"}

After the AWS Nitro Enclaves become GA, I immediately tried it out. However, when I studied the GitHub repositories, I felt very frustrated because the codes are written in either C or Rust. And the KMS API call part is even re-implementing the HTTP handling.

1. https://github.com/aws/aws-nitro-enclaves-sdk-c

1. https://github.com/aws/aws-nitro-enclaves-samples

![The SDK sample uses C to re-implement the entire HTTP handling](/assets/images/f437bc26-0096-490d-9483-7116cbdf4375.jpeg)

The SDK sample uses C to re-implement the entire HTTP handling

I felt like I'll need a month to write my hello world program as simple as calling an HTTP API, especially when I use Python.

So I changed my mind from following the sample to coming up my own idea: Writing a proxy to simulate HTTP connection through the only gateway of the Nitro Enclave - vsock tunnel.

# How does the demo works

![Using proxies to simulate HTTP connection through vsock tunnel](/assets/images/2602bfe6-cc68-48ca-bfaa-86006967610b.png)

Using proxies to simulate HTTP connection through vsock tunnel

For detail description, you can find in the [description](https://github.com/richardfan1126/nitro-enclave-python-demo/blob/master/README.md){:target="_blank"} inside the code repository. What I want to share in this post are some interesting things I found when I build this demo project.

## 1. Picking the right Docker image

For Python app development, using [Python base image](https://hub.docker.com/_/python){:target="_blank"} would be an obvious step. But for some reason, the python image is not running properly in the Nitro Enclave.

No matter I use the standard image, `-slim` image or `-alpine` image, even my Dockerfile is just running a simple `echo` command, an error `Could not open /env file: No such file or directory` will come up.

I finally used [amazonlinux](https://hub.docker.com/_/amazonlinux){:target="_blank"} base image and install the packages required during the build. Though I still don’t know the reason behind, it just worked fine.

If you also encounter some weird problem, try using other base images. What works in EC2 instance may not work in the Enclave.

## 2. Making HTTP connection

Most of the HTTP proxies use `127.0.0.1` to link up different applications in the same machine. I did the same thing while implementing the HTTP-to-vsock proxy.

However, I don’t know if this is part of the hardening process on Nitro Enclave. If you run `ifconfig` there is no network interface shown, that means you cannot do any IP connection at all (even to localhost).

Luckily, when I run `ifconfig -a` I found that the local loopback `lo` is still there. It’s just that no IP address is assigned to it.

![](/assets/images/2d9d9239-88fc-4fca-a64a-b8c50dd7cf2c.png)

So I added a command `ifconfig lo 127.0.0.1` into the bootstrap script to assign an IP address to it. After that, we can use `127.0.0.1` to do the HTTP connection between applications.

![](/assets/images/5c94fa4c-9c46-4d4f-becb-c1a331d0e9a9.png)

If your application relies on HTTP connection (e.g. REST API) you may find this method useful as you can write your own proxy to forward traffic out via the vsock channel.

# What’s next — Attestation

## What is attestation

One of the great features of AWS Nitro Enclaves is attestation. Besides data isolation, we may also want identity isolation.

Because the Nitro Enclave doesn’t have network access to the outside world, everything will go through the parent instance. There should be a way for service providers (e.g. AWS KMS) to identify whether an API call is originated from the parent instance or the enclave.

Attestation is the way we used to achieve this. We can use NitroSecureModule (NSM) to get a signed Attestation Document and use it to prove that the request is originated from the enclave. There is also a challenge mechanism to avoid outsiders from replicating the requests.

## What is the challenge I am facing now

However, the documents provided by AWS is still difficult for me, I may need more time to understand and hopefully implement a Python attestation process.

1. [https://github.com/aws/aws-nitro-enclaves-sdk-c/blob/main/docs/kmstool.md](https://github.com/aws/aws-nitro-enclaves-sdk-c/blob/main/docs/kmstool.md){:target="_blank"}

1. [https://github.com/aws/aws-nitro-enclaves-nsm-api/blob/main/docs/attestation_process.md](https://github.com/aws/aws-nitro-enclaves-nsm-api/blob/main/docs/attestation_process.md){:target="_blank"}
