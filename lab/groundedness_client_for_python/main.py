import asyncio
import json

from v4 import AzureGroundednessService, AzureGroundednessServiceEnv

async def main():
    # Create the environment configuration
    env = AzureGroundednessServiceEnv()

        # azure_groundedness_endpoint="<your_custom_subdomain>.cognitiveservices.azure.com/contentsafety/text:detectGroundedness?api-version=2024-09-15-preview",
        # azure_groundedness_subscription_key="<your_subscription_key>"
    # )

    # Initialize the service
    groundedness_service = AzureGroundednessService(env=env)

    # Define your payload
    payload = {
        "domain": "Generic",
        "task": "QnA",
        "qna": {
            "query": "How much does she currently get paid per hour at the bank?"
        },
        "text": "12/hour",
        "groundingSources": [
            "I'm 21 years old and I need to make a decision about the next two years of my life..."
        ],
        "reasoning": False
    }

    # Call the async method
    result = groundedness_service.verify_statements_requests(payload)
    print(json.dumps(result, indent=2))

# Run the async main function
asyncio.run(main())


# Get groundedness service

# Verify credentials



# Verify connection



# Use for verification


# Please ground these two statements, given the predicate

"The person is happy with the job done"

"I've been happy with the results, and would like to continue with the next phase of the project"

# Please ground