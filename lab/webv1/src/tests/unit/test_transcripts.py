from datetime import date
from src.prediction.domain.model import Prediction, Transcript


def test_a_transcript_is_complete_if_the_prediction_set_contains_predictions_for_all_batches_of_questions():
    t = Transcript(
        ref="transcript-1",
        sku="sku1",
        quality=1,
        eta=date(2023, 10, 1),
    )
    assert t.is_complete() is False


def test_raises_exception_if_transcripts_are_incomplete():
    t = Transcript(
        ref="transcript-1",
        sku="sku1",
        quality=1,
        eta=date(2023, 10, 1),
    )
    prediction = Prediction("sku1", "transcript-1")

    assert t.is_complete() is False

    t.add_prediction("batch1", "prediction1")
    assert t.is_complete() is False

    t.add_prediction("batch2", "prediction2")
    predict(t, [question_set1, question_set2])
    assert t.is_complete() is True

    # prediction = Prediction("sku1", "transcript-1")
    # positive_feedback = Feedback("sku1", "transcript-1", 1.0)

    # review(prediction, [positive_feedback])

    # assert prediction.is_accepted() == 1.0

    # prediction = Prediction("sku1", "transcript-2")

    # with pytest.raises(Exception):
    #     review(prediction, [positive_feedback])

    # assert prediction.is_accepted() == None