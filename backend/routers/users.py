from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db
from models.user import User, Favori
from routers.auth import get_current_user

router = APIRouter()

@router.get("/me")
def get_me(current_user: User = Depends(get_current_user)):
    return current_user

@router.get("/favoris")
def get_favoris(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return db.query(Favori).filter(Favori.user_id == current_user.id).all()

@router.post("/favoris/{residence_id}")
def add_favori(residence_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    existing = db.query(Favori).filter(Favori.user_id == current_user.id, Favori.residence_id == residence_id).first()
    if existing:
        return {"message": "Déjà en favoris"}
    db.add(Favori(user_id=current_user.id, residence_id=residence_id))
    db.commit()
    return {"message": "Ajouté"}

@router.delete("/favoris/{residence_id}")
def remove_favori(residence_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    db.query(Favori).filter(Favori.user_id == current_user.id, Favori.residence_id == residence_id).delete()
    db.commit()
    return {"message": "Retiré"}
