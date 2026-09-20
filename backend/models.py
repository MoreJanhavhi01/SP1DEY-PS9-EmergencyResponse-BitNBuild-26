from sqlalchemy import Column, Integer, String

from database import Base


""" class Incident(Base):
    __tablename__ = "incidents"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    description = Column(String)
    location = Column(String)
    status = Column(String) """