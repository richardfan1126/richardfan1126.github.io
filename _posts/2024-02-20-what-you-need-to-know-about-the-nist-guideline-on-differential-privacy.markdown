---
layout: post
title:  "What You Need to Know About the NIST Guideline on Differential Privacy"
date:   "2024-02-20"
author: Richard Fan
toc:    true
---

In December 2023, NIST published its first public draft of [Guidelines for Evaluating Differential Privacy Guarantees](https://csrc.nist.gov/pubs/sp/800/226/ipd){:target="_blank"}, this is a huge milestone of the digital privacy domain.

In this blog post, I'm going to tell you why and what you need to know from the guideline.

## What is the current state of privacy protection

To understand the importance of **Differential Privacy (DP)**, we first need to understand the current privacy protection approaches and some basic concepts.

### Input Privacy vs Output Privacy

In the past, when people wanted to conduct research on data related to individuals, we used different methods to minimize the exposure of the raw data (e.g., Relying on a trusted 3rd party to curate the data, distributing the data curation process to different parties, etc.) These methods prevent privacy leaks from the raw data **Input**; we call it **Input Privacy**.

But in some cases, we may also want to publish the research results to the broader audience or even the general public. We also need to ensure that an individual's privacy would not be derived from the result data **Output**; this is called the **Output Privacy**.

### Current De-identification method doesn't work

The main problem Differential Privacy wants to address is Output Privacy. It is about preventing individual information from being derived by combining different results and reverse engineering.

The most common method we have been using for decades is **De-identification**. We always talk about **Personal Identifiable Information (PII)**, and try to remove them from raw data before doing data research.

But this method has been frequently proved vulnerable; some prominent examples include [The Re-Identification of Governor William Weld's Medical Information](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=2076397){:target="_blank"} and [De-anonymization attacks on Netflix Prize Dataset](https://arxiv.org/pdf/cs/0610105.pdf){:target="_blank"}

Clearly, with enough auxiliary data, we can re-construct individual information from data that is supposed to be _Anonymized_. From this assumption, **every information of an individual is PII**.

## What is Differential Privacy

People have been trying to define what PII is for decades and failed repeatedly. Clearly, we need a more robust framework for measuring how much privacy we're preserving when performing anonymization.

And Differential Privacy is the framework we need. It is a **Statistical measurement of how much an individual's privacy is lost when exposing the data**.

### Differential Privacy is not an absolute guarantee

The guideline makes it clear at the very beginning that **_Differential privacy does not prevent somebody from making inferences about you._**

The word **Differential** means that the guarantee DP provides is relative to the situation where an individual doesn't participate in the dataset. DP can guarantee one's privacy will not face greater risk by participating in the data, but it **doesn't mean it will have no risk at all**.

We can understand it easily by considering the following example:

_Medical research found that smokers have a higher risk of lung cancer, so their insurance premiums are usually higher than those of other people._

_Let's say a smoker, John, didn't participate in that medical research; the result is probably still the same. So, no matter whether he participates or not, his insurance company can still learn that he has a higher risk of lung cancer and charge him a higher premium._

In this example, although medical research makes the insurance company know that John has higher risk of lung cancer. But we can still say DP guarantees John's privacy in the medical research because it **makes no difference to him whether he participates or not**.

## Differential Privacy Foundations

### Epsilon (ε)

The formal definition of ε is the following formula:

![Definition of Epsilon](/assets/images/3fa3ef79-9c14-4adc-8aa5-fdeba8239f19.png)

It might be too difficult to understand, but it roughly means **The chance where the datasets with and without an individual would produce different results**.

To understand it, we can assume a very small (or even zero) ε; there is little or no difference whether an individual participates in a research. So, there's less chance people can learn if that individual is or isn't in the dataset.

**In theory, smaller ε provide more privacy guarantee but less accuracy**.

### Privacy Unit

Another concept the guideline calls out is the Privacy Unit.

DP describes the difference between results from datasets with or without an individual, but it doesn't define **what is an individual**. It can be an individual transaction, or a person.

Since the common concern of data privacy is always about people. So the guideline suggests we always use **User as the Privacy Unit**.

This means when we apply DP, we should always measure the ε when **ALL records related to one person** are presented or not.

## Differential Privacy in practice
