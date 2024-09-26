'''this interface module will do the following:
-Receive user input from frontend web app
-Publish user input to the broker
-Setup subscriber for llm_result
'''
from flask import Flask, request, jsonify
from cloudevents.http import from_http
from dapr.clients import DaprClient
import json
import os
import logging
import time
import uuid
#logging.basicConfig(level=logging.DEBUG)

# Maintain a dictionary to store pending requests
pending_requests = {}

#subscriber using Dapr PubSub
app = Flask(__name__)
app_port = os.getenv('RAG_PORT', '8701')

def publish_message(data_json):
    with DaprClient() as client:
        result = client.publish_event(
            pubsub_name='edgeragpubsub',
            topic_name='vdb_input_topic',
            data=json.dumps(data_json),
            data_content_type='application/json',
        )
        logging.info('Published data: ' + json.dumps(data_json))
        time.sleep(1)

# API for receiving user input from the frontend web app
@app.route('/webpublish', methods=['POST'])
def publish():
    data = request.json
    web_user_query = data.get('user_query')
    web_index_name = data.get('index_name')

    if web_user_query:
        # Generate a unique ID for the request
        request_id = str(uuid.uuid4())
        # Store the request with its unique ID
        pending_requests[request_id] = {"web_user_query": web_user_query, "web_index_name": web_index_name}
        # Publish the user input 
        web_message = {"web_user_query": web_user_query, "web_index_name": web_index_name, "request_id": request_id}
        publish_message(web_message)
        return jsonify({'status': 'success', 'message': 'User input published to the broker', 'request_id': request_id})
    return jsonify({'status': 'error', 'message': 'Invalid user input'})

@app.route('/check_processed_result/<request_id>', methods=['GET'])
def check_processed_result(request_id):
    if request_id in pending_requests:
        if "processed_result" in pending_requests[request_id]:
            processed_result = pending_requests[request_id]["processed_result"]
            return jsonify({'status': 'success', 'processed_result': processed_result})
    
    return jsonify({'status': 'pending'})


# backend
# Register Dapr pub/sub subscriptions
@app.route('/dapr/subscribe', methods=['GET'])
def subscribe():
    subscriptions = [{
        'pubsubname': 'edgeragpubsub',
        'topic': 'llm_output_topic',
        'route': 'llm_output_topic_handler'
    }]
    print('Dapr pub/sub is subscribed to: ' + json.dumps(subscriptions))
    return jsonify(subscriptions)

# Dapr subscription in /dapr/subscribe
@app.route('/llm_output_topic_handler', methods=['POST'])
def orders_subscriber():
    event = from_http(request.headers, request.get_data())
    print('Subscriber received : %s' % event.data['inference_result'], flush=True)
    # Associate the processed result with the request ID
    processed_result = str(event.data['inference_result'])
    request_id = event.data['request_id']
    pending_requests[request_id]["processed_result"] = processed_result

    return json.dumps({'success':True}), 200, {'ContentType':'application/json'}


if __name__ == '__main__':
    #app.run(port=app_port)
    app.run(host='0.0.0.0', port=app_port)

