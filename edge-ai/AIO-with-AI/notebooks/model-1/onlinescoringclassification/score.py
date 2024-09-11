import os
import json
import numpy as np
import pickle
import joblib

def init():
    """
    This function is called when the container is initialized/started, typically after create/update of the deployment.
    You can write the logic here to perform init operations like caching the model in memory
    """
    global model
    # AZUREML_MODEL_DIR is an environment variable created during deployment.
    # It is the path to the model folder (./azureml-models/$MODEL_NAME/$VERSION)
    # For multiple models, it points to the folder containing all deployed models (./azureml-models)
    model_path = os.path.join(os.getenv("AZUREML_MODEL_DIR"), "sklearn_mnist_model.pkl")
    # deserialize the model file back into a sklearn model
    model = joblib.load(model_path)

def run(raw_data):
    """
    This function is called for every invocation of the endpoint to perform the actual scoring/prediction.
    In the example we extract the data from the json input and call the scikit-learn model's predict()
    method and return the result back
    """
    data = np.array(json.loads(raw_data)['data'])
	# make prediction
    y_hat = model.predict(data)
	# you can return any data type as long as it is JSON-serializable
    return y_hat.tolist()