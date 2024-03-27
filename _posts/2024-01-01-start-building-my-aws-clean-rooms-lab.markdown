---
layout: post
title:  "Start building my AWS Clean Rooms lab"
date:   "2024-01-01"
author: Richard Fan
toc:    true
tags:   pet differential-privacy aws-clean-rooms
---

![Cover image](/assets/images/90acd2d7-dda6-4af5-8da1-7efe67122714.png){:style="display:block; margin-left:auto; margin-right:auto"}

Last month, I had a [post on Linkedin](https://www.linkedin.com/posts/richardfan1126_from-privacy-to-partnership-the-royal-society-activity-7142354202655084544-ikbi){:target="_blank"} about AWS Clean Rooms Differential Privacy. But I was not comfortable sharing something that I've never used. So I spent some time to try it, but then hit the wall so hard.

## Why is it so challenging to try a clean room service?

First of all, the name **Clean Room** is not coined by AWS. **Data clean room** is a concept of analyzing data in an isolated environment so multiple parties can bring their data together to produce insight without compromising data privacy.

The difficulties of getting started are not specific to AWS Clean Rooms. It's more about the nature of a data clean room:

### Multi-party collaboration

Data clean room is about collaboration between different parties. To simulate this environment, we must utilize multiple AWS accounts to get a sense of the service.

### Reliance on good data

We can't feed random data into a data clean room to get some meaningful output. First, we must have 2 different datasets because we are simulating a multi-party collaboration. Second, these 2 data must have some relationship.

Apparently, we can't bring a list of Netflix movies and a bus route table together and hope to get some meaningful insight from them.

### Lack of online resources

This is probably the major reason.

I tried to search on [AWS official website](https://aws.amazon.com/clean-rooms/){:target="_blank"} to find resources. What I got is a lovely architecture diagram and a [pre-recorded demo](https://aws.amazon.com/clean-rooms/resources/#Demo){:target="_blank"}.

I tried to search on [AWS workshop website](https://workshops.aws/){:target="_blank"} using the keyword **Clean**. The only thing that popped up is **Service Cloud Voice Series: Cleaning up your environment**.

I can try *ClickOps* on the console without a tutorial and figure it out myself. But I still need some good data to play with.

I tried searching on [Kaggle](https://www.kaggle.com/){:target="_blank"}, and also on Google using keywords like *"data clean room lab csv"*, *"data clean room sample data"*.

But the data I got are either not clean enough or have only 1 table, which I can't simulate a data collaboration.

## That's why I'm creating my own lab

I was frustrated, but I don't want other people like me to be frustrated too. So, I decided to build an easy-to-follow lab on AWS Clean Rooms.

### Finding a suitable dataset

After trying harder and harder *(I learned this during my OSCP course)*, I finally found some useful sample data from [Maven Analytics](https://mavenanalytics.io/data-playground). And more importantly, their data is in the public domain, meaning I can freely use it in my lab. I picked the **Airline Loyalty Program** data in my lab.

### IaC everything

Another intimidating thing about AWS Clean Rooms is that we must jump between AWS accounts to finish the setup. It doesn't just make *ClickOps* complicated, but also IaC.

I usually use CloudFormation when working on public AWS projects because it's native to AWS. But this time, I'm mixing CloudFormation with Terraform because of its easy-to-setup multi-account deployment. I hope AWS can learn from Hashicorp in this aspect and make it easier to deploy stuff remotely.

## Here's the link

After talking so much, here's the link to my still-in-progress AWS Clean Rooms Lab: [https://github.com/richardfan1126/aws-clean-rooms-lab](https://github.com/richardfan1126/aws-clean-rooms-lab){:target="_blank"}

This lab is not completed yet. But it has 2 sessions already, which you can go through, start playing, and get meaningful results.

What's more exciting is that if you just want to play with the analysis rules and queries and don't want to deal with all the infrastructure hustle, you can simply run a few commands, and everything will be set for you.

I will continue creating more sessions on more complex analysis rules. And more interestingly, the differential privacy part.
