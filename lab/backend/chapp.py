import logging
from fastapi import FastAPI, Request, Depends, HTTPException, status
from lagom import Container, context_dependency_definition
from lagom.integrations.fast_api import FastApiIntegration
from typing import Iterator, List
from sqlalchemy import create_engine, Column, Integer, String, Boolean
from sqlalchemy.orm import sessionmaker, declarative_base, Session
from sqlalchemy.exc import IntegrityError
from pydantic import BaseModel
from passlib.context import CryptContext

logging.getLogger('passlib').setLevel(logging.ERROR)

# Password Hashing Setup
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_password_hash(password):
    return pwd_context.hash(password)

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

# Set Up SQLAlchemy
DATABASE_URL = "sqlite:///./test.db"
engine = create_engine(
    DATABASE_URL, connect_args={"check_same_thread": False}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Define Models
class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    is_active = Column(Boolean, default=True)

class Message(Base):
    __tablename__ = "messages"

    id = Column(Integer, primary_key=True, index=True)
    content = Column(String, index=True)

# Create Tables
Base.metadata.create_all(bind=engine)

# Set Up Dependency Injection
container = Container()

@context_dependency_definition(container)
def get_db_session() -> Iterator[Session]:
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()

deps = FastApiIntegration(container, request_context_singletons=[Session])

# 6. Initialize the FastAPI App
app = FastAPI()

# 7. Define Pydantic Schemas
class UserCreate(BaseModel):
    username: str
    password: str

class UserResponse(BaseModel):
    id: int
    username: str
    is_active: bool

    class Config:
        from_attributes = True

class MessageSchema(BaseModel):
    content: str

class MessageResponse(BaseModel):
    id: int
    content: str

    class Config:
        from_attributes = True

# Define Endpoints
@app.post("/users", response_model=UserResponse)
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

@app.get("/users/{user_id}", response_model=UserResponse)
def get_user(user_id: int, session: Session = deps.depends(Session)):
    user = session.query(User).filter(User.id == user_id).first()
    if user:
        return user
    else:
        raise HTTPException(status_code=404, detail="User not found")

@app.post("/messages", response_model=MessageResponse)
def create_message(message: MessageSchema, session: Session = deps.depends(Session)):
    db_message = Message(content=message.content)
    session.add(db_message)
    session.commit()
    session.refresh(db_message)
    return db_message

@app.get("/messages", response_model=List[MessageResponse])
def get_messages(session: Session = deps.depends(Session)):
    messages = session.query(Message).all()
    return messages
