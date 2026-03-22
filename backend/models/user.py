from sqlalchemy import Column, Integer, String, Boolean, DateTime
from sqlalchemy.sql import func
from database import Base

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, nullable=False, index=True)
    nom = Column(String, nullable=False)
    prenom = Column(String, nullable=False)
    telephone = Column(String)
    hashed_password = Column(String, nullable=False)
    role = Column(String, default="usager")   # usager | proprietaire | admin
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    carte_identite_url = Column(String)
    justificatif_domicile_url = Column(String)
    documents_verified = Column(Boolean, default=False)
    fcm_token = Column(String)
    fcm_platform = Column(String, default="web")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())


class Favori(Base):
    __tablename__ = "favoris"
    id           = Column(Integer, primary_key=True)
    user_id      = Column(Integer, ForeignKey("users.id"), nullable=False)
    residence_id = Column(Integer, ForeignKey("residences.id"), nullable=False)
    created_at   = Column(DateTime(timezone=True), server_default=func.now())
