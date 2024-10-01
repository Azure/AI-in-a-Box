from langchain_community.llms import LlamaCpp

llmmodel = LlamaCpp(model_path="./phi-2.Q4_K_M.gguf", verbose=True, n_threads=8)
print(llmmodel("what is a docker container?"))