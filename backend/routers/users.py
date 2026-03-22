from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from models.user import User
from database import get_db
from routers.auth import get_current_user, save_file

router = APIRouter()

@router.get("/")
def list_users(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin requis")
    return db.query(User).all()

@router.post("/upload-document")
async def upload_document(
    document_type: str,  # "carte_identite" ou "justificatif_domicile"
    fichier: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    url = save_file(fichier, "documents")
    if document_type == "carte_identite":
        current_user.carte_identite_url = url
    elif document_type == "justificatif_domicile":
        current_user.justificatif_domicile_url = url
    else:
        raise HTTPException(status_code=400, detail="Type de document invalide")
    
    db.commit()
    return {"url": url, "message": "Document uploadé avec succès"}


# ══ FAVORIS ══
from fastapi import APIRouter as _AR
from models.residence import Residence

@router.get("/favoris")
def get_favoris(current_user: User = Depends(get_current_active_user), db: Session = Depends(get_db)):
    favs = db.query(Favori).filter(Favori.user_id == current_user.id).all()
    return favs

@router.post("/favoris/{residence_id}")
def add_favori(residence_id: int, current_user: User = Depends(get_current_active_user), db: Session = Depends(get_db)):
    existing = db.query(Favori).filter(Favori.user_id == current_user.id, Favori.residence_id == residence_id).first()
    if existing: return {"message": "Déjà en favoris"}
    fav = Favori(user_id=current_user.id, residence_id=residence_id)
    db.add(fav); db.commit()
    return {"message": "Ajouté aux favoris"}

@router.delete("/favoris/{residence_id}")
def remove_favori(residence_id: int, current_user: User = Depends(get_current_active_user), db: Session = Depends(get_db)):
    db.query(Favori).filter(Favori.user_id == current_user.id, Favori.residence_id == residence_id).delete()
    db.commit()
    return {"message": "Retiré des favoris"}
