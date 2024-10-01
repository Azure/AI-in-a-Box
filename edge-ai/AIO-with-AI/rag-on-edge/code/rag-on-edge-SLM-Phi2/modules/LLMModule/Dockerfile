ARG CUDA_IMAGE="nvidia/cuda:12.0.1-devel-ubuntu22.04"
#ARG N_THREADS=32
FROM ${CUDA_IMAGE}

# Set environment variables
# ENV N_THREADS=32

# Set the working directory
WORKDIR /app

RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential libcurl4-openssl-dev libboost-python-dev libpython3-dev python3 python3-pip cmake curl git&& \
    rm -rf /var/lib/apt/lists/*
RUN pip3 install --upgrade pip
RUN pip3 install setuptools
RUN pip3 install ptvsd==4.1.3
COPY requirements.txt ./
RUN pip3 install -r requirements.txt
RUN pip3 install python-dotenv==0.21.0

# Expose the Dapr sidecar port
EXPOSE 8601

COPY . .

ENTRYPOINT [ "python3", "-u", "./main.py" ]
