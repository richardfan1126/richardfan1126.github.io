---
layout: post
title:  "A playground to practice differential privacy - Antigranular"
date:   "2023-12-25"
author: Richard Fan
toc:    true
---

## Background

I knew Jack from [Oblivious](https://www.oblivious.com/){:target="_blank"} (His company was called Oblivious AI then) early this year when I was researching companies that use [AWS Nitro Enclaves](https://aws.amazon.com/ec2/nitro/nitro-enclaves/){:target="_blank"}.

At that time, their tool was just helping users deploy simple applications in the enclaves, and I didn't understand how it was related to data science or even AI.

Last month in AWS re:Invent, I met Jack in person for the first time. After a great chat with him, I finally understood what his company was trying to achieve.

And today's post is to share my first-glance view on the Oblivious platform - Antigranular

## What is Antigranular

Antigranular is a Kaggle-like platform where we can play with various datasets, joining competitions on machine learning and data science using those datasets.

The difference from Kaggle is that Antigranular's dataset is not freely available. Instead, there are restrictions on how users can access their data in order to guarantee data privacy.

There is another [blog post](https://pub.towardsai.net/antigranular-how-to-access-sensitive-datasets-without-looking-at-them-44090cb22d8a){:target="_blank"} by Bex T. talking about what is Antigranular, what technique it is applying, and how to get started. You can read it if you are interested in the details.

## My quick walkthrough - as a non-data engineer

I'm not a data engineer, and I don't even know the difference between `pandas` and `numpy`.

But I still tried to create my Jupyter notebook to play with one sandbox competition on Antigranular.

If you are also not a data engineer and have no idea how DataFrame works, my walkthrough may help you understand Antigranular and differential privacy.

### Create a Jupyter Notebook

To play with the dataset, we first need to create a Jupyter notebook, a powerful and popular tool among data engineers. I created mine on [Google Colab](https://colab.research.google.com/){:target="_blank"}.

![Using Google Colab to create a Jupyter notebook](/assets/images/c45ce549-fdff-4adc-a770-72573805d5cf.png)

Jupyter notebook can run different programming languages. Since Antigranular provides a Python library, I will be using Python.

### Running some basic data engineering tasks

Before playing with the dataset, I need to mention a major difference between Antigranular and other data platforms - The data is not loaded into our Jupyter notebook.

![Data cannot be accessed on local notebook](/assets/images/4e0c878c-e9da-42e1-b031-9cf45cfacb9a.png)

You can see from the screenshot that if I access the data and try to get its metadata, it will raise an error.

Instead, the data is being loaded in a trusted execution environment (TEE) hosted by Antigranular.

To access it, we need to add a magic function `%%ag` into the code block. And the magic of it is that we can only use limited libraries and functions in those code blocks.

For example, `pandas` is a popular Python library data engineers use to play with the data. But inside the TEE, we can only use its variant - `op_pandas`.

![The operation in the TEE is limited](/assets/images/2fe7b0c5-15d6-41ba-b145-de0405231427.png)

Data engineers usually use the `head()` function to preview the data. But with `op_pandas`, this action is blocked.

With these restrictions, the Antigranular platform can assure data providers that the individual privacy inside the dataset will not be exposed.

### Do some machine learning tasks


