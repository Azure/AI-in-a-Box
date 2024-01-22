---
challenge:
    module: Use an Azure Machine Learning job for automation
    challenge: '1: Create an Azure Machine Learning job'
---

# Challenge: Create an Azure Machine Learning job

## Challenge scenario

The first step to automate machine learning workflows is to create a workflow of the machine learning workloads. To execute any workflow consisting of Python scripts, use Azure Machine Learning jobs.

## Prerequisites

If you haven't, complete the [set-up](00-set-up.md) before you continue.

## Objectives

By completing this challenge, you'll learn how to:

- Convert a notebook into scripts.
- Define an Azure Machine Learning job in YAML.
- Run an Azure Machine Learning job with the CLI v2.

## Challenge Duration

- **Estimated Time**: 30 minutes

## Instructions

In the **src/model** folder, you'll find a Python script which reads CSV files from a datastore and uses the data to train a classification model. In the **src** folder, you'll find a YAML file to define a job. There are values missing in the YAML file. It's up to you to complete it. 

- Run the script as a **job** in Azure Machine Learning. Complete the YAML file to define the job.
- Trigger the job using the CLI v2 using the Cloud Shell or a local terminal.
- Use the registered **data** asset in the Azure Machine Learning workspace as input to the job.
- Run the job using an Azure Machine Learning **compute instance** (don't forget to stop it when done, there's a workflow to help you).

> **Tip:**
> Whether you're working from the Cloud Shell or a local terminal, make sure to update the Azure Machine Learning extension for the CLI to the latest version.

## Success criteria

To complete this challenge successfully, you should be able to show:

- A successfully completed job in the Azure Machine Learning workspace.

> **Note:**
> If you've used a compute instance for experimentation, remember to stop the compute instance when you're done. You can use the **Stop compute instance** workflow to stop the compute instance in your Azure Machine Learning workspace with GitHub Actions.

## Useful resources

- [Learning path on how to use the CLI v2 with Azure Machine Learning.](https://docs.microsoft.com/learn/paths/train-models-azure-machine-learning-cli-v2/)
- [Example jobs.](https://github.com/Azure/azureml-examples/tree/main/cli/jobs/basics) 
- [YAML reference for command jobs.](https://docs.microsoft.com/azure/machine-learning/reference-yaml-job-command) 
- [CLI reference for jobs.](https://docs.microsoft.com/cli/azure/ml/job?view=azure-cli-latest)
