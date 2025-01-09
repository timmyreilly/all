

from src.prediction.domain.model import Prediction, Feedback


def test_prediction_is_accepted_should_receive_a_grounding_score_of_1():

    prediction = Prediction("sku1", "transcript-1")
    positive_feedback = Feedback("sku1", "transcript-1", 1.0)

    review(prediction, [positive_feedback])

    assert prediction.is_accepted() == 1.0

def test_prediction_is_accepted_is_idempotent():

    prediction = Prediction("sku1", "transcript-1")
    positive_feedback = Feedback("sku1", "transcript-1", 1.0)

    review(prediction, [positive_feedback])
    review(prediction, [positive_feedback])

    assert prediction.is_accepted() == 1.0

    
def test_prediction_is_rejected_should_receive_a_grounding_score_of_0():

    prediction = Prediction("sku1", "transcript-1")
    negative_feedback = Feedback("sku1", "transcript-1", 0.0)

    review(prediction, [negative_feedback])

    assert prediction.is_accepted() == 0.0


