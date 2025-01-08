import logging
import os
from typing import List

from src.dependencies import container, engine, get_db_session
from src.models import Base, Message, User
from src.schemas import (MessageResponse, MessageSchema, UserCreate,
                         UserResponse)
from fastapi import APIRouter, Depends, FastAPI, HTTPException, status
from lagom.integrations.fast_api import FastApiIntegration
from passlib.context import CryptContext
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session


## TODO: Refactor out for architecture sake
import jwt
from datetime import datetime, timedelta

SECRET_KEY = "your-secret-key"  # Keep this secret!
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    expire = datetime.now() + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def decode_access_token(token: str):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token has expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")


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
    expose_headers=["Authorization"],
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

# @api_router.post("/token")
# def login_for_access_token(
#     form_data: OAuth2PasswordRequestForm = Depends(),
#     session: Session = deps.depends(Session)
# ):
#     user = session.query(User).filter(User.username == form_data.username).first()
#     if not user or not verify_password(form_data.password, user.hashed_password):
#         raise HTTPException(
#             status_code=status.HTTP_401_UNAUTHORIZED,
#             detail="Incorrect username or password",
#             headers={"WWW-Authenticate": "Bearer"},
#         )
#     access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
#     access_token = create_access_token(
#         data={"sub": user.username}, expires_delta=access_token_expires
#     )
#     return {"access_token": access_token, "token_type": "bearer"}

# # @api_router.get("/users/me", response_model=UserResponse)
# # def read_users_me(current_user: User = Depends(deps.depends(get_current_user))):
# #     return current_user

from fastapi.security import OAuth2PasswordRequestForm

@api_router.post("/login")
def login(form_data: OAuth2PasswordRequestForm = Depends(), session: Session = deps.depends(Session)):
    user = session.query(User).filter(User.username == form_data.username).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid username or password")
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.username}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

from fastapi import Depends
from fastapi.security import OAuth2PasswordBearer

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/login")

def get_current_user(token: str = Depends(oauth2_scheme), session: Session = deps.depends(Session)):
    payload = decode_access_token(token)
    username: str = payload.get("sub")
    if username is None:
        raise HTTPException(status_code=401, detail="Invalid authentication credentials")
    user = session.query(User).filter(User.username == username).first()
    if user is None:
        raise HTTPException(status_code=401, detail="User not found")
    return user


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

@api_router.get("/secmessages", response_model=List[MessageResponse])
def get_messages(current_user: User = Depends(get_current_user), session: Session = deps.depends(Session)):
    messages = session.query(Message).all()
    return messages

@api_router.post("/secmessages", response_model=MessageResponse)
def create_message(message: MessageSchema, current_user: User = Depends(get_current_user), session: Session = deps.depends(Session)):
    db_message = Message(content=message.content, user_id=current_user.id)
    session.add(db_message)
    session.commit()
    session.refresh(db_message)
    return db_message


# Include the API router with a prefix
app.include_router(api_router, prefix="/api")

from fastapi.responses import FileResponse
# Serve the React app
from fastapi.staticfiles import StaticFiles

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
