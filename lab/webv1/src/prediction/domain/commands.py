# pylint: disable=too-few-public-methods
from datetime import date
from typing import Optional
from dataclasses import dataclass


class Command:
    pass


@dataclass
class Transcribe(Command):
    blob_reference: str
    sku: str
    quality: int
    eta: Optional[date] = None