# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

from dataclasses import field
import logging
import json
import os

import uuid

import azure.functions as func

from azure.storage.blob import BlobClient

# use managed identity 
from azure.identity import DefaultAzureCredential

# formrecognizer
from azure.ai.formrecognizer import DocumentAnalysisClient
from azure.core.credentials import AzureKeyCredential

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')
    
    try:
        req_body = req.get_json()

        storage_account = req_body.get('storage_account')
        input_container = req_body.get('input_container')
        output_container = req_body.get('output_container')
        file_name = req_body.get('file_name')
        file_path = req_body.get('file_path')
        date_time = req_body.get('date_time')
        date_only = req_body.get('date')
        year_number = req_body.get('year')
        month_number = req_body.get('month')
        day_number = req_body.get('day')
        
        #sample: 
        #file_path = r"/files-2-split/ContosoSafety360-Sample-1.pdf"

        base_name = os.path.basename(file_path)
        ext_split = os.path.splitext(base_name)
        file_name_no_ext = ext_split[0]

        msg = f"storage_account: {storage_account}. input_container: {input_container}. output_container: {output_container}.\
            file_name: {file_name}. file_path: {file_path}. \
            date_time: {date_time} year: {year_number}. month: {month_number}. day:{day_number} "
   
        if storage_account and input_container and output_container \
            and file_name and file_path \
            and date_time and year_number and month_number and day_number:
            logging.info(f"All required fields are received: {msg}")
        else:
            http_body_msg = f"Not all required fields are present in requet: {msg} "
            return func.HttpResponse(body=http_body_msg, status_code=100)

        my_account_url = f"https://{storage_account}.blob.core.windows.net"
        input_blob_url = f"{my_account_url}" + f"{file_path}"  # preferred method 

        ################################################################## 
        # Establish Security Model 
        # Use Managed Identity 
        # RG_MID_CLIENT_ID is the Azure Client ID of the Resource Group Managed Identity. Set in Fuctions App Settings   
        client_id = os.getenv("RG_MID_CLIENT_ID")
        my_credential = DefaultAzureCredential(managed_identity_client_id=client_id)

        ##################################################################
        # Start working with form recognizer 
        ##################################################################

        # All set as environment varibales in Fuctions App Settings 
        fr_endpoint = os.getenv("AZURE_FORM_RECOGNIZER_ENDPOINT")
        apim_key = os.getenv("AZURE_FORM_RECOGNIZER_KEY")
        model_id = os.getenv("CUSTOM_BUILT_MODEL_ID")
        
        document_analysis_client = DocumentAnalysisClient(
        endpoint=fr_endpoint, credential=AzureKeyCredential(apim_key))

        poller = document_analysis_client.begin_analyze_document_from_url(
                model=model_id, document_url=input_blob_url)
        analyzedResult = poller.result() # analyzedResult -AnalyzeResult Class 

        logging.info(f"form recognizer analyzed successfully.")

        ##################################################################
        # End working with form recognizer 
        ##################################################################

        ################################################################## 
        # Process form Recognizer Output 
        # Prepare output files for uploading to Azure Storage 
        # Prepare HTTP Output
        field_list = [] # List of Objects
        table_list = []
        doc_data_list = [] # List of Objects
        uuid_str = str(uuid.uuid4())  
        # Working with info obtained from fields.json 
        for idx, doc in enumerate(analyzedResult.documents):     
            # doc is AnalyzedDocument
            # docStr = str(doc.fields)   # doc.fields type is dict
            # docBytes = bytes(docStr, 'utf-8')
            doc_idx = idx+1
            # compare with fields defined in fields.json (or another file name holding same info)
            for field in doc.fields:
                if doc.fields[field].value_type == 'list':
                    my_list = doc.fields[field].value
                    table_list = []
                    for item in my_list:
                        for value in item.value:
                            table_column_value = item.value[value].value if item.value[value].value else item.value[value].content
                            table_record = {
                                'column_key': value, 
                                'column_type':table_column_value, 
                                'column_value':item.value[value].value_type
                            }
                            table_list.append(table_record)
                        table_master_record = {
                            'id':uuid_str,
                            'field_key':field,
                            'field_type':doc.fields[field].value_type,
                            'filed_value':{'table_columns':table_list}
                        }
                    field_list.append(table_master_record)
                        
                        
                else:    
                    field_value = doc.fields[field].value if doc.fields[field].value else doc.fields[field].content
                    data_record = {
                        'id':uuid_str, # added for easier PBI visualization. 
                        'field_key': field,
                        'field_type': doc.fields[field].value_type,
                        'field_value': field_value,
                        'field_confidence': doc.fields[field].confidence
                        }
                    field_list.append(data_record)

            logging.info(f"Number of fields recognized: {len(field_list)}")
              
            # prepare and upload output data to Azure Storage 
            doc_data = {
                'doc_idx':doc_idx,
                'id':uuid_str,
                'field_list':field_list
            }
            doc_data_list.append(doc_data)
          
        output_data = {
            'id': uuid_str,
            'date_time':date_time,
            'date':date_only,
            'year':year_number,
            'month':month_number,
            'day':day_number,
            'file_name':file_name,
            'file_path':file_path,
            'doc_data_list':doc_data_list
        }

    except Exception as ex_main:
        logging.error(f"Exception occurred: {ex_main}. ")
    else:
        logging.info(f"Processing Successful. Ready save data to Azure Data Lake Storage and then to send response to sender.")
        output_data_json  = json.dumps(output_data)
        output_data_file = file_name_no_ext +  "_doc_" + str(doc_idx) + ".json"
        dir_name = year_number + r"/"+ month_number + r"/" + day_number
        output_file_path_no_container=  r"/" + dir_name + r"/" + output_data_file 
        output_blob_client = BlobClient(account_url=my_account_url,container_name=output_container, blob_name=output_file_path_no_container, credential=my_credential)
        output_blob_client.upload_blob(output_data_json, overwrite=True, blob_type="BlockBlob")
        # return output data to caller as http body 
    return func.HttpResponse(body=output_data_json, status_code=200)

