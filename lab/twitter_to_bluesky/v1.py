import os
import json
import requests
from bs4 import BeautifulSoup

# Configuration
TWITTER_ARCHIVE_PATH = "path/to/your/archive.html"
BLUESKY_API_BASE_URL = "https://api.bluesky.social/v1"
BLUESKY_API_KEY = "your_bluesky_api_key"  # Replace with your actual API key
BLUESKY_API_AUTH_TOKEN = "your_auth_token"  # Replace with your auth token

if BLUESKY_API_AUTH_TOKEN is not None:
    TWITTER_ARCHIVE_PATH = os.environ.get("TWITTER_ARCHIVE_PATH")


def extract_tweets_from_html(html_file):
    """Parse the Twitter archive HTML and extract tweets."""
    with open(html_file, 'r', encoding='utf-8') as file:
        soup = BeautifulSoup(file, 'html.parser')

    tweets = []
    for tweet in soup.find_all("div", class_="tweet"):
        tweet_text = tweet.get_text(strip=True)
        media_urls = [img['src'] for img in tweet.find_all("img")]  # Extract media URLs
        tweets.append({"text": tweet_text, "media": media_urls})
    return tweets

def post_to_bluesky(text, media_urls):
    """Publish a tweet and media to Bluesky."""
    # Step 1: Upload media (if any)
    uploaded_media = []
    for media_url in media_urls:
        with open(media_url, 'rb') as media_file:
            media_response = requests.post(
                f"{BLUESKY_API_BASE_URL}/media/upload",
                headers={"Authorization": f"Bearer {BLUESKY_API_AUTH_TOKEN}"},
                files={"file": media_file}
            )
            media_response.raise_for_status()
            uploaded_media.append(media_response.json().get("media_id"))

    # Step 2: Post the tweet
    payload = {"text": text, "media_ids": uploaded_media}
    response = requests.post(
        f"{BLUESKY_API_BASE_URL}/posts",
        headers={"Authorization": f"Bearer {BLUESKY_API_AUTH_TOKEN}"},
        json=payload
    )
    response.raise_for_status()
    return response.json()

def main():
    # Step 1: Extract tweets
    tweets = extract_tweets_from_html(TWITTER_ARCHIVE_PATH)
    print(f"Found {len(tweets)} tweets to post...")

    # Step 2: Post tweets to Bluesky
    for idx, tweet in enumerate(tweets, start=1):
        print(f"Posting tweet {idx}/{len(tweets)}: {tweet['text'][:50]}...")
        try:
            result = post_to_bluesky(tweet['text'], tweet['media'])
            print(f"Posted successfully: {result}")
        except Exception as e:
            print(f"Failed to post tweet: {e}")

if __name__ == "__main__":
    main()
