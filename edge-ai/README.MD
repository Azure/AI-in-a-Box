# EdgeAI in-a-box
![Banner](../media/images/banner-edgeai-in-a-box.png)



## Why Edge AI?
Edge AI excels in diverse applications like image classification, object detection, body, face, and gesture analysis, as well as image manipulation. Moreover, in this swiftly evolving Generative AI (Gen AI) landscape, the move from cloud-based Gen AI to Edge Gen AI is becoming more prominent. This shift is not just desirable but increasingly necessary, propelled by demands for privacy, security, hyper-personalization, accuracy, cost-effectiveness, energy efficiency, and more. While the commercialization of today's cloud-based Gen AI is in full swing, there are efforts underway to optimize the models built for power-guzzling GPU server farms to run on power-sipping edge devices with efficient mobile GPUs, Neural and Tensor processors (NPU and TPU).

With this in mind, we aim to simplify the process of: creating a model, packaging it, and deploying it to the edge. The series kicks off by establishing the baseline of creating and deploying a model with Azure ML and IoT Edge. We'll then explore more specific scenarios, such as deploying a model with AKS and AKS Edge, and dive into creating a model with ONNX Runtime to highlight its advantages�allowing training in a preferred environment and deployment anywhere, be it on the cloud or edge. Similar attention will be given to OpenVIno. Our ultimate goal is to provide a clear understanding of various options and scenarios, guiding you into the realm of Edge Gen AI and facilitating a seamless transition.

## Why does AI-in-a-Box have an Edge AI Section?
### Because we want to show you the secrets of crafting and deploying your own model anywhere; We want to help you take your AI game to the next level!

AI-in-a-Box encompasses four vital domains within Azure AI/ML:

1.	**Azure ML:** This involves exploring the Azure ML Workspace and leveraging its capabilities to operationalize the creation of AI models.
2.	**Azure AI Services Integration:** This domain focuses on the seamless integration and utilization of prebuilt models through APIs on the Azure AI Services front.
3.	**GenAI Exploration & Acceleration:** This area delves into the realm of Generative AI (GenAI) and the effective utilization of Large Language Models (LLMs).
4.	**Edge AI:** Within this domain we address the creation of crucial Azure Resources for Edge AI scenarios, delve into model development, packaging and deployment. The central focus is on orchestrating the synergy between Azure Resources and positioning AI models as close to the edge as possible.

**Edge AI** is pivotal in extending AI and ML capabilities directly to edge devices, emphasizing the significance of running AI models on these devices and highlighting the essential interplay between various services in Azure. In summary, Edge AI enhances operational efficiency by bringing AI capabilities closer to the data source.

The provided series introduce a comprehensive and simple flow that streamlines the understanding and deployment of deep learning models on Edge devices or Edge-compatible Docker containers and working our way towards AKS and the Heavy Edge. These accelerators will help you pave the way for seamless integration into real-world applications.

We will start the series with:

![Banner](../media/images/edgeai-tree-options.png)

1. [AML Edge](./aml-edge-in-a-box/) - Creating a model in Azure ML, leveraging AutoML, packaging it correctly and deploying with IoT Edge to an Edge Device.
2. [Custom Vision Edge](./customvision-edge-in-a-box/) - Creating a model with Azure's [Custom Vision](https://learn.microsoft.com/en-us/azure/ai-services/custom-vision-service/overview) and deploying with IoT Edge and running that AI model in a docker container.

We will then expand the series to include the following:

3. [AI Vision Edge]() - Creating a model with [Azure AI Vision](https://learn.microsoft.com/en-us/azure/ai-services/computer-vision/overview) and the new Image Analysis 4.0 system, which is based on the Florence Foundational Model, which now supports custom models with few-shot learning capabilities.

Finally, we are actively advancing this series to showcase the creation and deployment of models within  AKS/[AKS Edge](https://learn.microsoft.com/en-us/azure/aks/hybrid/aks-edge-overview) and [Azure IoT Operations](https://learn.microsoft.com/en-us/azure/iot-operations/get-started/overview-iot-operations) scenarios.

4. [AKS Edge AI]() - Creating a model and deploying that model in AKS, AKS Edge and [Azure IoT Operations](https://learn.microsoft.com/en-us/azure/iot-operations/get-started/overview-iot-operations) scenarios

Furthermore, we have plans to enrich the series by providing knowledge and essential building blocks to help you navigate GenAI scenarios at the Edge—such as practical insights into managing intent at the edge.

5. [GenAI Edge]() - Working with GenAI at the edge scenarios

Stay tuned for more exciting accelerators in the pipeline, as there's much more to come!

## Quick Note: Model customization in Azure Custom Vision and/or Azure AI Services

You can train a custom model using either the [Custom Vision](https://learn.microsoft.com/en-us/azure/ai-services/custom-vision-service/overview) service or the Image Analysis 4.0 service (within [Azure AI Services](https://learn.microsoft.com/en-us/azure/ai-services/computer-vision/overview)) with model customization. The [following table](https://learn.microsoft.com/en-us/azure/ai-services/computer-vision/concept-model-customization) compares the two services.

|Areas|Custom Vision service|Image Analysis 4.0 service|
|---|---|---|
|Tasks | Image classification<br>Object detection | Image classification <br> Object detection|
|Base model | CNN |	Transformer model |
|Labeling |	[CustomVision.ai](https://www.customvision.ai/) | [AML Studio](https://ml.azure.com/) |
|Web Portal | [CustomVision.ai](https://www.customvision.ai/) | [Vision Studio](http://aka.ms/VisionStudio) |
|Libraries | REST, SDK | REST, Python Sample |
|Minimum training data needed |	15 images per category |2-5 images per category |
|Training data storage | Uploaded to service | Customer’s blob storage account |
|Model hosting | Cloud and **Edge**	| Cloud hosting only,<br>***Edge container hosting to come***


## Additional Resources

### Check out our <img src="../media//images/mindmap.png" alt="ml edge mindmap" width="30" style="padding-left: 10px;padding-right: 10px; f"  /> [ML/AI Edge MindMap](https://aka.ms/mledge-mm)

