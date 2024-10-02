# Law Firm Assistant

## Overview
This sample provides a guide to use the new Web Browser tool with the Azure OpenAI Assistants. 
This tool is based on Bing Search API and allows to easily implement a public web data grounding.


Given LLMs have data available only up to a cut off date, it might not handle questions that require up-to-date information.
And this is where the Web Browse tool comes in handy!


## Objective
The objective of this sample is to create an OpenAI assistant for law firms that helps answer questions about court cases.
Besides using the browser tool, the assistant will also use the [file search tool](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/file-search?tabs=python) to search for information in the law firm's index.

The assistant is implemented through a CLI in python (command line interface) which the user can use to interact with the assistant.

By the end of this tutorial, you should be able to:
- Create an OpenAI assistant that uses the Web Browse and the File Search tools

## Programming Languages
- Python

## Estimated Runtime: 10 mins

## Pre-requisites
- A [Azure OpenAI](https://azure.microsoft.com/en-us/products/ai-services/openai-service) resource (API key + endpoint)
- A [Bing Search](https://www.microsoft.com/en-us/bing/apis/bing-custom-search-api?msockid=05017416a2426182001960bfa3e36056) resource
  - The Bing resource should be a Bing Search v7 resource and the SKU should be S15 or S16
  - The Azure OpenAI resource needs to have 'Contributor' role on the selected Bing resource to use it
- Python 3.10 or later

## Running the sample

### Step 1: Fill in the environment variables
Create an `.env` file with the following environment variables:
```commandline
OPENAI_KEY="<openai_key>"
OPENAI_ENDPOINT="<openai_endpoint>"
BING_RESOURCE_ID="<bing_resource_id>"
```

Note: The first time you run, an assistant and vector stored will be created. Its ids will be stored in a new `assistant.env` file, which is used to load the assistant and vector in the following runs.


### Step 2: Install requirements
```commandline
pip install -r requirements.txt
```

### Step 3: Run the sample
```commandline
python app.py
```

In order to exit the application you can type `exit`.
```commandline
Your input: exit
```

## Example
```commandline
I'm a law firm assistant. 
How can I help you with court cases!
        
Your input: >? do we have any internal case about waste disposal?
Assistant: Yes, we have an internal case related to waste disposal:
**Case Title:** Contoso Company v. United States Environmental Protection Agency (EPA)  
**Docket Number:** 24-1234  
**Facts of the Case:** Contoso Company, a major manufacturer of electronic components, was fined by the EPA for allegedly violating environmental regulations related to the disposal of hazardous waste. Contoso argued that the regulations were overly vague and that they had taken all reasonable steps to comply with environmental laws.
**Legal Question:** Does the EPA’s regulation on hazardous waste disposal violate the Due Process Clause of the Fifth Amendment by being unconstitutionally vague?
**Arguments:**
- **Contoso Company:** They contended that the EPA’s regulations were so vague that they did not provide a clear standard for compliance, thus violating the company’s right to due process. They argued that the fines imposed were unjust and that the regulations needed to be more specific to be enforceable.
- **EPA:** The EPA argued that the regulations were clear and necessary to protect the environment and public health. They maintained that Contoso failed to meet the established standards and that the fines were justified.
**Decision:** The Supreme Court ruled in favor of the EPA, holding that the regulations were sufficiently clear and that Contoso had not demonstrated that they were unconstitutionally vague. The Court emphasized the importance of environmental protection and the need for companies to adhere to established standards.
**Opinion:** Justice Smith, writing for the majority, stated that while regulations must be clear, they do not need to be perfectly precise. The Court found that the EPA’s guidelines provided adequate notice of what was required and that Contoso had ample opportunity to comply【4:0†source】.

Your input: >? list me 3 similar external cases from the last month
Assistant: Here are three recent external cases related to waste disposal from July 2024:
1. **Hawkins v. Hopkinsville Solid Waste Enterprise et al**  
   **Court:** US District Court for the Western District of Kentucky  
   **Filed:** July 28, 2024  
   **Details:** This case involves a dispute over waste disposal practices by the Hopkinsville Solid Waste Enterprise【8:0†source】.
2. **Agarin v. Waste Management Solution LLC a/k/a WM Solutions d/b/a WM et al**  
   **Court:** New York Eastern District Court  
   **Filed:** July 31, 2024  
   **Details:** This case includes allegations of improper handling and disposal of personal injury-related waste by WM Solutions【8:1†source】.
3. **Zurich American Insurance Company v. Discount Waste, Inc. et al**  
   **Filed:** July 26, 2024  
   **Details:** The insurance company filed a complaint against Discount Waste for damages related to improper waste disposal practices【8:3†source】.
Url citations: 
* 【8:0†source】 - [Hawkins v. Hopkinsville Solid Waste Enterprise et al](https://dockets.justia.com/docket/kentucky/kywdce/5:2024cv00130/135679)
* 【8:0†source】 - [Calendars - District Court - King County, Washington](https://kingcounty.gov/en/court/district-court/courts-jails-legal-system/court-calendars-locations-operations/calendars)
* 【8:1†source】 - [Agarin v. Waste Management Solution LLC a/k/a WM Solutions d/b/a WM et ...](https://www.pacermonitor.com/public/case/54510346/Agarin_v_Waste_Management_Solution_LLC_aka_WM_Solutions_dba_WM_et_al)
* 【8:1†source】 - [Calendars - District Court - King County, Washington](https://kingcounty.gov/en/court/district-court/courts-jails-legal-system/court-calendars-locations-operations/calendars)
* 【8:3†source】 - [Zurich American Insurance Company v. Discount Waste, Inc. et al](https://dockets.justia.com/docket/florida/flmdce/3:2024cv00753/430469)
* 【8:3†source】 - [Calendars - District Court - King County, Washington](https://kingcounty.gov/en/court/district-court/courts-jails-legal-system/court-calendars-locations-operations/calendars)

Your input: >? compare the contoso case against the external ones in a table format
Assistant: Here is a comparison of the Contoso case against the three recent external cases in a table format:
| **Aspect** | **Contoso Company v. EPA** | **Hawkins v. Hopkinsville Solid Waste Enterprise et al** | **Agarin v. Waste Management Solution LLC et al** | **Zurich American Insurance Company v. Discount Waste Inc. et al** |
|------------|----------------------------|--------------------------------------------------------|--------------------------------------------------|---------------------------------------------------------------|
| **Court** | U.S. Supreme Court | U.S. District Court for the Western District of Kentucky | New York Eastern District Court | (Court not specified in available details) |
| **Date Filed** | (Filed on unspecified date) | July 28, 2024 | July 31, 2024 | July 26, 2024 |
| **Parties Involved** | Contoso Company, EPA | Hawkins, Hopkinsville Solid Waste Enterprise | Agarin, Waste Management Solution LLC (WM Solutions), WM | Zurich American Insurance Company, Discount Waste Inc. |
| **Legal Question** | Constitutionality of EPA's hazardous waste disposal regulations | Dispute over waste disposal practices | Improper handling and disposal of personal injury-related waste | Damages related to improper waste disposal practices |
| **Main Argument (Plaintiff)** | EPA's regulations were vague, violating due process | Waste disposal practices were improper or harmful | Mismanagement of waste, leading to personal injury | Improper waste disposal causing damages |
| **Main Argument (Defendant)** | Regulations were clear and necessary for environmental protection | (Not specified in available details) | (Not specified in available details) | (Not specified in available details) |
| **Decision** | EPA's regulations upheld; found sufficiently clear and enforceable | (Decision pending) | (Decision pending) | (Decision pending) |
This table highlights the main aspects and differences between the Contoso case and the three recent external cases related to waste disposal.
```

```
[2024-08-01 14:00:43 - assistant:36 - INFO] Vector store with id <id> already exists
[2024-08-01 14:00:44 - assistant:68 - INFO] Assistant with id <id> already exists
[2024-08-01 14:00:44 - cli:19 - INFO] starting conversation with assistant (assistant_id=<id>, thread_id=<id>)
[2024-08-01 14:00:55 - event_handler:21 - INFO] started calling tool file_search
[2024-08-01 14:00:58 - event_handler:24 - INFO] completed calling tool file_search
[2024-08-01 14:01:04 - event_handler:24 - INFO] completed calling tool file_search
[2024-08-01 14:01:04 - event_handler:24 - INFO] completed calling tool file_search
[2024-08-01 14:01:04 - event_handler:44 - INFO] completed conversation with assistant
[2024-08-01 14:01:20 - event_handler:21 - INFO] started calling tool browser
[2024-08-01 14:01:21 - event_handler:24 - INFO] completed calling tool browser
[2024-08-01 14:01:24 - event_handler:24 - INFO] completed calling tool browser
[2024-08-01 14:01:24 - event_handler:24 - INFO] completed calling tool browser
[2024-08-01 14:01:24 - event_handler:44 - INFO] completed conversation with assistant
[2024-08-01 14:01:58 - event_handler:44 - INFO] completed conversation with assistant

```

## Understanding the Solution

### OpenAI Client

- Create an OpenAI client with:
  - at least `2024-07-01-preview` version
  - passing the header "X-Ms-Enable-Preview": "true"
```python
  client = AzureOpenAI(
      api_key=openai_key,
      api_version="2024-07-01-preview",
      azure_endpoint=openai_endpoint,
      default_headers={"X-Ms-Enable-Preview": "true"} 
  )
```

### Vector Store

- Create a vector store
```python
# assistant.py
vector_store = client.beta.vector_stores.create(name="courtcases")
```

- Upload files to vector store
```python
# assistant.py
client.beta.vector_stores.file_batches.upload_and_poll(
    vector_store_id=vector_store_id, files=file_streams
)
```

### Assistant
- Create the assistant with file search and browser tools
  - browser tool needs the bing resource id
  - file search tool needs the vector store id
```python
# assistant.py
assistant = client.beta.assistants.create(
    name="Law firm copilot",
    instructions='''
You are a law firm assistant that answers questions about court cases.

You are only allowed to:
- use the file search tool to search for internal court cases
- use the browser tool to look for court cases on the web

You are not allowed to answer questions that are not related to court cases
    ''',
    tools=[{
        "type": "file_search"
    }, {
        "type": "browser",
        "browser": {
            "bing_resource_id": bing_resource_id
        }
    }],
    tool_resources={
        "file_search": {
            "vector_store_ids": [vector_store_id]
        }
    },
    model="gpt-4o-0513",
)
```

## FAQ

### How can I validate whether a tool was called?
You can validate the browser tool was called by checking the logs (`app.log` file). You should see a log similar to the following:
```
INFO:event_handler:completed calling tool <tool_name>
```

If you want you can also debug the `event_handler.py` file. 
When the tool call is completed, the `on_tool_call_done` method is called. You can add a breakpoint there to check the response.