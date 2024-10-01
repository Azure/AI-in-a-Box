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
from function.ChromaHelper import ChromaHelper
from function.NormalizeText import NormalizeText
from function.LangChainChunking import LangChanSplitter
from io import BytesIO 
import pandas as pd
import numpy as np
import base64

#logging.basicConfig(level=logging.DEBUG)

#subscriber using Dapr PubSub
app = Flask(__name__)
app_port = os.getenv('VDB_PORT', '8602')

chromaHelper = ChromaHelper()

def publish_message(data_json):
    with DaprClient() as client:
        result = client.publish_event(
            pubsub_name='edgeragpubsub',
            topic_name='llm_input_topic',
            data=json.dumps(data_json),
            data_content_type='application/json',
        )
        logging.info('Published data: ' + json.dumps(data_json))
        time.sleep(1)

# APIs for receiving http request from the frontend web app
@app.route('/list_index_names', methods=['GET'])
def list_index_names():
    index_names = chromaHelper.list_index_names()
    return jsonify({'status': 'success', 'message': 'index name list is retrieved', 'index_names': index_names})

@app.route('/create_index', methods=['POST'])
def create_index():
    data = request.json
    index_name = data.get('index_name')
    if not index_name:
        return jsonify({'status': 'error', 'message': 'Index name not provided'}), 400
    try:
        chromaHelper.create_index(index_name)
        return jsonify({'status': 'success', 'message': 'Index created successfully'})
    except Exception as e:
        return jsonify({'status': 'error', 'message': f'Error creating index: {str(e)}'}), 500

@app.route('/delete_index', methods=['POST'])
def delete_index():
    data = request.json
    index_name = data.get('index_name')
    if not index_name:
        return jsonify({'status': 'error', 'message': 'Index name not provided'}), 400
    try:
        chromaHelper.delete_index(index_name)
        return jsonify({'status': 'success', 'message': 'Index deleted successfully'})
    except Exception as e:
        return jsonify({'status': 'error', 'message': f'Error deleting index: {str(e)}'}), 500
    
@app.route('/upload_file', methods=['POST'])
def upload_file():
    data = request.json
    index_name = data.get('index_name')
    base64_data = data.get('file_data')
    # ids = data.get('ids')
    # documents = data.get('documents')

    if not index_name or not base64_data:
        return jsonify({'status': 'error', 'message': 'Index name or file_data are not provided'}), 400

    try:
        # Convert Base64-encoded string back to bytes
        bytes_data = base64.b64decode(base64_data.encode('utf-8'))
        pdf_file = BytesIO(bytes_data)
        # read pdf file
        pdf_reader = NormalizeText()
        longtxt = pdf_reader.get_doc_content_txt(pdf_file)

        pdf_reader = LangChanSplitter()
        stirnglist = pdf_reader.TokenTextSplitter(100,10,longtxt)

        df = pd.DataFrame({'document': stirnglist})
        df = df.dropna() 
        df['id'] = df.apply(lambda x : str(uuid.uuid4()), axis=1)  

        # split df to 50 records per batch
        df_array = np.array_split(df, len(df) // 50 + 1)  
        data_array_count = len(df_array)

        new_df_array = []
        current_job_number = 1
        for sub_df in df_array:
            logging.info("working on: " + str(current_job_number) + "/" +str(data_array_count))

            documents = sub_df["document"].to_list()
            ids = sub_df["id"].to_list()  
            chromaHelper.upload_documents(index_name, ids, documents)

            new_df_array.append(sub_df)
            current_job_number+=1
        new_df = pd.concat(new_df_array, axis=0, ignore_index=True) 
        logging.info(str(len(new_df)) + " records uploaded.")

        return jsonify({'status': 'success', 'message': f'{str(len(new_df))} records uploaded successfully'})
    except Exception as e:
        return jsonify({'status': 'error', 'message': f'Error uploading file: {str(e)}'}), 500


# Backend receive web query and vdb search
# Register Dapr pub/sub subscriptions
@app.route('/dapr/subscribe', methods=['GET'])
def subscribe():
    subscriptions = [{
        'pubsubname': 'edgeragpubsub',
        'topic': 'vdb_input_topic',
        'route': 'vdb_input_topic_handler'
    }]
    print('Dapr pub/sub is subscribed to: ' + json.dumps(subscriptions))
    return jsonify(subscriptions)

# Dapr subscription in /dapr/subscribe sets up this route
@app.route('/vdb_input_topic_handler', methods=['POST'])
def orders_subscriber():
    event = from_http(request.headers, request.get_data())
    print('Subscriber received : %s' % event.data['web_user_query'], flush=True)
    # Associate the processed result with the request ID
    # Perform Chroma operations using the backend
    user_query = str(event.data['web_user_query'])
    index_name = str(event.data['web_index_name'])
    request_id = event.data['request_id']

    vdb_result = chromaHelper.similarity_search(index_name, user_query)
    vdb_result_json = {'user_query': user_query, 'vdb_result': vdb_result["documents"][0][0], 'request_id': request_id}
    publish_message(vdb_result_json)
    return json.dumps({'success':True}), 200, {'ContentType':'application/json'}


if __name__ == '__main__':
    #app.run(port=app_port)
    app.run(host='0.0.0.0', port=app_port)

