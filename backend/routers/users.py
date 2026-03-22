from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text

from database import get_db
from models.user import User, Favori
from routers.auth import get_current_user

router = APIRouter()

@router.get("/me")
def get_me(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return current_user

@router.get("/favoris")
def get_favoris(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    favs = db.query(Favori).filter(Favori.user_id == current_user.id).all()
    return favs

@router.post("/favoris/{residence_id}")
def add_favori(residence_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    existing = db.query(Favori).filter(
        Favori.user_id == current_user.id,
        Favori.residence_id == residence_id
    ).first()
    if existing:
        return {"message": "Déjà en favoris"}
    fav = Favori(user_id=current_user.id, residence_id=residence_id)
    db.add(fav)
    db.commit()
    return {"message": "Ajouté aux favoris"}

@router.delete("/favoris/{residence_id}")
def remove_favori(residence_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    db.query(Favori).filter(
        Favori.user_id == current_user.id,
        Favori.residence_id == residence_id
    ).delete()
    db.commit()
    return {"message": "Retiré des favoris"}
