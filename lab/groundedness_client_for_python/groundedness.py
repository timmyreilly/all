import asyncio
import json
from dataclasses import dataclass
from typing import Any, Dict

import requests
# from lagom.environment import Env


class AzureGroundednessServiceEnv(Env):
    azure_groundedness_endpoint: str = os.getenv("AZURE_GROUNDEDNESS_ENDPOINT")
    azure_groundedness_subscription_key: str = os.getenv("AZURE_GROUNDEDNESS_SUBSCRIPTION_KEY")


@dataclass
class AzureGroundednessService:
    env: AzureGroundednessServiceEnv

    def __post_init__(self):
        self.endpoint = self.env.azure_groundedness_endpoint
        self.subscription_key = self.env.azure_groundedness_subscription_key
        self.headers = {
            'Ocp-Apim-Subscription-Key': self.subscription_key,
            'Content-Type': 'application/json'
        }

    async def verify_statements(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        """Verify statements using the Azure Groundedness API.

        :param payload: The JSON payload to send to the API.
        :return: The JSON response from the API.
        """
        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    url=self.endpoint,
                    headers=self.headers,
                    json=payload
                ) as response:
                    response.raise_for_status()
                    result = await response.json()
                    return result
        except Exception as e:
            print(f"Failed to verify statements: {e}")
            raise

    def verify_statements_sync(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        """Synchronous version of verify_statements for non-async contexts.

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
        except Exception as e:
            print(f"Failed to verify statements: {e}")
            raise
