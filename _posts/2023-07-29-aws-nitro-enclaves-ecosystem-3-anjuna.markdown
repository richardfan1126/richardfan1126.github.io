---
layout: post
title:  "AWS Nitro Enclaves Ecosystem (3) - Anjuna"
date:   "2023-07-29"
author: Richard Fan
toc:    true
tags:   nitro-enclaves
---

## Background   
After my last [post on Evervault](/2023/02/09/aws-nitro-enclave-ecosystem-2-evervault.html){:target="_blank"} was published, I didn't have time to try out other AWS Nitro Enclaves service providers. But luckily, Anjuna, which is also on my list to review, reached out to me and offered a free trial for me to review its Nitro enclaves offering.  
So in this blog post, I will talk about my takes.  
_If you are unfamiliar with AWS Nitro Enclaves, please read these AWS documents first. Otherwise, you may find it challenging to understand the rest of this post: [What is AWS Nitro Enclaves?](https://docs.aws.amazon.com/enclaves/latest/user/nitro-enclave.html){:target="_blank"} / [Nitro Enclaves concepts]( https://docs.aws.amazon.com/enclaves/latest/user/nitro-enclave-concepts.html){:target="_blank"}_  

---  

## What is Anjuna   

[Anjuna Security](https://www.anjuna.io/){:target="_blank"} is a company offering a software platform that automates the creation of confidential computing environments in the public cloud. Besides AWS Nitro Enclaves, they also support other cloud platforms (e.g., Azure, GCP) based on various hardware chipsets (e.g., Intel SGX, AMD SEV).  

### Tools as a Service   

My initial expectation of Anjuna was that it would be a cloud service integrated with my AWS account through permission grants, a common approach of cloud service providers.  

However, Anjuna doesn't go on this path. Instead, they provide a complete software platform to customers, helping them build and run their applications on AWS Nitro Enclaves.  

During the process, no communication is needed between the workloads and Anjuna. With the tools downloaded upfront, customers can even build and deploy the application in a private VPC without Internet access.  

---  

## Features   

The Anjuna Nitro Enclaves toolset consists of several useful tools to help developers build enclave applications.  

Most of the tools act as the replacement for commonly used tools like docker, nitro-cli. The magic behind it is that when you run the command, the tools will embed some Anjuna-built runtime or services alongside your app and help achieve some tasks.  

_Diagram from Anjuna_  

![Diagram from Anjuna](/assets/images/fb6a885f-2ad3-412c-9f01-4e27f450071a.png)

### Network Proxy   

Without Anjuna, we need to create proxies in both the parent EC2 instance and the enclave runtime to forward traffic between them (See my [example](https://dev.to/aws-builders/running-python-app-on-aws-nitro-enclaves-3lhp){:target="_blank"} in another post)  

Instead of using AWS-provided `nitro-cli`, we can use `anjuna-nitro-cli build-enclave` to build the enclave image. The tool embeds the Anjuna Nitro Runtime into the image. This customized runtime provides more than just a network proxy on the enclave side. It also provides the proxy service for other functions I’ll discuss later.  

Before running the enclave app, we need to run the command `anjuna-nitro-netd-parent --enclave-name <enclave_name> --daemonize` to start the network proxy on the parent instance side.   

By running two commands, we are ready to run an enclave app with network connections, a convenient experience for software developers.  

### More handy tools - Secret Storing, Persistent Storage   

AWS KMS is one of the only 2 AWS services with native support on AWS Nitro Enclaves. When it comes to storage, developers need to be creative with their solutions.  

Anjuna provides two solutions to it. The 1st one is secret storing, which utilizes S3 as storage and KMS as an encryption service.  

The tool `anjuna-nitro-encrypt` uses your AWS KMS key to encrypt the secret and upload it to an S3 bucket you specified.  

When running the enclave app, we can specify the location of the encrypted file in the enclave config file. The Anjuna runtime in the enclave will help download, decrypt it with AWS KMS, and provide the secret to the app runtime.  

Anjuna also provides seamless persistent block storage on AWS Nitro Enclaves. With a daemon running on the parent instance and the mount point configured in the enclave config file, the Anjuna Nitro tool can mount a block storage from the enclave runtime to a file on the parent instance.  

---  

## Most Powerful Feature - Kubernetes plugin   

After discussing some handy tools, I need to spare another section on one of the most powerful tools, the Kubernetes plugin.  

All the tools I have mentioned make deploying enclave applications easy, but just for one instance. When it comes to large-scale application deployment, Kubernetes is the most popular way to go, and Anjuna takes AWS Nitro Enclaves into this area.  

Like previously mentioned tools, the Anjuna Nitro Kubernetes toolset embeds proxy into your workloads. But in this case, besides the Anjuna runtime (they call it **Anjuna Nitro Launcher**), there are two additional Kubernetes resources – [MutatingWebhookConfiguration](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#mutatingadmissionwebhook){:target="_blank"}, [DevicePlugin](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/device-plugins/){:target="_blank"}  

![Anjuna Nitro Kubernetes toolset](/assets/images/0293617f-6a2a-4ccc-a301-510a21c577c6.png)

We only need to add an annotation to the pod definition to deploy an application into the enclave. But under the hood, there are a series of events happening.  

First, the Anjuna Nitro Webhook intercepts the request and modifies it. The two main changes are to embed the app image into the Anjuna Nitro Launcher runtime, which will provide services to the enclave app. Another main change is to specify the enclave requirement of the pod inside the `resources` section.  

Anjuna Device Manager is registered as a [device plugin](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/device-plugins/){:target="_blank"} of the Kubernetes cluster, so when a pod has an enclave requirement, it can assign it to the Nitro enclave through interaction with the Nitro Enclaves kernel API (i.e. `/dev/nitro_enclaves`)  

![Anjuna Nitro Webhook modify pod definition](/assets/images/d5663712-eeb3-4b80-a383-a37edc66e88b.jpeg)

![Anjuna Device Manager](/assets/images/071d0c0d-5407-481b-a1b0-bc91b4a05093.jpeg)

This is a standard approach to customizing Kubernetes clusters. But with all these tweaks, the Anjuna Nitro Kubernetes toolset helps us deploy enclave applications in a scalable way.  

---  

## Data Privacy  

Enclave applications usually process sensitive data, so privacy is the most critical concern.  

With the Anjuna tool binary running inside the same enclave as the application, we have little to do to prevent it from accessing the data. But unlike other cloud services, Anjuna Nitro tools don’t require any communication between customers’ workloads and Anjuna’s servers. This opens up an option for customers to use Anjuna services without the risk of data exposure.   

### Operate in Private Network   

Although the official documentation doesn’t emphasize, we can actually use Anjuna tools in a private network.  

During my review, I tried to build a private VPC and run Anjuna inside, so here’s the result.  

Firstly, I downloaded the Anjuna tools and the necessary container images into my EC2 instance.  

Then, I created the VPC endpoints necessary for me to access the instance via AWS SSM.  

_Create VPC endpoints for SSM access_  

![Create VPC endpoints for SSM access](/assets/images/655604bb-16d2-49c8-9f28-d04f97e376b8.png)

And then, I restricted the instance security group outbound traffic to the VPC endpoints only.  

_Restrict instance access to the Internet_  

![Restrict instance access to the Internet](/assets/images/078328bf-55a5-47b1-be63-5e2fea01e637.png)

Since then, my EC2 instance has no access to the Internet. But under this environment, I can still use Anjuna tools to run the enclave application.  

_Anjuna tools can run without Internet_  

![Anjuna tools can run without Internet](/assets/images/4a9f6154-a222-4bde-9019-f978138186da.jpeg)

Another fun fact is that I tried building a self-managed Kubernetes cluster without using EKS and put it in a private subnet without internet access. The Anjuna Nitro Kubernetes toolset can still run correctly.  

### Licensing Model   

With Anjuna software running entirely offline, the license to customers is only checked locally. I think this is a carefully considered decision by Anjuna.   

Given the focus on privacy by Anjuna's customers, it would have been challenging to accept tools running inside a sensitive workload sending data out, unless Anjuna could have proven they had no access to customers' data. But this would have required Anjuna to open source their tools, which doesn’t seem to fit their business model.   

This license model works for Anjuna’s customers, as they provide not just the tools but also customer support.   

They are also planning on transparent metric collection from customers' workloads, so Anjuna can better understand customers' usage, and the customers can also see what data is sent to Anjuna.   

---  

## Final Thought  

### Trust Model  

Enclave applications usually have access to sensitive data, so the users always pay attention to who has potential access to the data.  

Most of the Nitro Enclaves use cases fall into 3 categories:  
1. Building their own enclave applications (e.g., Dashlane)  
1. Completely open-source (e.g., EdgeBit Enclaver)  
1. Providing managed service to customers (e.g., Evervault, Oblivious AI)  

In the first 2 cases, we don’t trust anyone and need complete control or visibility of the application source code. The last case is where we trust the vendors and use their service to minimize data exposure.  

Anjuna is sitting in between them, which we trust Anjuna that we are installing their tools into the enclave without reviewing the source code. But we do not entirely trust it, so we may want to ensure no data is sent to them from our workloads.  

This makes me think that as a Security Engineer, I always face the question between build and buy. Sometimes, I need to ask myself: Is this SOC2 or ISO 27001 certificate trustworthy? Can I trust the vendors that they can safeguard our data? Especially when I see many remarks and accepted risks in the audit reports.  

But even with these doubts, we still need to choose the vendor because building our own solution is simply too expensive.  

Having a choice to host the application completely in our environment is definitely a plus in these trade-offs. And I think Anjuna is smartly positioning its services here: Not disclosing the tool logic, but you are free to decide where to deploy.  

### Target Audience  

The current licensing model of Anjuna and the technical skills required to use the tools (Especially the knowledge of deploying resources on AWS) are suitable for enterprises whose primary focus is not developing software.  

On the one hand, those companies have enough technical personnel to deploy the applications. On the other hand, they don’t have enough resources or incentives to hire and train engineers specifically on enclave technology.  

For Anjuna itself, managing those customers is also easier because they can build close relationships with a small number of big companies. Anjuna can even provide special arrangements for their most important customers to audit the tools source code.  

I am interested in what direction Anjuna will go in the future. Will they explore other business models to expand the customer base? How will they make their tools much more accessible to customers with fewer technical skills without compromising the risk of customers’ data?  

With more types of service offerings, more public awareness of enclave technology, and the pros and cons of different options, I believe there will be more adoption in the future. 
