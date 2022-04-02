FROM ubuntu:20.04

# Setup correct timezone
ENV TZ=Europe/Ljubljana
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# apt(-get!) Installation
RUN apt-get update
RUN apt-get install --yes --no-install-recommends asis-programs \
       libgl1-mesa-glx libgl1-mesa-dev libxt-dev \
       gnat \
       gnat-gps \
       googletest \
       clang-format \
       cmake \
       wget build-essential \
       cppcheck 

# Webots installation
RUN wget -qO- https://cyberbotics.com/Cyberbotics.asc | apt-key add - \
    apt-add-repository 'deb https://cyberbotics.com/debian/ binary-amd64/' \
    apt-get update \
    apt-get install webots

# pip Installation
RUN apt-get update
RUN apt-get install --yes --no-install-recommends --fix-missing python python3-pip
RUN pip install black \
       pytest \
       pytest-cov \
       isort \
       coverage \
       gcovr \
       codecov 

# Clean environment
RUN apt-get update && \
    apt-get install -yq --no-install-recommends \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
