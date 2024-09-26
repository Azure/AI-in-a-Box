import re
import PyPDF2

class NormalizeText:
    # s is input text
    def normalize_text(self, s, sep_token = " \n "):
        s = re.sub(r'\s+',  ' ', s).strip()
        s = re.sub(r". ,","",s)
        # remove all instances of multiple spaces
        s = s.replace("..",".")
        s = s.replace(". .",".")
        s = s.replace("\n", "")
        s = s.strip()
        return s

    def normalize_text_to_page_item(self, s, sep_token = " \n "):
        array = s.extract_text().split("\n ")
        return array

    def normalize_text_to_itemtext(self, pagesitem, sep_token = " \n "):
        texts = ''
        # for item in pagesitem:
        page_text = pagesitem.strip()
        pageArray = page_text.split("\n")
        for pageitem in pageArray:
            line = pageitem.strip()
            if line != "":
                texts+=line            
        return self.normalize_text(texts)
    
    def get_doc_content(self, pdf_file):
        item_list = []
        pdf_reader = PyPDF2.PdfReader(pdf_file)  
        for page in pdf_reader.pages:  
            pagesitems = self.normalize_text_to_page_item(page)
            for pagesitem in pagesitems:
                page_text = pagesitem.strip()
                if page_text == "" or page_text.isdigit():
                    continue      
                line = self.normalize_text_to_itemtext(page_text)
                item_list.append(line)
        return item_list
    
    def get_doc_content_txt(self, pdf_file):
        long_text = ""
        pdf_reader = PyPDF2.PdfReader(pdf_file)  
        for page in pdf_reader.pages:  
            content = page.extract_text()
            long_text += content
        return long_text