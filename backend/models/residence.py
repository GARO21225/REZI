from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, Text, JSON
from sqlalchemy.sql import func
from database import Base

class Residence(Base):
    __tablename__ = "residences"
    id = Column(Integer, primary_key=True, index=True)
    proprietaire_id = Column(Integer)
    titre = Column(String, nullable=False)
    adresse = Column(String)
    ville = Column(String)
    commune = Column(String)
    quartier = Column(String)
    latitude = Column(Float)
    longitude = Column(Float)
    type_logement = Column(String)
    prix_par_nuit = Column(Float)
    capacite = Column(Integer)
    nb_chambres = Column(Integer)
    nb_salles_bain = Column(Integer)
    superficie = Column(Float)
    description = Column(Text)
    equipements = Column(JSON)
    disponible = Column(Boolean, default=True)
    photo_facade_url = Column(String)
    photos_supplementaires = Column(JSON)
    note_moyenne = Column(Float, default=0)
    nb_avis = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
