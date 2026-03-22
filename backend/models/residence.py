from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, Text, JSON, ForeignKey
from sqlalchemy.sql import func
from database import Base

class Residence(Base):
    __tablename__ = "residences"
    id = Column(Integer, primary_key=True, index=True)
    titre = Column(String, nullable=False)
    description = Column(Text)
    adresse = Column(String, nullable=False)
    ville = Column(String, nullable=False)
    pays = Column(String, default="Côte d'Ivoire")
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    type_logement = Column(String, nullable=False)
    prix_par_nuit = Column(Float, nullable=False)
    capacite = Column(Integer, default=1)
    nb_chambres = Column(Integer, default=1)
    nb_salles_bain = Column(Integer, default=1)
    superficie = Column(Float)
    equipements = Column(JSON, default=list)
    disponible = Column(Boolean, default=True)
    photo_facade_url = Column(String, nullable=False)
    photos_supplementaires = Column(JSON, default=list)
    proprietaire_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    note_moyenne = Column(Float, default=0.0)
    nb_avis = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
