FROM python:3.11

# Install necessary tools
RUN apt-get update && apt-get install -y wget && apt -y install nano &&  rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt /app/

RUN pip install --no-cache-dir -r requirements.txt

COPY . /app

# Download the desired file using wget
RUN wget -O phi-2.Q4_K_M.gguf https://huggingface.co/TheBloke/phi-2-GGUF/resolve/main/phi-2.Q4_K_M.gguf

CMD ["python", "keepalive.py"]