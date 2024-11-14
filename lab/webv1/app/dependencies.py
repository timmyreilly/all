from lagom import Container, context_dependency_definition
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy import create_engine
from typing import Iterator

DATABASE_URL = "sqlite:///./test.db"

engine = create_engine(
    DATABASE_URL, connect_args={"check_same_thread": False}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Set Up Dependency Injection
container = Container()

@context_dependency_definition(container)
def get_db_session() -> Iterator[Session]:
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()
