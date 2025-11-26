from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from datetime import datetime
from typing import List
import os
import redis
import json

app = FastAPI(title="Demo API", version="1.0.0")

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
