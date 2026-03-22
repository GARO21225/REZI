from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Enum, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base
import enum

class OperateurMobile(str, enum.Enum):
    orange_money = "orange_money"
    mtn_momo = "mtn_momo"
    wave = "wave"
    moov_money = "moov_money"

class StatutPaiement(str, enum.Enum):
    en_attente = "en_attente"
    initie = "initie"
    confirme = "confirme"
    echoue = "echoue"
    rembourse = "rembourse"

class Paiement(Base):
    __tablename__ = "paiements"

    id = Column(Integer, primary_key=True, index=True)
    reservation_id = Column(Integer, ForeignKey("reservations.id"), nullable=False)
    usager_id = Column(Integer, ForeignKey("users.id"), nullable=False)

    # Montants
    montant = Column(Float, nullable=False)
    montant_frais = Column(Float, default=0.0)
    montant_total = Column(Float, nullable=False)
    devise = Column(String, default="XOF")  # Franc CFA

    # Mobile Money
    operateur = Column(Enum(OperateurMobile), nullable=False)
    numero_telephone = Column(String, nullable=False)
    reference_externe = Column(String, unique=True)  # ID retourné par l'opérateur
    reference_interne = Column(String, unique=True)  # Notre référence

    statut = Column(Enum(StatutPaiement), default=StatutPaiement.en_attente)
    message_statut = Column(Text)

    # Callbacks & webhooks
    callback_url = Column(String)
    callback_recu = Column(String)  # JSON brut du callback

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    confirmed_at = Column(DateTime(timezone=True))

    reservation = relationship("Reservation", backref="paiements")
    usager = relationship("User", backref="paiements")
