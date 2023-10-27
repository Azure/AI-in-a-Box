---
challenge:
    module: 'Deploy a model with GitHub Actions'
    challenge: '6: Deploy and test the model'
---

# Challenge: Deploy and test the model

## Challenge scenario

To get value from a model, you'll want to deploy it. You can deploy a model to a managed online or batch endpoint.

## Prerequisites

If you haven't, complete the [set-up](00-set-up.md) before you continue.

You'll also need the GitHub Action that triggers the Azure Machine Learning pipeline created in Challenge 3. 

## Objectives

By completing this challenge, you'll learn how to:

- Register the model with GitHub Actions.
- Deploy the model to an online endpoint with GitHub Actions.
- Test the deployed model.

## Challenge Duration

- **Estimated Time**: 60 minutes

## Instructions

When a model is trained and logged by using MLflow, you can easily deploy the model with Azure Machine Learning. You

- Register the model, create an endpoint and deploy your model to the endpoint using the CLI (v2) in a GitHub Actions workflow.
- Test whether the deployed model returns predictions as expected.

## Success criteria

To complete this challenge successfully, you should be able to show:

- A model registered in the Azure Machine Learning workspace.
- A successfully completed Action in your GitHub repo that deploys the model to an online endpoint.

## Useful resources

- [Learning path covering an introduction of DevOps principles for machine learning.](https://docs.microsoft.com/learn/paths/introduction-machine-learn-operations/)
- [GitHub Actions.](https://docs.github.com/actions/guides)

