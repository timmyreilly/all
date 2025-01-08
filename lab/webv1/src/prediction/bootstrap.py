import inspect
from typing import Callable
from prediction.service_layer import handlers, messagebus, unit_ofwork

def bootstrap(
        start_orm: bool = True, 
        uow: unit_of_work.AbstractUnitOfWork = unit_of_work.SqlAlchemyUnitOfWork,
) -> messagebus.MessageBus:
    