from fastapi import FastAPI, Depends
from lagom import Container
from lagom.integrations.fast_api import FastApiIntegration
from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.orm import sessionmaker, declarative_base, Session
from contextlib import contextmanager
from pydantic import BaseModel
from typing import List

# Database configuration
DATABASE_URL = "sqlite:///./test.db"

Base = declarative_base()

# SQLAlchemy ORM model
class Message(Base):
    __tablename__ = 'messages'
    id = Column(Integer, primary_key=True, index=True)
    content = Column(String)

engine = create_engine(DATABASE_URL, echo=True)
SessionLocal = sessionmaker(bind=engine)

# Create the database tables
Base.metadata.create_all(bind=engine)

# Dependency Injection container setup
container = Container()

@contextmanager
def get_session() -> Session:
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()

# Register the context manager using container.define()
container.define(Session, get_session)

lagom = FastApiIntegration(container)

# FastAPI app initialization
app = FastAPI()

# Pydantic models for request and response schemas
class MessageSchema(BaseModel):
    content: str

class MessageResponse(BaseModel):
    id: int
    content: str

    class Config:
        orm_mode = True

# API endpoint to get all messages
@app.get("/messages", response_model=List[MessageResponse])
def get_messages(session: Session = Depends(lagom.depends(Session))):
    messages = session.query(Message).all()
    return messages

# API endpoint to create a new message
@app.post("/messages", response_model=MessageResponse)
def create_message(message: MessageSchema, session: Session = Depends(lagom.depends(Session))):
    db_message = Message(content=message.content)
    session.add(db_message)
    session.commit()
    session.refresh(db_message)
    return db_message
