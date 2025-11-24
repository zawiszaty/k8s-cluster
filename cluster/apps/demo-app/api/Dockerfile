FROM python:3.11-slim

WORKDIR /app

# Skopiuj requirements i zainstaluj zależności
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Skopiuj kod aplikacji
COPY main.py .

# Ustaw użytkownika dla bezpieczeństwa
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

# Start aplikacji
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
