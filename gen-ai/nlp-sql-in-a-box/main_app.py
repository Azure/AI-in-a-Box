import os
import semantic_kernel as sk
from semantic_kernel.connectors.ai.open_ai import AzureChatCompletion
from plugins.ttsPlugin.ttsPlugin import TTSPlugin
from plugins.sttPlugin.sttPlugin import STTPlugin
from dotenv import load_dotenv
import pyodbc
import time
import asyncio

# Native functions are used to call the native skills
# 1. Create speech from the text
# 2. Create text from user's voice through microphone
def nativeFunctions(kernel, context, plugin_class,skill_name, function_name):
    native_plugin = kernel.import_skill(plugin_class, skill_name)
    function = native_plugin[function_name]
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    try:
        result = function.invoke(context=context)
        return result["result"]
    finally:
        loop.close()    
    return None

# Create speech from the text
def speak_out_response(kernel, context, content):
    context["content"] = content
    context["speech_key"] = os.getenv("speech_key")
    context["speech_region"] = os.getenv("speech_region")
    nativeFunctions(kernel, context, TTSPlugin(), "ttsPlugin", "speak_out_response")

# Create text from user's voice through microphone
def recognize_from_microphone(kernel, context):
    context["speech_key"] = os.getenv("speech_key")
    context["speech_region"] = os.getenv("speech_region")
    return nativeFunctions(kernel, context, STTPlugin(), "sttPlugin", "recognize_from_microphone")    

# Semantic functions are used to call the semantic skills
# 1. nlp_sql: Create SQL query from the user's query
def semanticFunctions(kernel, skills_directory, skill_name, input):
    functions = kernel.import_semantic_skill_from_directory(skills_directory, "plugins")
    summarizeFunction = functions[skill_name]
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    try:
        result = summarizeFunction(input)
    finally:
        loop.close()
    return result

# Function to get the result from the database
def get_result_from_database(sql_query):
    server_name = os.environ.get("server_name")
    database_name = os.environ.get("database_name")
    username = os.environ.get("SQLADMIN_USER")
    password = os.environ.get("SQL_PASSWORD")
    conn = pyodbc.connect('DRIVER={driver};SERVER={server_name};DATABASE={database_name};UID={username};PWD={password}'.format(driver="ODBC Driver 18 for SQL Server",server_name=server_name, database_name=database_name, username=username, password=password))
    
    cursor = conn.cursor()
    try:
        cursor.execute(sql_query)
        result = cursor.fetchone()
    except:
        return "No Result Found"
    cursor.close()
    conn.close()
    return result[0]

def main():

    #Load environment variables from .env file
    load_dotenv()

    # Create a new kernel
    kernel = sk.Kernel()
    context = kernel.create_new_context()
    context['result'] = ""

    # Configure AI service used by the kernel
    deployment, api_key, endpoint = sk.azure_openai_settings_from_dot_env()

    # Add the AI service to the kernel
    kernel.add_text_completion_service("dv", AzureChatCompletion(deployment_name=deployment, endpoint=endpoint, api_key=api_key))

    # Starting the Conversation
    speak_out_response(kernel,context,"....Welcome to the Kiosk Bot!! I am here to help you with your queries. I am still learning. So, please bear with me.")

    repeat = True
    while(repeat):
        speak_out_response(kernel,context,"Please ask your query through the Microphone:")
        print("Listening:")

        # Taking Input from the user through the Microphone
        query = recognize_from_microphone(kernel, context)
        print("Processing........")
        print("The query is: {}".format(query))
        
        # Processing the query
        # Generating summary
        skills_directory = "."
        sql_query = semanticFunctions(kernel, skills_directory, "nlpToSQLPlugin", query)
        sql_query = sql_query.result.split(';')[0]
        print("The SQL query is: {}".format(sql_query))

        # Use the query to call the database and get the output
        result = get_result_from_database(sql_query)
        # Speak out the result to the user
        speak_out_response(kernel,context,"The result of your query is: {}".format(result))

        speak_out_response(kernel,context,"Do you have any other query? Say Yes to Continue")
        # Taking Input from the user
        print("Listening:")
        user_input = recognize_from_microphone(kernel, context)
        print(user_input)
        if user_input == 'Yes.':
            repeat = True
        else:
            repeat = False
            speak_out_response(kernel,context,"Thank you for using the Kiosk Bot. Have a nice day.")


if __name__ == "__main__":
    start = time.time()
    main()
    print("Time taken Overall(mins): ", (time.time() - start)/60)