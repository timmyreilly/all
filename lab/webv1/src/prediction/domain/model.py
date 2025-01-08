from __future__ import annotations
from dataclasses import dataclass
from datetime import date
from typing import Optional, List, Set
from . import commands, events


class Prediction:
    def __init__(self, sku: str, transcript: List[Transcript], version_number: int = 0):
        self.sku = sku
        self.transcript = transcript
        self.version_number = version_number
        self.events = []  # type: List[events.Event]


class Transcript:
    def __init__(self, ref: str, sku: str, quality: int, eta: Optional[date]):
        self.blob_reference = ref
        self.sku = sku
        self.eta = eta
        self._transcript_quality = quality
        self._allocations = set()  # type: Set[OrderLine]
