import pytest
from src.prediction.adapters import repository
from src.prediction.domain import model

pytestmark = pytest.mark.usefixtures("mappers")

def test_get_by_transcriptref(sqlite_session_factory):
    session = sqlite_session_factory()
    repo = repository.SqlAlchemyRepository(session)

    t1 = model.Transcript()
    t2 = model.Transcript()
    t3 = model.Transcript()
    transcript_ref = "transcript-1"
    p1 = model.Prediction(
        id="prediction-1",
        transcript_ref=transcript_ref,
        results=[{"label": "label1", "confidence": 0.9}]
    )
    p2 = model.Prediction(
        id="prediction-2",
        transcript_ref=transcript_ref,
        results=[{"label": "label1", "confidence": 0.9}]
    )
    
    repo.add(p1)
    repo.add(p2)

    assert repo.get_by_transcriptref(transcript_ref) == [p1, p2]