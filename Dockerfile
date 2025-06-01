# Start from a slim, production-ready base image
FROM python:3.13-slim

# Set environment variables for Python (avoids .pyc files, and enables unbuffered logs)
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Install OS dependencies for running Python, FastAPI, and uvicorn
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set work directory
WORKDIR /app

# Copy only the requirements first for caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy app source code
COPY . .

# Expose the port uvicorn will run on
EXPOSE 8085

# Run the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8085"]


#Uses a minimal base image (python:3.11-slim) to reduce image size and attack surface.
#Separates dependency installation and app code for better Docker caching.
#Avoids unnecessary OS packages.
#Uses unbuffered logging for container log streaming.
#Cleans up APT cache to reduce final image size.