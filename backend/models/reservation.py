from sqlalchemy import Column, Integer, String, Float, DateTime, Text, ForeignKey
from sqlalchemy.sql import func
from database import Base

class Reservation(Base):
    __tablename__ = "reservations"
    id = Column(Integer, primary_key=True, index=True)
    usager_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    residence_id = Column(Integer, ForeignKey("residences.id"), nullable=False)
    date_debut = Column(DateTime, nullable=False)
    date_fin = Column(DateTime, nullable=False)
    nb_personnes = Column(Integer, default=1)
    prix_total = Column(Float, nullable=False)
    statut = Column(String, default="en_attente")
    message = Column(Text)
    note = Column(Integer)
    commentaire = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())


class Avis(Base):
    __tablename__ = "avis"
    id           = Column(Integer, primary_key=True)
    residence_id = Column(Integer, ForeignKey("residences.id"), nullable=False)
    user_id      = Column(Integer, ForeignKey("users.id"), nullable=False)
    reservation_id = Column(Integer, ForeignKey("reservations.id"), nullable=True)
    note         = Column(Float, nullable=False)
    texte        = Column(Text)
    sous_notes   = Column(JSON)
    reponse      = Column(JSON)     # {auteur, texte}
    verifie      = Column(Boolean, default=False)
    publie       = Column(Boolean, default=True)
    created_at   = Column(DateTime(timezone=True), server_default=func.now())
