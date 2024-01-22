---
challenge:
    module: 'Work with linting and unit testing in GitHub Actions'
    challenge: '4: Work with linting and unit testing'
---

# Challenge: Work with linting and unit testing

## Challenge scenario

Code quality can be assessed in two ways: linting and unit testing. Use linting to check for any stylistic errors and unit testing to verify your functions.

## Prerequisites

If you haven't, complete the [set-up](00-set-up.md) before you continue.

You'll also need the GitHub Action that triggers the Azure Machine Learning pipeline created in Challenge 3. 

## Objectives

By completing this challenge, you'll learn how to:

- Run linters and unit tests with GitHub Actions.
- Troubleshoot errors to improve your code.

## Challenge Duration

- **Estimated Time**: 45 minutes

## Instructions

In the **tests** folder, you'll find files that will perform linting and unit testing on your code. The `flake8` lints your code to check for stylistic errors. The `test_train.py` performs unit tests on your code to check whether the functions work.

- Go to the **Actions** tab in your GitHub repo and trigger the **Linting** workflow manually. Inspect the output and fix your code where necessary.

> You'll get an F841 warning describing that the variable model is never used. You can ignore this warning as MLflow logs the model, which is later necessary for model deployment.

- Go to the **Actions** tab in your GitHub repo and trigger the **Unit testing** workflow manually. Inspect the output and fix your code where necessary.

- Create a GitHub Actions workflow that runs linting and unit testing, triggered by a pull request.
- Create a **branch protection rule** to require code checks to be successful before mering a pull request to the **main** branch.
- Make a change and push it. For example, change the hyperparameter value. 
- Create a pull request, showing the integrated code checks.

## Success criteria

To complete this challenge successfully, you should be able to show:

- Both the **Linting** and **Unit testing** checks are completed successfully without any errors. The successful checks should be shown in a newly created pull request.

## Useful resources

- [Learning path covering an introduction of DevOps principles for machine learning.](https://docs.microsoft.com/learn/paths/introduction-machine-learn-operations/)