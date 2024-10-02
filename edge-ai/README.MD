# EdgeAI in-a-box

![Banner](../media/images/banner-edgeai-in-a-box.png)

## Why Edge AI?

Edge AI excels in diverse applications like image classification, object detection, body, face, and gesture analysis, as well as image manipulation. Moreover, in this swiftly evolving Generative AI (Gen AI) landscape, the move from cloud-based Gen AI to Edge Gen AI is becoming more prominent. This shift is not just desirable but increasingly necessary, propelled by demands for privacy, security, hyper-personalization, accuracy, cost-effectiveness, energy efficiency, and more. While the commercialization of today's cloud-based Gen AI is in full swing, there are efforts underway to optimize models to run on power-sipping edge devices with efficient mobile GPUs, Neural and Tensor processors (NPU and TPU).

With this in mind, we aim to simplify your understanding of creating a model, packaging it, and deploying it to the edge. The series kicks off by establishing the baseline of creating and deploying a model with Azure ML and IoT Edge. We'll then explore more specific scenarios, such as deploying a model with AKS and AKS Edge, dive into creating a model with ONNX Runtime, and finally guide you into the realm of Edge Gen AI. Our ultimate goal is to provide you with a clearer understanding of your options within Azure for Edge AI scenarios.

## Why does AI-in-a-Box have an Edge AI Section?

### Because we want to show you the options of crafting and deploying a model anywhere

**Edge AI** plays a crucial role in expanding AI and ML capabilities by bringing them directly to edge devices. This emphasizes the importance of running AI models on these devices and underscores the essential interplay between various Azure services. This series introduces a progressive flow designed to enhance your comprehension of model creation and deployment on Edge devices or Edge-compatible containers. It guides you through the journey, starting with fundamental concepts, advancing towards AKS deployments, and eventually delving into more advanced GenAI Edge scenarios. These practical examples aim to deepen your understanding of the possibilities within Azure for Edge AI scenarios, providing valuable insights into the diverse applications of this technology.

![Banner](../media/images/edgeai-tree-options.png)

We will start the series with:

1. [AML Edge](https://github.com/Azure-Samples/aml-edge-in-a-box) - Creating a model in Azure ML, leveraging AutoML, packaging it correctly and deploying with IoT Edge to an Edge Device.
2. [Custom Vision Edge](https://github.com/Azure-Samples/customvision-edge-in-a-box) - Creating a model with Azure's [Custom Vision](https://learn.microsoft.com/en-us/azure/ai-services/custom-vision-service/overview) and deploying with IoT Edge and running that AI model in a docker container.

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
|Tasks | Image classification<br />Object detection | Image classification <br /> Object detection |
|Base model | CNN |	Transformer model |
|Labeling |	[CustomVision.ai](https://www.customvision.ai/) | [AML Studio](https://ml.azure.com/) |
|Web Portal | [CustomVision.ai](https://www.customvision.ai/) | [Vision Studio](http://aka.ms/VisionStudio) |
|Libraries | REST, SDK | REST, Python Sample |
|Minimum training data needed |	15 images per category |2-5 images per category |
|Training data storage | Uploaded to service | Customer’s blob storage account |
|Model hosting | Cloud and **Edge** | Cloud hosting only,<br />***Edge container hosting to come*** |

## Additional Resources

### Check out our Mindmap

[![ml edge mindmap](/media/images/mindmap.png) ML/AI Edge MindMap](https://aka.ms/mledge-mm)
