# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

from calendar import month
from fileinput import filename
import logging
import os
import io
import json

import azure.functions as func
from azure.storage.blob import BlobClient

# use managed identity 
from azure.identity import DefaultAzureCredential


import PyPDF2
import datetime


def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    req_body = req.get_json()

    storage_account = req_body.get('storage_account') # 
    input_container = req_body.get('input_container')
    output_container = req_body.get('output_container')
    file_name = req_body.get('file_name') 
    file_path = req_body.get('file_path') # need this to work with adls file structures 

    msg = f"storage_account: {storage_account}. input_container: {input_container}. output_container: {output_container}. \
        file_name: {file_name}. file_path: {file_path}."
   
    if storage_account and input_container and output_container and file_name and file_path:
        logging.info(f"All required fields are received: {msg}")
    else:
        http_body_msg = f"Not all required fields are present: {msg} "
        return func.HttpResponse(body=http_body_msg, status_code=100)
    
    # processing file_path to get the right input for blob downlaod api
    input_container_index = file_path.find(input_container)
    if input_container_index != -1:
        input_container_len = len(input_container)
        start_position = input_container_index + input_container_len 
        input_file_path = file_path[start_position:]
    else:
        input_file_path = file_path

    # sample input_file_path: removed the container name in front of the file_path as input 
    # "input_file_path": "/test-input/ContosoSafety360-Sample-1.pdf"
    # "input_file_path": "/ContosoSafety360-Sample-1.pdf"

    my_account_url = f"https://{storage_account}.blob.core.windows.net" 
    

    try:
        # use managed identity. 
        # RG_MID_CLIENT_ID is the Azure Client ID of the Resource Group Managed Identity. Set in App Settings 
        client_id = os.getenv("RG_MID_CLIENT_ID")
        my_credential = DefaultAzureCredential(managed_identity_client_id=client_id)
        # blob_name can accept file name or file path but not with container name in it. 
        input_blob_client = BlobClient(account_url=my_account_url,container_name=input_container,blob_name=input_file_path,credential=my_credential)
        my_downloader = input_blob_client.download_blob() # This returns instance of StorageStreamDownloader object.
        download_bytes = my_downloader.content_as_bytes(max_concurrency=1) # This operation is blocking until all data is downloaded.

        logging.info(f"Blob download completed")
    
        ###############################################################################################
        # Working wiht OS File Systems 
        # Export 'HOME' envrionment variable using os command or shell script if debugging locally 
        # 'HOME' environment variable needs to be defined in local OS for this to work. 
        OS_LOCAL_HOME = os.environ['HOME'] #  Linux OS_LOCAL_HOME: /home 
            
        DATA_DIR = os.path.join (OS_LOCAL_HOME, "data")  # /home/data. 
        if (not(os.path.exists(DATA_DIR))):
            os.mkdir(DATA_DIR)
        
        logging.info(f"OS_LOCAL_HOME: {OS_LOCAL_HOME}.")
        logging.info(f"DATA_DIR: {DATA_DIR}. Working with OS file system successful")

        temp_input_fp = os.path.join (DATA_DIR, file_name)
        if (os.path.exists(temp_input_fp)):
            os.remove(temp_input_fp)

        # Generate date time object of the run
        date_time_now = datetime.datetime.now()
        date_time = date_time_now.strftime('%Y-%m-%dT%H-%M-%S')
        date_only = date_time_now.strftime('%Y-%m-%d')
        year_number = date_time_now.strftime('%Y')
        month_number = date_time_now.strftime('%m')
        day_number = date_time_now.strftime('%d')
        #time_number = date_time_now.strftime('%H-%M-%S')
        dir_name = year_number + r"/"+ month_number + r"/" + day_number
       
        # Extract original PDF file name
        pdf_prefix_file_name = ''.join(file_name.split('.pdf')[:1]) + '_'

        # Open single or multi-page PDF file and then split 
        with io.BytesIO(download_bytes) as open_pdf_file:
            read_pdf = PyPDF2.PdfFileReader(open_pdf_file)
            # Extract each page and write out to individual file for each page
            output_list = []
            for i in range(read_pdf.numPages):
                output = PyPDF2.PdfFileWriter()
                output.addPage(read_pdf.getPage(i))
            
                # Temporarily write PDF to OS disk
                temp_pdf_fn = pdf_prefix_file_name + str(i + 1) + str(".pdf")
                temp_pdf_fp = os.path.join(DATA_DIR, temp_pdf_fn)
                with open(temp_pdf_fp, "wb") as outputStream:
                    output.write(outputStream)

                # Open os file as rd and then upload to blob. Blob API takes file_path that does not contain container name in the beginning.  
                output_file_path_no_container=  r"/" + dir_name + r"/" + temp_pdf_fn
                output_blob_client = BlobClient(account_url=my_account_url,container_name=output_container, blob_name=output_file_path_no_container, credential=my_credential)
                with open(temp_pdf_fp, 'rb') as upload_data:
                    output_blob_client.upload_blob(upload_data, overwrite=True, blob_type="BlockBlob")
                
                # prepare output / response
                output_file_path = r"/" + output_container + output_file_path_no_container
                ind_item = {
                    'date_time':date_time,
                    'date':date_only,
                    'year':year_number,
                    'month':month_number,
                    'day':day_number,
                    'file_name': temp_pdf_fn,
                    'file_path': output_file_path,
                    'file_path_no_container': output_file_path_no_container
                }
                output_list.append(ind_item)

                # clean up: remove all temp files 
                if (os.path.exists(temp_pdf_fp)):
                    os.remove(temp_pdf_fp)

                logging.info(f"Split File Successful.")
        resp_obj = {
            'single_file_list':output_list
        }
    except Exception as ex_main:
        http_body_msg = f"Exception occurred: {ex_main}"
        logging.error(http_body_msg)
        return func.HttpResponse(body=http_body_msg, status_code=100)
    else:
        return func.HttpResponse(body=json.dumps(resp_obj), status_code=200)
  
            

