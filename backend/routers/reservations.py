from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import and_
from typing import Optional
from datetime import datetime
from pydantic import BaseModel

from database import get_db
from models.reservation import Reservation
from models.residence import Residence
from models.user import User
from routers.auth import get_current_active_user

router = APIRouter()

class ReservationCreate(BaseModel):
    residence_id: int
    date_debut: datetime
    date_fin: datetime
    nb_personnes: int = 1
    message: Optional[str] = None

def resa_to_dict(r):
    return {
        "id": r.id, "usager_id": r.usager_id, "residence_id": r.residence_id,
        "date_debut": str(r.date_debut), "date_fin": str(r.date_fin),
        "nb_personnes": r.nb_personnes, "prix_total": r.prix_total,
        "statut": r.statut, "message": r.message,
        "note": r.note, "commentaire": r.commentaire,
        "created_at": str(r.created_at) if r.created_at else None,
    }

@router.post("/")
def create_reservation(
    data: ReservationCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    res = db.query(Residence).filter(Residence.id == data.residence_id).first()
    if not res: raise HTTPException(404, "Résidence introuvable")
    if not res.disponible: raise HTTPException(400, "Cette résidence n'est pas disponible")
    if data.date_debut >= data.date_fin: raise HTTPException(400, "Dates invalides")
    if data.nb_personnes > res.capacite:
        raise HTTPException(400, f"Capacité maximale : {res.capacite} personnes")

    # Vérifier conflits de dates
    conflit = db.query(Reservation).filter(
        and_(
            Reservation.residence_id == data.residence_id,
            Reservation.statut.in_(["confirmee","en_attente"]),
            Reservation.date_debut < data.date_fin,
            Reservation.date_fin > data.date_debut,
        )
    ).first()
    if conflit: raise HTTPException(400, "Ces dates sont déjà réservées")

    nb_nuits = (data.date_fin - data.date_debut).days
    prix_total = nb_nuits * res.prix_par_nuit

    r = Reservation(
        usager_id=current_user.id,
        residence_id=data.residence_id,
        date_debut=data.date_debut,
        date_fin=data.date_fin,
        nb_personnes=data.nb_personnes,
        prix_total=prix_total,
        statut="en_attente",
        message=data.message,
    )
    db.add(r); db.commit(); db.refresh(r)
    return resa_to_dict(r)

@router.get("/mes-reservations")
def mes_reservations(current_user: User = Depends(get_current_active_user), db: Session = Depends(get_db)):
    resas = db.query(Reservation).filter(Reservation.usager_id == current_user.id)\
        .order_by(Reservation.created_at.desc()).all()
    return [resa_to_dict(r) for r in resas]

@router.get("/mes-demandes")
def mes_demandes(current_user: User = Depends(get_current_active_user), db: Session = Depends(get_db)):
    """Réservations reçues sur les résidences du propriétaire"""
    mes_residences = db.query(Residence).filter(Residence.proprietaire_id == current_user.id).all()
    ids = [r.id for r in mes_residences]
    resas = db.query(Reservation).filter(Reservation.residence_id.in_(ids))\
        .order_by(Reservation.created_at.desc()).all()
    return [resa_to_dict(r) for r in resas]

@router.put("/{resa_id}/statut")
def update_statut(
    resa_id: int, statut: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    r = db.query(Reservation).filter(Reservation.id == resa_id).first()
    if not r: raise HTTPException(404, "Réservation introuvable")
    res = db.query(Residence).filter(Residence.id == r.residence_id).first()
    if res.proprietaire_id != current_user.id and current_user.role != "admin":
        raise HTTPException(403, "Non autorisé")
    if statut not in ["confirmee","annulee","refusee","terminee"]:
        raise HTTPException(400, "Statut invalide")
    r.statut = statut
    db.commit(); db.refresh(r)
    return resa_to_dict(r)

@router.post("/{resa_id}/avis")
def laisser_avis(
    resa_id: int, note: int, commentaire: Optional[str] = None,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    r = db.query(Reservation).filter(
        Reservation.id == resa_id,
        Reservation.usager_id == current_user.id
    ).first()
    if not r: raise HTTPException(404, "Réservation introuvable")
    if r.statut != "terminee": raise HTTPException(400, "Vous ne pouvez évaluer qu'un séjour terminé")
    if not 1 <= note <= 5: raise HTTPException(400, "La note doit être entre 1 et 5")

    r.note = note; r.commentaire = commentaire
    # Recalculer la note moyenne de la résidence
    res = db.query(Residence).filter(Residence.id == r.residence_id).first()
    if res:
        all_notes = [rv.note for rv in db.query(Reservation).filter(
            Reservation.residence_id == res.id,
            Reservation.note.isnot(None)
        ).all()]
        res.nb_avis = len(all_notes)
        res.note_moyenne = round(sum(all_notes) / len(all_notes), 1) if all_notes else 0.0
    db.commit()
    return {"message": "Avis publié", "note": note}


# ══ AVIS VÉRIFIÉS ══
from pydantic import BaseModel as _BM
from typing import Optional as _Opt

class AvisCreate(_BM):
    note: float
    texte: str
    sous_notes: _Opt[dict] = {}

@router.get("/residences/{residence_id}/avis")
def get_avis(residence_id: int, db: Session = Depends(get_db)):
    from models.reservation import Avis
    avis = db.query(Avis).filter(Avis.residence_id == residence_id, Avis.publie == True).order_by(Avis.created_at.desc()).all()
    return [{"id":a.id,"auteur":f"{a.user.prenom} {a.user.nom[0]}." if a.user else "Anonyme",
             "initiales":(a.user.prenom[0]+a.user.nom[0]).upper() if a.user else "??",
             "date":a.created_at.strftime("%d %B %Y"),"note":a.note,"texte":a.texte,
             "verifie":a.verifie,"sous_notes":a.sous_notes or {},"reponse":a.reponse} for a in avis]

@router.post("/residences/{residence_id}/avis")
def create_avis(residence_id: int, data: AvisCreate,
    current_user = Depends(get_current_active_user), db: Session = Depends(get_db)):
    from models.reservation import Avis, Reservation
    # Vérifier qu'il a séjourné
    res = db.query(Reservation).filter(
        Reservation.residence_id == residence_id,
        Reservation.usager_id == current_user.id,
        Reservation.statut == 'terminee'
    ).first()
    from models.reservation import Avis
    avis = Avis(residence_id=residence_id, user_id=current_user.id,
        note=min(5,max(1,data.note)), texte=data.texte,
        sous_notes=data.sous_notes, verifie=bool(res), publie=True)
    db.add(avis); db.commit()
    # Recalculer note moyenne
    tous = db.query(Avis).filter(Avis.residence_id==residence_id, Avis.publie==True).all()
    from models.residence import Residence
    r = db.query(Residence).filter(Residence.id==residence_id).first()
    if r and tous:
        r.note_moyenne = round(sum(a.note for a in tous)/len(tous),2)
        r.nb_avis = len(tous); db.commit()
    return {"message":"Avis publié","verifie":bool(res)}
