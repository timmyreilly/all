import pytest
from src.prediction.adapters import repository
from src.prediction.domain import model

pytestmark = pytest.mark.usefixtures("mappers")

def test_get_by_transcriptref(sqlite_session_factory):
    session = sqlite_session_factory()
    repo = repository.SqlAlchemyRepository(session)

    t1 = model.Transcript(ref="ref1", sku="sku1", quality=1, eta=None)
    t2 = model.Transcript(ref="ref2", sku="sku2", quality=2, eta=None)
    t3 = model.Transcript(ref="ref3", sku="sku3", quality=3, eta=None)
    transcript_ref = "transcript-1"
    p1 = model.Prediction(
        id="prediction-1",
        transcript=t1,
        results=[{"label": "label1", "confidence": 0.9}],
        sku="sku1",
    )
    p2 = model.Prediction(
        id="prediction-2",
        transcript=t2,
        results=[{"label": "label1", "confidence": 0.9}],
        sku="sku2",
    )
    
    repo.add(p1)
    repo.add(p2)

    assert repo.get_by_transcriptref(transcript_ref) == [p1, p2]