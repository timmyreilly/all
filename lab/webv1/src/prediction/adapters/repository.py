import abc
from typing import Set
from src.prediction.adapters import orm
from src.prediction.domain import model


class AbstractRepository(abc.ABC):
    def __init__(self):
        self.seen = set()  # type: Set[model.Product]

    @abc.abstractmethod
    def _get_by_transcriptref(self, transcriptref) -> model.Prediction:
        raise NotImplementedError

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

    def _get_by_transcriptref(self, transcriptref):
        return (
            self.session.query(model.Prediction)
            .join(model.Transcript)
            .filter(orm.transcripts.c.reference == transcriptref,)
            .first()
        )

    def add(self, prediction: model.Prediction):
        self.session.add(prediction)