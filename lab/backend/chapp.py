from fastapi import FastAPI, Request
from lagom import Container, context_dependency_definition
from lagom.integrations.fast_api import FastApiIntegration
from pydantic import BaseModel

from typing import Iterator
import sqlite3

# 1. Define the database connection class
class DBConnection:
    def __init__(self, db_path: str):
        self.db_path = db_path
        self.connection = sqlite3.connect(self.db_path)
        self.connection.row_factory = sqlite3.Row

    def fetch_data_for_user(self, user_id: int):
        cursor = self.connection.cursor()
        cursor.execute("SELECT name FROM users WHERE id = ?", (user_id,))
        result = cursor.fetchone()
        if result:
            return {"name": result["name"]}
        else:
            return {"name": "Unknown"}

    def close(self):
        self.connection.close()

# 2. Set up the container
container = Container()

# 3. Define a context manager dependency for DBConnection
@context_dependency_definition(container)
def db_connection_provider() -> Iterator[DBConnection]:
    db_conn = DBConnection("test.db")
    try:
        yield db_conn
    finally:
        db_conn.close()

# 4. Set up FastApiIntegration with request_context_singletons
deps = FastApiIntegration(container, request_context_singletons=[DBConnection])

# 5. Initialize the FastAPI app
app = FastAPI()

class MessageSchema(BaseModel):
    content: str

class MessageResponse(BaseModel):
    id: int
    content: str

    class Config:
        orm_mode = True

# 6. Define an endpoint that uses the db dependency
@app.get("/users/{user_id}")
async def get_user(user_id: int, db: DBConnection = deps.depends(DBConnection)):
    user = db.fetch_data_for_user(user_id)
    return {"user": user}

# 7. Define another endpoint with access to the Request object
@app.get("/info")
async def get_info(request: Request, db: DBConnection = deps.depends(DBConnection)):
    return {
        "path": request.url.path,
        "db_status": "connected" if db.connection else "disconnected"
    }

