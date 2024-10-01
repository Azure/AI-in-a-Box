import streamlit as st
import requests

st.title('Index Management')
st.subheader('Create Index')
index_name = st.text_input('Please input index name')

if st.button('Create Index') or index_name != '':
    if index_name == '':
        st.error('Please input index name!')
        st.stop()
    else:
        with st.spinner('Creating index...'):
            backend_url = 'http://rag-vdb-service:8602/create_index'
            payload = {'index_name': index_name}
            response = requests.post(backend_url, json=payload)
            if response.status_code == 200:
                st.success("Index created successfully!")
            else:
                st.error(f"Failed to create index. Error: {response.text}")
