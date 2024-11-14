import logging
from fastapi import FastAPI, Depends, HTTPException, status
from lagom.integrations.fast_api import FastApiIntegration
from sqlalchemy.exc import IntegrityError
from passlib.context import CryptContext
from typing import List
import os
from sqlalchemy.orm import Session

from app.dependencies import container, get_db_session
from app.models import Base, engine, User, Message
from app.schemas import (
    UserCreate, UserResponse,
    MessageSchema, MessageResponse
)

# Create Tables
Base.metadata.create_all(bind=engine)

# Password Hashing Setup
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
logging.getLogger('passlib').setLevel(logging.ERROR)

def get_password_hash(password):
    return pwd_context.hash(password)

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

deps = FastApiIntegration(container, request_context_singletons=[Session])

app = FastAPI()

# Serve the React App
from fastapi.staticfiles import StaticFiles

build_dir = os.path.join(os.path.dirname(__file__), '../frontend/build')

if os.path.isdir(build_dir):
    app.mount("/", StaticFiles(directory=build_dir, html=True), name="react_app")
else:
    @app.get("/")
    def read_root():
        return {"message": "React app not found. Please build the frontend."}

# User Endpoints
@app.post("/api/users", response_model=UserResponse)
def create_user(user: UserCreate, session: Session = deps.depends(Session)):
    hashed_password = get_password_hash(user.password)
    db_user = User(
        username=user.username,
        hashed_password=hashed_password
    )
    session.add(db_user)
    try:
        session.commit()
        session.refresh(db_user)
    except IntegrityError:
        session.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username already registered"
        )
    return db_user

@app.get("/api/users/{user_id}", response_model=UserResponse)
def get_user(user_id: int, session: Session = deps.depends(Session)):
    user = session.query(User).filter(User.id == user_id).first()
    if user:
        return user
    else:
        raise HTTPException(status_code=404, detail="User not found")

# Message Endpoints
@app.post("/api/messages", response_model=MessageResponse)
def create_message(message: MessageSchema, session: Session = deps.depends(Session)):
    db_message = Message(content=message.content)
    session.add(db_message)
    session.commit()
    session.refresh(db_message)
    return db_message

@app.get("/api/messages", response_model=List[MessageResponse])
def get_messages(session: Session = deps.depends(Session)):
    messages = session.query(Message).all()
    return messages
