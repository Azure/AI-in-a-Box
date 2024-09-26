import streamlit as st
import requests

st.title('Index Management')
st.subheader('Delete Index')

# Fetch index names from Chroma backend
backend_url = 'http://rag-vdb-service:8602/list_index_names'  
index_names = requests.get(backend_url).json()['index_names']

with st.spinner(text="Loading..."):
    st.session_state.item = None
    selected_index_name = st.selectbox('Please select an index name.',index_names,index=st.session_state.item)

if st.button('Delete Index'):
    if selected_index_name == None:
        st.stop()
    else:
        with st.spinner('Deleting index...'):
            # Make an API call to Chroma backend to delete the index
            delete_url = 'http://rag-vdb-service:8602/delete_index'  
            payload = {'index_name': selected_index_name}
            response = requests.post(delete_url, json=payload)

            if response.status_code == 200:
                st.session_state.item = None
                st.rerun()
                st.success("Index deleted successfully!")
            else:
                st.error(f"Failed to delete index. Error: {response.text}")
