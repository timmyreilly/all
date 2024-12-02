# demo service and model 

from lab.email_to_gpt.models.email_message import EmailMessage

message = EmailMessage(
    subject="Hello",
    body="Hello, how are you?"
    sender="timreilly@demo.com"
    recipients=["timreilly@demo.com"]
)

response = gpt.generate_response(message)

message_handler(message)


message_response = message_handler.get_response() 


message = {
    "subject": "Today: 8-10", 
    "body": "Please take the subject of this sentence as complete the task by interpreting the details of date and time and generating a ics file as the only response output",
}

response = gpt.generate_response(message)

link = upload_ics_to_blob_storage(response)

# reply with link to ics file 
email_service.send_email(message["recipients"], link)


import getpass
import os

os.environ["OPENAI_API_KEY"] = getpass.getpass()

from langchain_openai import ChatOpenAI

model = ChatOpenAI(model="gpt-4")