# Travel Planner Assistant

## Overview
This sample provides a guide to use the new Web Browse tool with the Azure OpenAI Assistants. 
This tool is based on Bing Search API and allows to easily implement a public web data grounding.


Given LLMs have data available only up to a cut off date, it might not handle questions that require up-to-date information.
And this is where the Web Browse tool comes in handy!


## Objective
The objective of this sample is to create an OpenAI assistant that can help you plan your trip and which will use the Web Browse 
tool whenever it needs to get the latest information related to the trip.

The assistant will be implemented through a CLI in python (command line interface) which the user can use to interact with the assistant.

By the end of this tutorial, you should be able to:
- Create an OpenAI assistant that uses the Web Browse tool

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

Note: The first time you run, an assistant will be created. Its id will be stored in a new `assistant.env` file, which is used to load the assistant in the following runs.


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
I'm a travel planner copilot. 
Please let me know what you are looking for and I'll try to suggest a nice trip for you!

Your input: I'm trying to plan a trip in august and that lasts 5 days. I'm looking for a place that is warm and is not expected to rain. It would be great if there is a rock concert by the same time, like foo fighters or metallica. I would be leaving from Quebec city. Could you come up with a suggestion for this trip?

Based on your preferences and the available information, here’s a trip suggestion for you!

**City:** Foxborough, Massachusetts  
**Start and End Date:** 2024-08-16 to 2024-08-21

**Cost Breakdown:**
- Flights: A roundtrip flight from Quebec City to Boston Logan International Airport may cost approximately CAD 350-550, depending on the booking class and how far in advance you book.
- Accommodation: For a mid-range hotel, expect to pay about USD 150-250 per night. Total for 5 nights: approx. USD 750-1250.
- Car Rental: A car rental for the duration might cost around USD 300-500.
- Concert Tickets: Depending on seating, a ticket for the Metallica concert might range from USD 100 to 400 or more.
- Food and Miscellaneous: Approximately USD 50-100 per day. Total for 5 days: USD 250-500.
- Total Estimate: CAD 350-550 (Flight) + USD 1600-2650 (Stay, Car, Concert, Misc) exchanged to CAD at current rates.

**Weather Forecast:** The historical average for Foxborough in August has been warm with temperatures around 86°F (30°C). Typically, there’s a moderate chance of precipitation but relatively warm weather overall.

**Attractions:**
- **Metallica Concert**: Metallica will be rocking out at the Gillette Stadium in Foxborough on August 16, 2024. Make sure to book your tickets in advance as these events tend to sell out quickly!
- **Patriot Place**: Next to Gillette Stadium, this venue offers shopping, dining, and entertainment options to enjoy during your stay.
- **The Hall at Patriot Place**: A great place for sports fans to visit, featuring New England Patriots’ history and memorabilia.
- **Nearby Boston**: If time permits, take a trip into Boston to walk the Freedom Trail, visit the Museum of Fine Arts, or enjoy the local cuisine.

**Useful Information:**
- Book concert tickets as soon as possible to ensure availability and potentially better prices.
- Renting a car would be optimal for commuting between Boston and Foxborough, especially after the concert.
- Check the weather forecast closer to the departure date for a more accurate outlook and to plan your packing appropriately.

Remember to book accommodations and flights early for better rates, and have a fantastic time rocking out with Metallica!
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

### Assistant
- Create the assistant with file search and browser tools
  - browser tool needs the bing resource id
  - file search tool needs the vector store id
```python
# assistant.py
assistant = client.beta.assistants.create(
    name="Travel planner copilot",
    instructions='''
You are travel planner that helps people plan trips across the world.

The user might give you constraints like:
- destination
- weather preference
- attractions preference
- date preference

When asked for up-to-date information, you should use the browser tool.

You should try to give a plan in the following format:
- city
- start and end date
- cost breakdown
- weather forecast
- attractions and any useful information about tickets.
    ''',
    tools=[{
        "type": "browser",
        "browser": {
            "bing_resource_id": bing_resource_id
        }
    }],
    model="gpt-4-1106-preview",
)
```

## FAQ

## How can I validate the browser tool was called?
You can validate the browser tool was called by checking the logs (`app.log` file). You should see a log similar to the following:
```
INFO:event_handler:completed calling tool browser
```

If you want you can also debug the `event_handler.py` file. 
When the tool call is completed, the `on_tool_call_done` method is called. You can add a breakpoint there to check the response.
