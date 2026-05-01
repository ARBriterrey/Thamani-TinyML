FROM python:3.10-slim

# Install minimal dependencies
USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    procps \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

COPY . .

# Run the python wrapper
CMD ["python", "process.py"]
