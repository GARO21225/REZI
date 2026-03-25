from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import Optional, List
import os, shutil, uuid, json

from database import get_db
from models.residence import Residence
from models.user import User
from routers.auth import get_current_active_user, save_file

router = APIRouter()

def res_to_dict(r, user_lat=None, user_lng=None):
    dist = None
    if user_lat and user_lng:
        from math import radians, sin, cos, sqrt, atan2
        R = 6371
        lat1,lon1,lat2,lon2 = map(radians,[user_lat,user_lng,r.latitude,r.longitude])
        a = sin((lat2-lat1)/2)**2 + cos(lat1)*cos(lat2)*sin((lon2-lon1)/2)**2
        dist = round(R * 2 * atan2(sqrt(a), sqrt(1-a)), 1)
    return {
        "id": r.id, "titre": r.titre, "description": r.description,
        "adresse": r.adresse, "ville": r.ville, "pays": r.pays,
        "latitude": r.latitude, "longitude": r.longitude,
        "type_logement": r.type_logement, "prix_par_nuit": r.prix_par_nuit,
        "capacite": r.capacite, "nb_chambres": r.nb_chambres,
        "nb_salles_bain": r.nb_salles_bain, "superficie": r.superficie,
        "equipements": r.equipements or [],
        "disponible": r.disponible,
        "photo_facade_url": r.photo_facade_url,
        "photos_supplementaires": r.photos_supplementaires or [],
        "proprietaire_id": r.proprietaire_id,
        "note_moyenne": r.note_moyenne or 0.0,
        "nb_avis": r.nb_avis or 0,
        "distance_km": dist,
        "created_at": str(r.created_at) if r.created_at else None,
    }

@router.get("/")
def list_residences(
    ville: Optional[str] = None,
    type_logement: Optional[str] = None,
    disponible: Optional[bool] = None,
    prix_min: Optional[float] = None,
    prix_max: Optional[float] = None,
    lat: Optional[float] = None,
    lng: Optional[float] = None,
    rayon_km: Optional[float] = None,
    search: Optional[str] = None,
    limit: int = Query(100, le=500),
    offset: int = 0,
    db: Session = Depends(get_db)
):
    q = db.query(Residence)
    if ville: q = q.filter(Residence.ville.ilike(f"%{ville}%"))
    if type_logement: q = q.filter(Residence.type_logement == type_logement)
    if disponible is not None: q = q.filter(Residence.disponible == disponible)
    if prix_min: q = q.filter(Residence.prix_par_nuit >= prix_min)
    if prix_max: q = q.filter(Residence.prix_par_nuit <= prix_max)
    if search:
        s = f"%{search}%"
        q = q.filter(
            Residence.titre.ilike(s) |
            Residence.adresse.ilike(s) |
            Residence.ville.ilike(s) |
            Residence.description.ilike(s)
        )
    residences = q.offset(offset).limit(limit).all()
    return [res_to_dict(r, lat, lng) for r in residences]

@router.get("/{residence_id}")
def get_residence(residence_id: int, lat: Optional[float] = None, lng: Optional[float] = None, db: Session = Depends(get_db)):
    r = db.query(Residence).filter(Residence.id == residence_id).first()
    if not r: raise HTTPException(404, "Résidence introuvable")
    return res_to_dict(r, lat, lng)

@router.post("/")
async def create_residence(
    titre: str = Form(...),
    description: Optional[str] = Form(None),
    adresse: str = Form(...),
    ville: str = Form("Abidjan"),
    latitude: float = Form(...),
    longitude: float = Form(...),
    type_logement: str = Form(...),
    prix_par_nuit: float = Form(...),
    capacite: int = Form(1),
    nb_chambres: int = Form(1),
    nb_salles_bain: int = Form(1),
    superficie: Optional[float] = Form(None),
    equipements: Optional[str] = Form("[]"),
    photo_facade: UploadFile = File(...),
    photos_supplementaires: Optional[List[UploadFile]] = File(None),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    # Passer automatiquement en propriétaire si usager
    if current_user.role == "usager":
        current_user.role = "proprietaire"
        db.commit()
    elif current_user.role not in ["proprietaire","admin"]:
        raise HTTPException(403, "Accès refusé")
    if prix_par_nuit <= 0: raise HTTPException(400, "Le prix doit être positif")

    facade_url = save_file(photo_facade, "photos")
    photos_urls = []
    if photos_supplementaires:
        for p in photos_supplementaires:
            if p.filename:
                photos_urls.append(save_file(p, "photos"))

    try:
        equip_list = json.loads(equipements or "[]")
    except:
        equip_list = []

    r = Residence(
        titre=titre, description=description, adresse=adresse,
        ville=ville, pays="Côte d'Ivoire",
        latitude=latitude, longitude=longitude,
        type_logement=type_logement, prix_par_nuit=prix_par_nuit,
        capacite=capacite, nb_chambres=nb_chambres,
        nb_salles_bain=nb_salles_bain, superficie=superficie,
        equipements=equip_list, disponible=True,
        photo_facade_url=facade_url,
        photos_supplementaires=photos_urls,
        proprietaire_id=current_user.id,
        note_moyenne=0.0, nb_avis=0
    )
    db.add(r); db.commit(); db.refresh(r)
    result = res_to_dict(r)
    result['user_role'] = current_user.role  # Retourner le nouveau rôle
    return result

@router.put("/{residence_id}")
async def update_residence(
    residence_id: int,
    titre: Optional[str] = Form(None),
    description: Optional[str] = Form(None),
    prix_par_nuit: Optional[float] = Form(None),
    disponible: Optional[bool] = Form(None),
    equipements: Optional[str] = Form(None),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    r = db.query(Residence).filter(Residence.id == residence_id).first()
    if not r: raise HTTPException(404, "Résidence introuvable")
    if r.proprietaire_id != current_user.id and current_user.role != "admin":
        raise HTTPException(403, "Non autorisé")
    if titre: r.titre = titre
    if description: r.description = description
    if prix_par_nuit: r.prix_par_nuit = prix_par_nuit
    if disponible is not None: r.disponible = disponible
    if equipements:
        try: r.equipements = json.loads(equipements)
        except: pass
    db.commit(); db.refresh(r)
    return res_to_dict(r)

@router.delete("/{residence_id}")
def delete_residence(residence_id: int, current_user: User = Depends(get_current_active_user), db: Session = Depends(get_db)):
    r = db.query(Residence).filter(Residence.id == residence_id).first()
    if not r: raise HTTPException(404, "Résidence introuvable")
    if r.proprietaire_id != current_user.id and current_user.role != "admin":
        raise HTTPException(403, "Non autorisé")
    db.delete(r); db.commit()
    return {"message": "Résidence supprimée"}

@router.get("/{residence_id}/dates-reservees")
def dates_reservees(residence_id: int, db: Session = Depends(get_db)):
    """Retourne les périodes réservées pour une résidence (pour bloquer le calendrier)"""
    from models.reservation import Reservation
    from datetime import datetime
    resas = db.query(Reservation).filter(
        Reservation.residence_id == residence_id,
        Reservation.statut.in_(["confirmee","en_attente"]),
        Reservation.date_fin >= datetime.now()
    ).all()
    return [{"debut": r.date_debut.strftime("%Y-%m-%d"), "fin": r.date_fin.strftime("%Y-%m-%d")} for r in resas]
