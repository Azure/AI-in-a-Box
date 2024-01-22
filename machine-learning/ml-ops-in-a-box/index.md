---
title: Online Hosted Instructions
permalink: index.html
layout: home
---

# MLOps Challenges

This repository contains hands-on challenges for end-to-end machine learning operations (MLOps) with Azure Machine Learning.

To complete these exercises, you’ll need a Microsoft Azure subscription. If your instructor has not provided you with one, you can sign up for a free trial at [https://azure.microsoft.com](https://azure.microsoft.com/).

## Challenges

{% assign challenge = site.pages | where_exp:"page", "page.url contains '/documentation'" %}
| Module | Challenge |
| --- | --- | 
{% for activity in challenge  %}| {{ activity.challenge.module }} | [{{ activity.challenge.challenge }}{% if activity.challenge.type %} - {{ activity.challenge.type }}{% endif %}]({{ site.github.url }}{{ activity.url }}) |
{% endfor %}