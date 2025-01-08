# pylint: disable=too-few-public-methods
from dataclasses import dataclass


class Event:
    pass


@dataclass
class Transcribed(Event):
    blob_reference: str
    sku: str
    quality: int
    eta: str = None

@dataclass
class Predicted(Event):
    sku: str
    version_number: int