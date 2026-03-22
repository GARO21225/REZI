from fastapi import APIRouter, Depends, HTTPException, Request, BackgroundTasks
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
import json
import uuid

from database import get_db
from models.paiement import Paiement, StatutPaiement, OperateurMobile
from models.reservation import Reservation
from models.user import User
from routers.auth import get_current_user
from services.mobile_money import (
    initier_paiement_orange_money,
    initier_paiement_mtn_momo,
    initier_paiement_wave,
    initier_paiement_moov,
    verifier_statut_paiement,
    calculer_frais,
    generer_reference
)

router = APIRouter()

class InitierPaiementRequest(BaseModel):
    reservation_id: int
    operateur: OperateurMobile
    numero_telephone: str

class VerifierPaiementRequest(BaseModel):
    paiement_id: int

@router.post("/initier")
async def initier_paiement(
    data: InitierPaiementRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Initie un paiement Mobile Money pour une réservation"""
    
    # Vérifier la réservation
    reservation = db.query(Reservation).filter(
        Reservation.id == data.reservation_id,
        Reservation.usager_id == current_user.id
    ).first()
    if not reservation:
        raise HTTPException(status_code=404, detail="Réservation introuvable")
    
    if reservation.statut not in [StatutReservation.en_attente, StatutReservation.confirmee]:
        raise HTTPException(status_code=400, detail="Cette réservation ne peut plus être payée")
    
    # Vérifier si déjà payée
    paiement_existant = db.query(Paiement).filter(
        Paiement.reservation_id == data.reservation_id,
        Paiement.statut == StatutPaiement.confirme
    ).first()
    if paiement_existant:
        raise HTTPException(status_code=400, detail="Cette réservation est déjà payée")
    
    # Calculer montants
    montant = reservation.prix_total
    frais = calculer_frais(montant, data.operateur.value)
    montant_total = montant + frais
    reference = generer_reference()
    description = f"PCR ou Loger - Réservation #{reservation.id}"
    
    # Appeler le service Mobile Money approprié
    initiateurs = {
        OperateurMobile.orange_money: initier_paiement_orange_money,
        OperateurMobile.mtn_momo: initier_paiement_mtn_momo,
        OperateurMobile.wave: initier_paiement_wave,
        OperateurMobile.moov_money: initier_paiement_moov,
    }
    
    resultat = await initiateurs[data.operateur](
        numero=data.numero_telephone,
        montant=montant_total,
        reference=reference,
        description=description
    )
    
    if not resultat.get("succes"):
        raise HTTPException(status_code=502, detail=resultat.get("message", "Échec d'initialisation du paiement"))
    
    # Enregistrer en base
    paiement = Paiement(
        reservation_id=reservation.id,
        usager_id=current_user.id,
        montant=montant,
        montant_frais=frais,
        montant_total=montant_total,
        operateur=data.operateur,
        numero_telephone=data.numero_telephone,
        reference_externe=resultat.get("reference_externe"),
        reference_interne=reference,
        statut=StatutPaiement.initie,
        message_statut=resultat.get("message", "Paiement initié")
    )
    db.add(paiement)
    db.commit()
    db.refresh(paiement)
    
    return {
        "paiement_id": paiement.id,
        "reference": reference,
        "montant": montant,
        "frais": frais,
        "montant_total": montant_total,
        "devise": "FCFA",
        "operateur": data.operateur,
        "statut": "initie",
        "message": resultat.get("message"),
        "payment_url": resultat.get("payment_url"),
        "wave_launch_url": resultat.get("wave_launch_url"),
        "instruction": _get_instruction(data.operateur, data.numero_telephone, montant_total)
    }

def _get_instruction(operateur: OperateurMobile, numero: str, montant: float) -> str:
    montant_str = f"{int(montant):,}".replace(",", " ")
    instructions = {
        OperateurMobile.orange_money: f"Composez #144# sur votre téléphone Orange ({numero}) et validez le paiement de {montant_str} FCFA",
        OperateurMobile.mtn_momo: f"Vous allez recevoir une notification MoMo sur le {numero}. Entrez votre PIN pour valider {montant_str} FCFA",
        OperateurMobile.wave: f"Ouvrez l'application Wave sur {numero} et confirmez le paiement de {montant_str} FCFA",
        OperateurMobile.moov_money: f"Composez *555# sur votre téléphone Moov ({numero}) et validez {montant_str} FCFA",
    }
    return instructions.get(operateur, "Suivez les instructions sur votre téléphone")

@router.post("/verifier/{paiement_id}")
async def verifier_paiement(
    paiement_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Vérifie le statut d'un paiement en cours"""
    paiement = db.query(Paiement).filter(
        Paiement.id == paiement_id,
        Paiement.usager_id == current_user.id
    ).first()
    if not paiement:
        raise HTTPException(status_code=404, detail="Paiement introuvable")
    
    # Interroger l'opérateur
    resultat = await verifier_statut_paiement(
        paiement.operateur.value,
        paiement.reference_externe
    )
    
    nouveau_statut = resultat.get("statut", "en_attente")
    
    if nouveau_statut == "confirme" and paiement.statut != StatutPaiement.confirme:
        paiement.statut = StatutPaiement.confirme
        paiement.confirmed_at = datetime.utcnow()
        # Confirmer la réservation automatiquement
        reservation = paiement.reservation
        reservation.statut = StatutReservation.confirmee
        db.commit()
    elif nouveau_statut == "echoue":
        paiement.statut = StatutPaiement.echoue
        db.commit()
    
    db.refresh(paiement)
    return {
        "paiement_id": paiement.id,
        "statut": paiement.statut,
        "reference": paiement.reference_interne,
        "montant_total": paiement.montant_total,
        "operateur": paiement.operateur,
        "confirmed_at": paiement.confirmed_at,
        "reservation_statut": paiement.reservation.statut
    }

@router.post("/webhook/orange")
async def webhook_orange(request: Request, db: Session = Depends(get_db)):
    """Webhook Orange Money — callback de confirmation"""
    body = await request.json()
    reference = body.get("order_id") or body.get("txnid")
    
    if reference:
        paiement = db.query(Paiement).filter(Paiement.reference_interne == reference).first()
        if paiement:
            paiement.callback_recu = json.dumps(body)
            statut = body.get("status", "").lower()
            if statut in ["success", "successful"]:
                paiement.statut = StatutPaiement.confirme
                paiement.confirmed_at = datetime.utcnow()
                paiement.reservation.statut = StatutReservation.confirmee
            elif statut in ["failed", "cancelled"]:
                paiement.statut = StatutPaiement.echoue
            db.commit()
    return {"status": "ok"}

@router.post("/webhook/mtn")
async def webhook_mtn(request: Request, db: Session = Depends(get_db)):
    """Webhook MTN MoMo"""
    body = await request.json()
    ref_externe = body.get("referenceId") or body.get("externalId")
    
    if ref_externe:
        paiement = db.query(Paiement).filter(
            (Paiement.reference_externe == ref_externe) |
            (Paiement.reference_interne == ref_externe)
        ).first()
        if paiement:
            paiement.callback_recu = json.dumps(body)
            if body.get("status") == "SUCCESSFUL":
                paiement.statut = StatutPaiement.confirme
                paiement.confirmed_at = datetime.utcnow()
                paiement.reservation.statut = StatutReservation.confirmee
            db.commit()
    return {"status": "ok"}

@router.post("/webhook/wave")
async def webhook_wave(request: Request, db: Session = Depends(get_db)):
    """Webhook Wave"""
    body = await request.json()
    client_ref = body.get("client_reference")
    
    if client_ref:
        paiement = db.query(Paiement).filter(Paiement.reference_interne == client_ref).first()
        if paiement:
            paiement.callback_recu = json.dumps(body)
            if body.get("payment_status") == "succeeded":
                paiement.statut = StatutPaiement.confirme
                paiement.confirmed_at = datetime.utcnow()
                paiement.reservation.statut = StatutReservation.confirmee
            db.commit()
    return {"status": "ok"}

@router.get("/mes-paiements")
def mes_paiements(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    paiements = db.query(Paiement).filter(Paiement.usager_id == current_user.id).order_by(Paiement.created_at.desc()).all()
    return [{
        "id": p.id,
        "reference": p.reference_interne,
        "montant_total": p.montant_total,
        "operateur": p.operateur,
        "statut": p.statut,
        "created_at": p.created_at,
        "confirmed_at": p.confirmed_at,
        "reservation_id": p.reservation_id
    } for p in paiements]

@router.post("/rembourser/{paiement_id}")
async def rembourser(
    paiement_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Admin : rembourser un paiement"""
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin requis")
    
    paiement = db.query(Paiement).filter(Paiement.id == paiement_id).first()
    if not paiement or paiement.statut != StatutPaiement.confirme:
        raise HTTPException(status_code=400, detail="Paiement non remboursable")
    
    # En production : appeler l'API de remboursement de l'opérateur
    paiement.statut = StatutPaiement.rembourse
    paiement.reservation.statut = StatutReservation.annulee
    db.commit()
    
    return {"message": f"Remboursement de {paiement.montant_total} FCFA initié"}
