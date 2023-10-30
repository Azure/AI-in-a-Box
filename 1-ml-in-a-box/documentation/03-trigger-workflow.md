---
challenge:
    module: 'Trigger GitHub Actions with trunk-based development'
    challenge: '3: Trigger GitHub Actions with trunk-based development'
---

# Challenge: Trigger GitHub Actions with trunk-based development

## Challenge scenario

Triggering a workflow by pushing directly to the repo is **not** considered a best practice. Preferably, you'll want to review any changes before you build them with GitHub Actions.

## Prerequisites

If you haven't, complete the [set-up](00-set-up.md) before you continue.

You'll also need the GitHub Action that triggers the Azure Machine Learning job created in Challenge 2. 

## Objectives

By completing this challenge, you'll learn how to:

- Work with trunk-based development.
- Protect the main branch.
- Trigger a GitHub Actions workflow by merging a pull request.

## Challenge Duration

- **Estimated Time**: 45 minutes

## Instructions

Use trunk-based development to better govern changes made to the repo and the triggering of GitHub Actions.

- Create a **branch protection rule** to block any direct pushes to the **main** branch.
- Create a branch in the repo.
- Make a change and push it. For example, change the hyperparameter value. 
- Create a pull request. 
- Trigger a GitHub Actions workflow by creating a pull request.

> **Tip:**
> To trigger the workflow, you have to use an event that pushes changes to the main branch. Don't use the pull request event because then the workflow is triggered by the creation of the pull request, not by the merge.

## Success criteria

To complete this challenge successfully, you should be able to show:

- The branch protection rule for the main branch.
- A successfully completed Action in your GitHub repo. 
- An event in the GitHub Action that ensures the workflow is triggered by a new pull request.

## Useful resources

- [Learning path covering an introduction of DevOps principles for machine learning.](https://docs.microsoft.com/learn/paths/introduction-machine-learn-operations/)
- [GitHub Actions.](https://docs.github.com/actions/guides)
- [Triggering a GitHub Actions workflow.](https://docs.github.com/actions/using-workflows/triggering-a-workflow)
