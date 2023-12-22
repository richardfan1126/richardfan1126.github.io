---
layout: post
title:  "AWS Nitro Enclaves Ecosystem (2) - Evervault"
date:   "2023-02-09"
author: Richard Fan
toc:    true
---

## Background

If you haven't read my previous post, please read [AWS Nitro Enclaves Ecosystem (1) - Chain of trust](/2022/12/22/aws-nitro-enclaves-ecosystem-1-chain-of-trust.html){:target="_blank"} on how I see services built on top of AWS Nitro Enclaves and the importance of Attestation Document.

This time, I'm going to talk about my thought on Evervault.

## What is Evervault

[Evervault](https://evervault.com/){:target="_blank"} provides transparent encryption using relay webhooks.

### Encryption service

The idea is that before sensitive data goes into the system, you can route the traffic through Evervault [Inbound Relay](https://docs.evervault.com/products/inbound-relay){:target="_blank"} to encrypt it so that the system can only get the encrypted data.

To use the encrypted data, Evervault provides [Outbound Relay](https://docs.evervault.com/products/outbound-relay){:target="_blank"} to decrypt the data before sending it to the external components.

Using it, developers can build applications that handle sensitive data without worrying about encryption or changing the code to protect it.

Evervault states that the encryption is performed by [Evervault Encryption Engine (E3)](https://docs.evervault.com/security/evervault-encryption){:target="_blank"}, which is running on Nitro Enclaves. However, there is no way for us to tell whether it's true. There is no independent audit available as well.

### Runtime provisioning

#### Evervault Functions

Besides simply encrypting data, Evervault also provides the environment for developers to run simple functions on sensitive data.

The current offering is [Evervault Functions](https://docs.evervault.com/products/functions){:target="_blank"}, in which you can invoke your custom Python or Node.js application with the encrypted data. Your application will be given decrypted data as parameters so you can perform your business logic on it.

The example Evervault provides is to [validate encrypted phone number](https://docs.evervault.com/guides/validate-phone-numbers){:target="_blank"}

#### Evervault Cages

Evervault Functions is not running on Nitro Enclaves, so I will not discuss it in this blog post. But Evervault has a beta offering called [Evervault Cages](https://docs.evervault.com/products/cages){:target="_blank"} which provides a similar feature on Nitro Enclaves. In this blog post, I will focus on it.

## Deep dive

I tried Evervault Cages by following their [documentation](https://docs.evervault.com/products/cages#getting-started){:target="_blank"}, as well as the help from the Evervault team to understand how it works.

This session is about the key points which are worth considering.

### Less infrastructure overhead

Using Cages CLI, you can quickly build your docker application and deploy it into Nitro Enclave. You don't need to provision EC2 instances or configure Nitro Enclaves. Evervault provides the infrastructure in their AWS account for you during deployment.

You also don't need to handle external traffic, as Evervault will handle it for you. The Cage application endpoint will be forwarded to the exposed port of your enclave application. Evervault can also forward egress traffic from the enclave to the Internet.

### TLS Attestation

Another feature Evervault Cages provides is [TLS Attestation](https://docs.evervault.com/products/cages#tls-attestation){:target="_blank"}.

When TLS termination is enabled in your Cage application, the attestation document of the Nitro Enclave will be embedded inside the Cage endpoint TLS certificate.

According to the documentation, you can only use Evervault SDK or CLI to validate the embedded Attestation document. The tools use an undocumented API to retrieve the attestation. We can use the same API to validate the attestation document ourselves.

![Connect to the Cage endpoint with a nonce](/assets/images/649e0424-6663-4e3c-86de-055c78da821c.png)

![Attestation document is embedded in the TLS certificate](/assets/images/7db30655-bbe6-48a9-91a2-83e440adffe4.png)

When connecting to the Cage application endpoint `<cage_name>.<cage_id>.cages.evervault.com` (or `<nonce>.attest.<cage_name>.<cage_id>.cages.evervault.com` if you want to use nonce on the attestation), the Evervault-signed TLS cert will contain a Nitro Enclave attestation document in the **Subject Alternative Name (SAN)** section, in hex code format.

Besides using TLS Attestation, Cage environment also provides an [internal API](https://docs.evervault.com/products/cages#attestation-document){:target="_blank"} `http://127.0.0.1:9999/attestation-doc` for developers to retrieve attestation document within the enclave.

These two features help application developers use attestation documents to validate enclave identity without writing their code to retrieve attestation documents.

### Unknown sidecar

To achieve features like egress proxy, TLS Attestation, etc. Evervault Cages installs a proxy sidecar, which they call it **Data Plane**.

![Comparison between original Dockerfile and the version ev-cage has modified](/assets/images/ae99290c-f4c1-4fba-8aec-5a3a166372d0.png)

When we run the following command 

```bash
ev-cage build --write --output .
```

`ev-cage` will modify our original `Dockerfile`, adding two files (One is the runtime dependency, the other one is the sidecar) into it.

As of the time of writing, there is still no source code of the **Data Plane** sidecar publicly available. So when using Evervault Cages, we need to keep in mind that an unknown binary is running along with your application in the enclave.

There is a risk of Evervault doing bad things on the sidecar, or there are vulnerabilities on it.

### Insufficient access control

**API key** is the only [authentication](https://docs.evervault.com/sdks/cli#authentication){:target="_blank"} method Evervault provides for programmatic access.

In a simple platform, this is not an issue. But if I use Nitro Enclaves (or Evervault Cages in this case), I would expect additional data protection.

The issues I can see are:

1. **Lack of permission separation**

    Each Evervault app only has one API key, which can be used across different services (i.e. Relay, Functions, Cages).

    An API key used by Cages can also be used by Functions, so we cannot guarantee an encrypted data can only be decrypted by Cage.

1. **Lack of attestation document support**

    The [decryption API](https://docs.evervault.com/products/cages#decrypt){:target="_blank"} only takes the API key as the sole authentication method. There is no control similar to AWS KMS [key policy](https://docs.aws.amazon.com/kms/latest/developerguide/conditions-nitro-enclaves.html){:target="_blank"}, where we can specify *"only this enclave image can decrypt my secret"*

Image if I have a system which handles both phone no. and credit card no. I want to validate phone no. on Evervault Functions because it's not very sensitive.

But I want to validate the credit card no. on Cages because it's more sensitive than phone no.

In this case, I have no way to protect credit card no. because the _phone no. validation developers_ can decrypt the credit card no. using their API key (because they are the same).

Even though API keys are separated, the _credit card no. validation developers_ can also decrypt the credit card no. because they can write a rogue app (e.g. reverse shell) and deploy it to Cages, then use the decrypt API. Since there is no attestation authentication on the API, we cannot specify which enclave image can decrypt the secret.

## My thought

The idea of Evervault is good, making data protection as easy as possible. Abstracting protecting data-in-use away from developers using Functions and Cages is a boost on adoption.

However, the current state of Evervault Cages is still a long way to go. I would say Cages is as good as the current Functions offering in terms of security and privacy, but there is no significant extra benefit on top of it.

I would suggest the following if Evervault is targeting first-time users who are not familiar with confidential computing and want a quick start:

1. Provides permission control for the API key so users can have more control of data on different privacy levels.

    _Evervault response: Evervault is now working on refining the scopes for API Keys, specifically for decoupling Cages from the surrounding products_

If Evervault is to target more advanced users who treat sensitive data seriously, they can:

1. Open source the **Data Plane** sidecar so users can review its security.

    Alternatively, if Evervault wants to avoid publishing the source code, they can find a reputable 3rd-party audit. Or open source a lightweight version of the sidecar with fewer functions, so users can choose to minimise their risk by using it.

    _Evervault response: Evervault is now undergoing a 3rd Party audit for Cages. Open sourcing is also in their roadmap._

1. Provides attestation document authentication so users can specify which enclave image can decrypt specific data.

    _Evervault response: Evervault is now working on the Cages auth for encryption/decryption to include an attestation step_

## Final thought

To be fair, Evervault Cages is a new release, and it's not expected to be perfect now. Evervault team has done a great job of democratising Nitro Enclaves’ use. They are open to feedback as well.

I suggest you try it out and have a taste of how confidential computing works.
