import asyncio
import json
from dataclasses import dataclass
import os
import pytest
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


from unittest.mock import patch, Mock



# Pytest fixtures for setup
@pytest.fixture
def env():
    # Set up the environment with valid values
    env = AzureGroundednessServiceEnv()
    env.azure_groundedness_endpoint = "https://test-endpoint.cognitiveservices.azure.com"
    env.azure_groundedness_subscription_key = "valid_subscription_key"
    env.azure_groundedness_full_endpoint = f"{env.azure_groundedness_endpoint}/contentsafety/text:detectGroundedness?api-version=2024-09-15-preview"
    return env

@pytest.fixture
def service(env):
    return AzureGroundednessService(env=env)

@pytest.fixture
def payload():
    return {
        "domain": "Generic",
        "task": "QnA",
        "qna": {
            "query": "How much does she currently get paid per hour at the bank?"
        },
        "text": "12/hour",
        "groundingSources": [
            "Sample grounding source text..."
        ],
        "reasoning": False
    }

# Test cases using pytest
def test_successful_verify_statements(service, payload):
    """Test that a successful API call returns the expected result."""
    with patch('requests.post') as mock_post:
        # Mock the response to simulate a successful API call
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"result": "success"}
        mock_post.return_value = mock_response

        # Call the method
        result = service.verify_statements_requests(payload)

        # Assertions
        assert result == {"result": "success"}
        mock_post.assert_called_once_with(
            url=service.endpoint,
            headers=service.headers,
            json=payload
        )

def test_verify_statements_404_error(service, payload):
    """Test that a 404 error raises an HTTPError."""
    with patch('requests.post') as mock_post:
        # Mock the response to simulate a 404 Not Found error
        mock_response = Mock()
        mock_response.raise_for_status.side_effect = requests.exceptions.HTTPError(response=mock_response)
        mock_response.status_code = 404
        mock_response.text = 'Not Found'
        mock_post.return_value = mock_response

        # Call the method and assert that an HTTPError is raised
        with pytest.raises(requests.exceptions.HTTPError):
            service.verify_statements_requests(payload)

        mock_post.assert_called_once_with(
            url=service.endpoint,
            headers=service.headers,
            json=payload
        )

def test_verify_statements_invalid_credentials(service, payload):
    """Test that invalid credentials raise an HTTPError."""
    with patch('requests.post') as mock_post:
        # Mock the response to simulate a 401 Unauthorized error
        mock_response = Mock()
        mock_response.raise_for_status.side_effect = requests.exceptions.HTTPError(response=mock_response)
        mock_response.status_code = 401
        mock_response.text = 'Unauthorized'
        mock_post.return_value = mock_response

        # Call the method and assert that an HTTPError is raised
        with pytest.raises(requests.exceptions.HTTPError):
            service.verify_statements_requests(payload)

        mock_post.assert_called_once_with(
            url=service.endpoint,
            headers=service.headers,
            json=payload
        )