import requests
import os
import json

def get_groundedness_service(endpoint, subscription_key):
    headers = {
        'Ocp-Apim-Subscription-Key': subscription_key,
        'Content-Type': 'application/json'
    }
    return headers

def verify_statements(endpoint, headers, payload):
    try:
        print(f"Endpoint: {endpoint}")
        print(f"Headers: {headers}")
        print(f"Payload: {json.dumps(payload, indent=2)}")
        
        response = requests.post(endpoint, headers=headers, data=json.dumps(payload))
        if response.status_code == 200:
            print("Request successful.")
            print(response.json())
        else:
            print(f"Failed to verify statements: {response.status_code}")
            print(response.text)
    except Exception as e:
        print(f"Failed to verify statements: {e}")

def main():
    endpoint = os.environ.get("GROUNDEDNESS_ENDPOINT", "<your_custom_subdomain>.cognitiveservices.azure.com")
    subscription_key = os.environ.get("GROUNDEDNESS_API_KEY", "<your_subscription_key>")
    
    print(f"Environment Endpoint: {endpoint}")
    print(f"Environment Subscription Key: {subscription_key}")
    
    full_endpoint = f"{endpoint}/contentsafety/text:detectGroundedness?api-version=2024-09-15-preview"
    print(f"Full Endpoint: {full_endpoint}")
    
    headers = get_groundedness_service(endpoint, subscription_key)
    
    payload = {
        "domain": "Generic",
        "task": "QnA",
        "qna": {
            "query": "How much does she currently get paid per hour at the bank?"
        },
        "text": "12/hour",
        "groundingSources": [
            "I'm 21 years old and I need to make a decision about the next two years of my life. Within a week. I currently work for a bank that requires strict sales goals to meet. IF they aren't met three times (three months) you're canned. They pay me 10/hour and it's not unheard of to get a raise in 6ish months. The issue is, **I'm not a salesperson**. That's not my personality. I'm amazing at customer service, I have the most positive customer service \"reports\" done about me in the short time I've worked here. A coworker asked \"do you ask for people to fill these out? you have a ton\". That being said, I have a job opportunity at Chase Bank as a part time teller. What makes this decision so hard is that at my current job, I get 40 hours and Chase could only offer me 20 hours/week. Drive time to my current job is also 21 miles **one way** while Chase is literally 1.8 miles from my house, allowing me to go home for lunch. I do have an apartment and an awesome roommate that I know wont be late on his portion of rent, so paying bills with 20hours a week isn't the issue. It's the spending money and being broke all the time.\n\nI previously worked at Wal-Mart and took home just about 400 dollars every other week. So I know i can survive on this income. I just don't know whether I should go for Chase as I could definitely see myself having a career there. I'm a math major likely going to become an actuary, so Chase could provide excellent opportunities for me **eventually**."
        ],
        "reasoning": False
    }
    
    verify_statements(full_endpoint, headers, payload)

if __name__ == "__main__":
    main()