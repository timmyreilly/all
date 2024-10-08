import asyncio
import json
from dataclasses import dataclass
import os
from typing import Any, Dict
# from aiohttp import ClientSession

import requests
# from lagom.environment import Env


class AzureGroundednessServiceEnv():
    azure_groundedness_endpoint: str = os.environ.get("GROUNDEDNESS_ENDPOINT", "<your_custom_subdomain>.cognitiveservices.azure.com")
    azure_groundedness_subscription_key: str = os.environ.get("GROUNDEDNESS_API_KEY", "<your_subscription_key>")
    azure_groundedness_full_endpoint: str = f"{azure_groundedness_endpoint}/contentsafety/text:detectGroundedness?api-version=2024-09-15-preview"

@dataclass
class AzureGroundednessService:
    env: AzureGroundednessServiceEnv

    def __post_init__(self):
        self.endpoint = self.env.azure_groundedness_full_endpoint
        self.subscription_key = self.env.azure_groundedness_subscription_key
        self.headers = {
            'Ocp-Apim-Subscription-Key': self.subscription_key,
            'Content-Type': 'application/json'
        }

    def verify_statements_requests(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        """Verify statements using the Azure Groundedness API.

        :param payload: The JSON payload to send to the API.
        :return: The JSON response from the API.
        """
        try:
            response = requests.post(
                url=self.endpoint,
                headers=self.headers,
                json=payload
            )
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"Failed to verify statements: {e}")
            raise

    # async def verify_statements_async(self, payload: Dict[str, Any]) -> Dict[str, Any]:
    #     """Verify statements using the Azure Groundedness API.

    #     :param payload: The JSON payload to send to the API.
    #     :return: The JSON response from the API.
    #     """
    #     try:
    #         async with aiohttp.ClientSession() as session:
    #             async with session.post(
    #                 url=self.endpoint,
    #                 headers=self.headers,
    #                 json=payload
    #             ) as response:
    #                 response.raise_for_status()
    #                 result = await response.json()
    #                 return result
    #     except Exception as e:
    #         print(f"Failed to verify statements: {e}")
    #         raise
