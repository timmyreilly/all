from __future__ import annotations
from dataclasses import dataclass
from datetime import date
from typing import Optional, List, Set
from . import commands, events


class Prediction:
    def __init__(self, sku: str, transcript: List[Transcript], version_number: int = 0, id: Optional[str] = None, results: Optional[List[dict]] = None):
        self.id = None
        self.sku = sku
        self.transcript = transcript
        self.results = []
        self.version_number = version_number
        self.events = []  # type: List[events.Event]

@dataclass(unsafe_hash=True)
class PredictionLine:
    predictionid: str
    citation: str
    text: str

@dataclass(frozen=True)
class Feedback:
    sku: str
    transcript: str
    score: float

@dataclass(frozen=True)
class QuestionAnswerPair:
    question: str
    answer: str


# entities are identified by a reference, a transcript has persistent identity

class Transcript:
    def __init__(self, ref: str, sku: str, quality: int, eta: Optional[date]):
        self.blob_reference = ref
        self.sku = sku
        self.eta = eta
        self._transcript_quality = quality
        self._predictions = set()  # type: Set[OrderLine]

    def __hash__(self):
        return hash(self.blob_reference)
    
    def __eq__(self, other):
        if not isinstance(other, Transcript):
            return False
        return other.blob_reference == self.blob_reference

    @property
    def is_complete(self):
        return all(allocation.is_complete for allocation in self._allocations)