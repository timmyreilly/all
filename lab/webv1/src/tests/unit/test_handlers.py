# pylint: disable=no-self-use
from __future__ import annotations
from collections import defaultdict
from datetime import date
from typing import Dict, List
import pytest
from src.prediction.adapters import repository, notifications
from src.prediction.domain import commands
from src.prediction import bootstrap

class FakeRepository(repository.AbstractRepository):
    def __init__(self, predictions):
        super().__init__()
        self._predictions = set(predictions)

    def _add(self, product):
        self._predictions.add(prediction)

    def _get(self, sku):
        return next((p for p in self._predictions if p.sku == sku), None)

    def _get_by_transcriptref(self, batchref):
        return next(
            (p for p in self._predictions for b in p.batches if b.reference == batchref),
            None,
        )


class FakeUnitOfWork(unit_of_work.AbstractUnitOfWork):
    def __init__(self):
        self.predictions = FakeRepository([])
        self.committed = False

    def _commit(self):
        self.committed = True

    def rollback(self):
        pass


class FakeNotifications(notifications.AbstractNotifications):
    def __init__(self):
        self.sent = defaultdict(list)  # type: Dict[str, List[str]]

    def send(self, destination, message):
        self.sent[destination].append(message)


def bootstrap_test_app():
    return bootstrap.bootstrap(
        start_orm=False,
        uow=FakeUnitOfWork(),
        notifications=FakeNotifications(),
        publish=lambda *args: None,
    )


class TestAddPrediction:
    def test_for_new_prediction(self):
        bus = bootstrap_test_app()
        bus.handle(commands.CreatePrediction("sku1", "transcript-1"))
        assert bus.uow.predictions.get("transcript-1") is not None
        assert bus.uow.committed


# can't create a prediction without a transcript reference 

# if a prediction has a grounding score less than 0.5, it should not be added to the repository

# if a transcription job is incomplete we should not be able to access the predictions

# if a transcription job is complete we should get an email with the predictions

# if a prediction is accepted it should receive a grounding score of 1.0

# a matching transcript and matching series of predictions should result in the same prediction

# a matching transcript and matching series of predictions should result in different prediction if the prediction configuration is different

# a complete_batch of predictions should be tied to only one transcript

# a transcript can have multiple prediction_sets

# a transcript is complete if the prediction_set contains predictions for all the batches of questions

# a prediction_set is a pairing of questions and predictions once all questions have predictions the prediction_set is complete. 

# a transcript can have multiple predictions_sets 