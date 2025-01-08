from prediction.service_layer import unit_of_work

def predictions(predictionId: str, uow: unit_of_work.SqlAlchemyUnitOfWork):
    with uow:
        results = uow.session.execute(
            """
            SELECT * FROM predictions WHERE id = :predictionId
            """,
            dict(predictionId=predictionId)
        )
    return [dict(r)_ for r in results]