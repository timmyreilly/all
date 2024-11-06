from fastapi import FastAPI, Request, HTTPException, status
from lagom import Container, context_dependency_definition
from lagom.integrations.fast_api import FastApiIntegration
from pydantic import BaseModel
from passlib.context import CryptContext
from typing import Iterator, List
import sqlite3

# 1. Password Hashing Setup
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_password_hash(password):
    return pwd_context.hash(password)

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

# 2. Define the `DBConnection` Class
class DBConnection:
    def __init__(self, db_path: str):
        self.db_path = db_path
        self.connection = sqlite3.connect(self.db_path)
        self.connection.row_factory = sqlite3.Row
        self.create_tables()

    def create_tables(self):
        cursor = self.connection.cursor()
        # Create 'users' table
        cursor.execute('''CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            hashed_password TEXT NOT NULL,
            is_active BOOLEAN NOT NULL DEFAULT 1
        )''')
        # Create 'messages' table
        cursor.execute('''CREATE TABLE IF NOT EXISTS messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            content TEXT NOT NULL
        )''')
        self.connection.commit()

    def fetch_data_for_user(self, user_id: int):
        cursor = self.connection.cursor()
        cursor.execute("SELECT username FROM users WHERE id = ?", (user_id,))
        result = cursor.fetchone()
        if result:
            return {"username": result["username"]}
        else:
            return {"username": "Unknown"}

    def close(self):
        self.connection.close()

# 3. Set Up the Container and Dependency
container = Container()

@context_dependency_definition(container)
def db_connection_provider() -> Iterator[DBConnection]:
    db_conn = DBConnection("test.db")
    try:
        yield db_conn
    finally:
        db_conn.close()

# 4. FastAPI Integration
deps = FastApiIntegration(container, request_context_singletons=[DBConnection])

# 5. Initialize the FastAPI App
app = FastAPI()

# 6. Define Pydantic Schemas
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

# 7. Define Endpoints Using `DBConnection`
@app.get("/users/{user_id}", response_model=UserResponse)
async def get_user(user_id: int, db: DBConnection = deps.depends(DBConnection)):
    user_data = db.fetch_data_for_user(user_id)
    if user_data["username"] != "Unknown":
        return UserResponse(id=user_id, username=user_data["username"], is_active=True)
    else:
        raise HTTPException(status_code=404, detail="User not found")

@app.get("/info")
async def get_info(request: Request, db: DBConnection = deps.depends(DBConnection)):
    return {
        "path": request.url.path,
        "db_status": "connected" if db.connection else "disconnected"
    }

@app.get("/messages", response_model=List[MessageResponse])
def get_messages(db: DBConnection = deps.depends(DBConnection)):
    cursor = db.connection.cursor()
    cursor.execute('SELECT id, content FROM messages')
    rows = cursor.fetchall()
    messages = [MessageResponse(id=row['id'], content=row['content']) for row in rows]
    return messages

@app.post("/messages", response_model=MessageResponse)
def create_message(message: MessageSchema, db: DBConnection = deps.depends(DBConnection)):
    cursor = db.connection.cursor()
    cursor.execute('INSERT INTO messages (content) VALUES (?)', (message.content,))
    db.connection.commit()
    message_id = cursor.lastrowid
    return MessageResponse(id=message_id, content=message.content)

@app.post("/users", response_model=UserResponse)
def create_user(user: UserCreate, db: DBConnection = deps.depends(DBConnection)):
    hashed_password = get_password_hash(user.password)
    cursor = db.connection.cursor()
    try:
        cursor.execute('''
            INSERT INTO users (username, hashed_password, is_active)
            VALUES (?, ?, ?)
        ''', (user.username, hashed_password, True))
        db.connection.commit()
        user_id = cursor.lastrowid
        return UserResponse(id=user_id, username=user.username, is_active=True)
    except sqlite3.IntegrityError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username already registered"
        )
