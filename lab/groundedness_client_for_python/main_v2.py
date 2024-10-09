import json
import os

from v4 import AzureGroundednessService, AzureGroundednessServiceEnv

def main():
    # Create the environment configuration
    env = AzureGroundednessServiceEnv()

    # Initialize the service
    groundedness_service = AzureGroundednessService(env=env)

    # Path to the JSON file
    json_file_path = 'b_private_sample.json'

    # Check if the file exists
    if not os.path.exists(json_file_path):
        print(f"Error: File '{json_file_path}' not found.")
        print(f"Using the default file 'grounded_sample.json'.")
        json_file_path = 'grounded_sample.json'

    # Read the JSON file
    with open(json_file_path, 'r') as file:
        data = json.load(file)

    payloads = data.get('payloads', [])

    if not payloads:
        print("No payloads found in the JSON file.")
        return

    for idx, payload in enumerate(payloads):
        print(f"\nProcessing payload {idx + 1}/{len(payloads)}:")
        try:
            result = groundedness_service.verify_statements_requests(payload)
            print(json.dumps(result, indent=2))
        except Exception as e:
            print(f"An error occurred while processing payload {idx + 1}: {e}")

if __name__ == "__main__":
    main()
