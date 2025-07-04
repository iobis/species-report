# Base image with Python and R
FROM rocker/r-ver:4.3.2

# System dependencies
RUN apt-get update && apt-get install -y \
    python3 python3-pip \
    libcurl4-openssl-dev libssl-dev libxml2-dev \
    libfontconfig1-dev libharfbuzz-dev libfribidi-dev \
    wget unzip curl git \
    chromium-browser \
    && apt-get clean

# Install Python dependencies
COPY requirements.txt /app/requirements.txt
RUN pip3 install --no-cache-dir -r /app/requirements.txt

# Install R packages
RUN Rscript -e "install.packages(c('ggplot2', 'dplyr', 'pagedown', 'httr', 'jsonlite', 'sf'), repos='https://cloud.r-project.org')"

# Install Quarto
RUN wget https://quarto.org/download/latest/quarto-linux-amd64.deb && \
    dpkg -i quarto-linux-amd64.deb && \
    rm quarto-linux-amd64.deb

# Set workdir
WORKDIR /app
COPY . /app

# Default command
CMD ["python3", "app.py"]
