# AI-in-a-Box Multilingual Agent

<!-- <div style="display: flex;">
  <div style="width: 70%;">
    This solution is part of the the AI-in-a-Box framework developed by the team of Microsoft Customer Engineers and Architects to accelerate the deployment of AI and ML solutions. Our goal is to simplify the adoption of AI technologies by providing ready-to-use accelerators that ensure quality, efficiency, and rapid deployment.
  </div>
  <div style="width: 30%;">
    <img src="./media/ai-in-a-box.png" alt="AI-in-a-box Project Logo: Description" style="width: 10%">
  </div>
</div> -->
|||
|:---| ---:|
|This solution is part of the the AI-in-a-Box framework developed by the team of Microsoft Customer Engineers and Architects to accelerate the deployment of AI and ML solutions. Our goal is to simplify the adoption of AI technologies by providing ready-to-use accelerators that ensure quality, efficiency, and rapid deployment.| <img src="./media/ai-in-a-box.png" alt="AI-in-a-box Logo: Description" style="width: 70%"> |

## User Story
![multilingual-agent](./media/multilingual-agent.jpg)


This is the WHY

Insert a image here that tells an interesting story about the solution being delivered

Describe how this solution can help a user's organization, including  examples on how this solution could help specific industries

Describe what makes this solution and other reasons why someone would want to deploy this. Here's some ideas that you may wish to consider:

- **Speed and Efficiency**: How does this solution accelerate the deployment of AI/ML solutions?
- **Cost-Effectiveness**: In what ways does it help save on development costs?
- **Quality and Reliability**: What measures are in place to ensure the high quality and reliability of your solution?
- **Competitive Edge**: How does it give users a competitive advantage in their domain?

## What's in the Box

- CLI (command line interface) that allows users to talk with the assistant by voice
- Orchestrator that is responsible for
  1. Capture and convert the user's voice to text
  2. Translate the text to the language of the assistant (english)
  3. Send the text to the assistant
  4. Translate the response to the user's language
  5. Convert the text to voice and play it to the user
- Deployment of all azure resources needed:
  - Azure AI Services (we will be using Speech and Language services)
  - Azure OpenAI
- Creation of Open AI Assistant
  - Integrated with File Search tool


This is WHAT they get when they deploy the solution

Describe any helpful technical benefits of this solution (for example, deploys key vault for storing keys securely, UAMI for easy and secure integration)

Describe what Azure Resources are deployed

Include Architecture Diagrams including inputs and outputs

Provide links to any associated blogs about this solution (any FTA blogs you wrote that provide more details)

## Thinking Outside of the Box

This is a WHY and a WHAT

Describe ways users can customize and enahance the solution for use inside their organization

## Deploy the Solution

Provide instructions on how to deploy the solutione:

1. **Prerequisites**: List any requirements for using this solution (e.g., software, accounts).
2. **Installation**: Step-by-step instructions for deploying the solution to Azure.
3. **Post Deployment**: Include any instructions that the user may need to do after the resources have been deployed; for example, upload files to blob storage, create an ML or an AI Services project

## Run the Solution

Include instructions on how they can run and test the solution

## Customize the Solution

Describe different ideas on how to enhance or customize for their use cases

## How to Contribute

This project welcomes contributions and suggestions. Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit <https://cla.opensource.microsoft.com>

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq) or contact <opencode@microsoft.com> with any additional questions or comments.
## Key Contacts & Contributors

Highlight the main contacts for the project and acknowledge contributors. You can adapt the structure from AI-in-a-Box:

| Contact | GitHub ID | Email |
|---------|-----------|-------|
| Your Name | @YourGitHub | your.email@example.com |

## Acknowledgments

If applicable, offer thanks to individuals, organizations, or projects that helped inspire or support your project.

## License

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft trademarks or logos is subject to and must follow [Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general). Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship. Any use of third-party trademarks or logos are subject to those third-party's policies.

---

This project is part of the AI-in-a-Box series, aimed at providing the technical community with tools and accelerators to implement AI/ML solutions efficiently and effectively.