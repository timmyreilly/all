from datetime import date
from src.prediction.domain.model import Transcript


def test_a_transcript_is_complete_if_the_prediction_set_contains_predictions_for_all_batches_of_questions():
    t = Transcript(
        ref="transcript-1",
        sku="sku1",
        quality=1,
        eta=date(2023, 10, 1),
    )
    assert t.is_complete() is False