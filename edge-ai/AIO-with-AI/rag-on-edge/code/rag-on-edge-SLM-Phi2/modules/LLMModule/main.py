from flask import Flask, request, jsonify
from cloudevents.http import from_http
from dapr.clients import DaprClient
import json
import os
import logging
from langchain.llms import LlamaCpp
import time
logging.basicConfig(level=logging.DEBUG)

# Number of threads to use for LLM inference: pass as Env Var to override
N_THREADS = int(os.getenv('N_THREADS', os.cpu_count()))
logging.info('Number of threads for SLM inference detected or passed in: ' + str(N_THREADS))

#subscriber using Dapr
app = Flask(__name__)
app_port = os.getenv('SLM_PORT', '8601')

llmmodel = LlamaCpp(model_path="./models/phi-2.Q4_K_M.gguf", verbose=True, n_threads=N_THREADS)

llm_prompt = '''Use the Content to answer the Search Query.

Search Query: 

SEARCH_QUERY_HERE

Content: 

SEARCH_CONTENT_HERE

Answer:
'''

llm_output = '''
Search Content: 

SEARCH_CONTENT_HERE

Answer:

LLM_CONTENT_HERE

'''

# Register Dapr pub/sub subscriptions
@app.route('/dapr/subscribe', methods=['GET'])
def subscribe():
    subscriptions = [{
        'pubsubname': 'edgeragpubsub',
        'topic': 'llm_input_topic',
        'route': 'llm_input_topic_handler'
    }]
    print('Dapr pub/sub is subscribed to: ' + json.dumps(subscriptions))
    return jsonify(subscriptions)

# Dapr subscription in /dapr/subscribe sets up this route
@app.route('/llm_input_topic_handler', methods=['POST'])
def orders_subscriber():
    event = from_http(request.headers, request.get_data())
    user_query = str(event.data['user_query'])
    vdb_result = str(event.data['vdb_result'])
    request_id = event.data['request_id']

    llm_prompt_prepped = llm_prompt.replace('SEARCH_QUERY_HERE',user_query).replace('SEARCH_CONTENT_HERE',vdb_result)
    
    # Perform LLM inference
    inference_result = llm_inference(llm_prompt_prepped)
    # Publish the LLM inference result
    output_result_prepped = llm_output.replace('SEARCH_CONTENT_HERE',vdb_result).replace('LLM_CONTENT_HERE',inference_result)
    #logging.info(output_result_prepped)
    output_message = {"inference_result": output_result_prepped, "request_id": request_id}
    with DaprClient() as client:
        result = client.publish_event(
            pubsub_name='edgeragpubsub',
            topic_name='llm_output_topic',
            data=json.dumps(output_message),
            data_content_type='application/json',
        )
        logging.info('Published data: ' + json.dumps(output_message))
        time.sleep(1)

    return json.dumps({'success':True}), 200, {'ContentType':'application/json'}

def llm_inference(data):
    #logging.info('llm input :' + data)
    llm_response = llmmodel(data)
    llm_response_str=str(llm_response)
    #logging.info('llm response :' + llm_response_str)
    return llm_response_str


if __name__ == '__main__':
    app.run(port=app_port)
