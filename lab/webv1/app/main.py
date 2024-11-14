import logging
from fastapi import FastAPI, Depends, HTTPException, status
from lagom.integrations.fast_api import FastApiIntegration
from sqlalchemy.exc import IntegrityError
from passlib.context import CryptContext
from typing import List
import os
from sqlalchemy.orm import Session

from app.dependencies import container, get_db_session, engine
from app.models import Base, User, Message
from app.schemas import (
    UserCreate, UserResponse,
    MessageSchema, MessageResponse
)
from fastapi import APIRouter

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

# CORS middleware, etc.
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],  # React dev server origin
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Define API routes using APIRouter
api_router = APIRouter()

# User Endpoints
@api_router.post("/users", response_model=UserResponse)
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

@api_router.get("/users/{user_id}", response_model=UserResponse)
def get_user(user_id: int, session: Session = deps.depends(Session)):
    user = session.query(User).filter(User.id == user_id).first()
    if user:
        return user
    else:
        raise HTTPException(status_code=404, detail="User not found")

# Message Endpoints
@api_router.post("/messages", response_model=MessageResponse)
def create_message(message: MessageSchema, session: Session = deps.depends(Session)):
    db_message = Message(content=message.content)
    session.add(db_message)
    session.commit()
    session.refresh(db_message)
    return db_message

@api_router.get("/messages", response_model=List[MessageResponse])
def get_messages(session: Session = deps.depends(Session)):
    messages = session.query(Message).all()
    return messages

# Include the API router with a prefix
app.include_router(api_router, prefix="/api")

# Serve the React app
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

build_dir = os.path.join(os.path.dirname(__file__), '../frontend/build')

if os.path.isdir(build_dir):
    # Serve static files from the build directory
    app.mount("/static", StaticFiles(directory=os.path.join(build_dir, "static")), name="static")

    # Catch-all route to serve index.html
    @app.get("/{full_path:path}")
    async def serve_react_app(full_path: str):
        index_path = os.path.join(build_dir, "index.html")
        if os.path.exists(index_path):
            return FileResponse(index_path)
        else:
            raise HTTPException(status_code=404, detail="React app not found")
else:
    @app.get("/")
    def read_root():
        return {"message": "React app not found. Please build the frontend."}
