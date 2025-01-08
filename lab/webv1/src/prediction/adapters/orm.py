import logging
from sqlalchemy import (
    Table,
    MetaData,
    Column,
    Integer,
    String,
    Date,
    ForeignKey,
    event,
)
from sqlalchemy.orm import mapper, relationship

from src.prediction.domain import model

logger = logging.getLogger(__name__)

metadata = MetaData()

def start_mappers():
    logger.info("start mappers")