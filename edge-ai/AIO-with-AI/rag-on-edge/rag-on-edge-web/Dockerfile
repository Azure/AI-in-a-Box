FROM mcr.microsoft.com/devcontainers/base:ubuntu AS base
WORKDIR /app

RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential libcurl4-openssl-dev libboost-python-dev libpython3-dev python3 python3-pip cmake curl git&& \
    rm -rf /var/lib/apt/lists/*
RUN pip3 install --upgrade pip
RUN pip3 install setuptools
RUN pip3 install ptvsd==4.1.3

COPY ./requirements.txt /app/requirements.txt
RUN pip install -r requirements.txt
RUN pip3 install python-dotenv==0.21.0

EXPOSE 8501

COPY . .

ENTRYPOINT ["streamlit", "run", "page_home.py", "--server.port=8501", "--server.address=0.0.0.0"]
