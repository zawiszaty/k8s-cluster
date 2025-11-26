from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from datetime import datetime
from typing import List
import os
import redis
import json

# OpenTelemetry imports
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.redis import RedisInstrumentor

# Configure OpenTelemetry
def configure_opentelemetry():
    """Configure OpenTelemetry tracing"""
    # Create resource with service information
    resource = Resource.create({
        "service.name": os.getenv("OTEL_SERVICE_NAME", "demo-api"),
        "service.version": "1.1.0",
        "deployment.environment": os.getenv("ENVIRONMENT", "production")
    })

    # Create tracer provider
    tracer_provider = TracerProvider(resource=resource)

    # Configure OTLP exporter
    otlp_endpoint = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT")
    if otlp_endpoint:
        # Note: OTLPSpanExporter automatically appends /v1/traces to the endpoint
        otlp_exporter = OTLPSpanExporter(
            endpoint=otlp_endpoint,
        )
        tracer_provider.add_span_processor(BatchSpanProcessor(otlp_exporter))

    # Set as global tracer provider
    trace.set_tracer_provider(tracer_provider)

    # Instrument Redis
    RedisInstrumentor().instrument()

# Initialize OpenTelemetry
configure_opentelemetry()

app = FastAPI(title="Demo API", version="1.1.0")

# Instrument FastAPI
FastAPIInstrumentor.instrument_app(app)

# CORS for frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Redis connection
REDIS_HOST = os.getenv("REDIS_HOST", "redis")
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))

redis_client = redis.Redis(
    host=REDIS_HOST,
    port=REDIS_PORT,
    decode_responses=True,
    socket_connect_timeout=5,
    socket_timeout=5
)

MESSAGES_KEY = "demo:messages"

class Message(BaseModel):
    text: str

@app.get("/")
def read_root():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "Demo API",
        "version": "1.0.0",
        "timestamp": datetime.now().isoformat(),
        "hostname": os.getenv("HOSTNAME", "unknown")
    }

@app.get("/api/messages")
def get_messages():
    """Get all messages"""
    try:
        # Get all messages from Redis list
        messages_raw = redis_client.lrange(MESSAGES_KEY, 0, -1)
        messages = [json.loads(msg) for msg in messages_raw]

        return {
            "messages": messages,
            "count": len(messages),
            "timestamp": datetime.now().isoformat()
        }
    except redis.RedisError as e:
        raise HTTPException(status_code=503, detail=f"Redis connection error: {str(e)}")

@app.post("/api/messages")
def create_message(message: Message):
    """Create a new message"""
    if not message.text or len(message.text.strip()) == 0:
        raise HTTPException(status_code=400, detail="Message text cannot be empty")

    try:
        # Get current message count for ID
        message_count = redis_client.llen(MESSAGES_KEY)

        new_message = {
            "id": message_count + 1,
            "text": message.text,
            "timestamp": datetime.now().isoformat(),
            "hostname": os.getenv("HOSTNAME", "unknown")
        }

        # Store message in Redis list
        redis_client.rpush(MESSAGES_KEY, json.dumps(new_message))

        return {
            "message": "Message created successfully",
            "data": new_message
        }
    except redis.RedisError as e:
        raise HTTPException(status_code=503, detail=f"Redis connection error: {str(e)}")

@app.get("/health")
def health_check():
    """Health check for Kubernetes"""
    return {"status": "ok"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
