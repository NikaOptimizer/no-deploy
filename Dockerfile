# Use an Ubuntu base
FROM python:3.13-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install Python and pip (and build deps for many Python packages)
RUN apt-get -y update && apt-get -y upgrade && apt-get -y install python3 python3-virtualenv python3-pip 
RUN python3 -m pip install --upgrade pip
RUN pip install --upgrade setuptools packaging

# Create user 'nika' with home directory and libs folder
RUN useradd -m -s /bin/bash nika \
 && mkdir -p /home/nika/libs \
 && chown -R nika:nika /home/nika

WORKDIR /home/nika

# Copy and install Python requirements
COPY requirements.txt /tmp/requirements.txt
RUN python3 -m pip install --no-cache-dir -r /tmp/requirements.txt \
 && rm /tmp/requirements.txt

# Run container as user 'nika' by default
USER nika
CMD ["/bin/bash"]