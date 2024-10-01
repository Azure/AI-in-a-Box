#FROM python:3.8-bullseye ----unsupported version of sqlite3. Chroma requires sqlite3 more than 3.35.0
#FROM python:3.10-bullseye  -----unsupported version of sqlite3. Chroma requires sqlite3 more than 3.35.0
#FROM python:3.13.0a2-bullseye  ---not working with ptvsd==4.1.3, and other dependecies
#FROM python:3.13-rc-bullseye   ---not working with ptvsd==4.1.3, and other dependecies
FROM mcr.microsoft.com/devcontainers/base:ubuntu AS base
#ARG CUDA_IMAGE="nvidia/cuda:12.0.1-devel-ubuntu22.04"
#FROM ${CUDA_IMAGE}

# Set the working directory
WORKDIR /app
RUN apt-get update
RUN apt-get install python3-pip -y

RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential libcurl4-openssl-dev libboost-python-dev libpython3-dev python3 python3-pip cmake curl git&& \
    rm -rf /var/lib/apt/lists/*
RUN pip3 install --upgrade pip
RUN pip3 install setuptools
COPY requirements.txt ./
RUN pip3 install -r requirements.txt
RUN pip3 install python-dotenv==0.21.0

# Expose the Dapr sidecar port
EXPOSE 8602

COPY . .

ENTRYPOINT [ "python3", "-u", "./main.py" ]
