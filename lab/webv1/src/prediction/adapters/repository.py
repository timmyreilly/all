import abc
from typing import Set
from src.prediction.adapters import orm
from src.prediction.domain import model


class AbstractRepository(abc.ABC):
    def __init__(self):
        self.seen = set()  # type: Set[model.Product]

    def get_by_transcriptref(self, transcript_ref: str) -> list[model.Prediction]:
        prediction = self._get_by_transcriptref(transcript_ref)
        if prediction: 
            self.seen.add(prediction)
        return [prediction]


class SqlAlchemyRepository(AbstractRepository):
    def __init__(self, session):
        super().__init__()
        self.session = session

    def _add(self, product):
        self.session.add(product)
