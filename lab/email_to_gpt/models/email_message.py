
#email message pydantic model
from pydantic import BaseModel
from typing import List

class EmailMessage(BaseModel):
    subject: str
    body: str
    recipients: List[str]
    sender: str

    class Config:
        orm_mode = True