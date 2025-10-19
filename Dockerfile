# Use an official lightweight Python image
FROM python:3.11-slim

# Prevent interactive prompts during apt installs
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies and Microsoft ODBC Driver 18 for SQL Server
RUN apt-get update && apt-get install -y \
    curl gnupg2 apt-transport-https unixodbc unixodbc-dev \
    && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/debian/12/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update && ACCEPT_EULA=Y apt-get install -y msodbcsql18 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy only dependency files first for better caching
COPY requirements.txt ./

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the project
COPY . .

# Expose the default port for Cloud Run
ENV PORT=8080

# Optional: Disable Flask debug mode in production
ENV FLASK_ENV=production

# Run Gunicorn (recommended for production)
CMD exec gunicorn --bind :$PORT --workers 2 --threads 4 --timeout 0 app:app
