class LangChanSplitter:

    def RecursiveCharacterTextSplitter(self, chunk_size, chunk_overlap, content):
        from langchain.text_splitter import RecursiveCharacterTextSplitter
        text_splitter = RecursiveCharacterTextSplitter(
            chunk_size = chunk_size,
            chunk_overlap  = chunk_overlap,
            length_function = len,
        )
        doc_list = text_splitter.create_documents([content])
        contents = [item.page_content for item in doc_list]
        return contents
    
    def TokenTextSplitter(self, chunk_size, chunk_overlap, content):
        from langchain.text_splitter import TokenTextSplitter
        text_splitter = TokenTextSplitter(chunk_size=chunk_size, chunk_overlap=chunk_overlap)
        doc_list = text_splitter.split_text(content)
        return doc_list