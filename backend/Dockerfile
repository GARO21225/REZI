FROM python:3.11-slim

WORKDIR /app

# Dépendances système
RUN apt-get update && apt-get install -y \
    libpq-dev gcc gdal-bin libgdal-dev \
    && rm -rf /var/lib/apt/lists/*

# Dépendances Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Code source
COPY . .

# Dossiers uploads
RUN mkdir -p uploads/photos uploads/documents

EXPOSE 8000
# Railway utilise la variable PORT
CMD sh -c "alembic upgrade head && uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}"
