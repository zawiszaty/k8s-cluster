from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from datetime import datetime
from typing import List
import os

app = FastAPI(title="Demo API", version="1.0.0")

# CORS for frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory storage
messages: List[dict] = []

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
    return {
        "messages": messages,
        "count": len(messages),
        "timestamp": datetime.now().isoformat()
    }

@app.post("/api/messages")
def create_message(message: Message):
    """Create a new message"""
    if not message.text or len(message.text.strip()) == 0:
        raise HTTPException(status_code=400, detail="Message text cannot be empty")

    new_message = {
        "id": len(messages) + 1,
        "text": message.text,
        "timestamp": datetime.now().isoformat(),
        "hostname": os.getenv("HOSTNAME", "unknown")
    }
    messages.append(new_message)

    return {
        "message": "Message created successfully",
        "data": new_message
    }

@app.get("/health")
def health_check():
    """Health check for Kubernetes"""
    return {"status": "ok"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
