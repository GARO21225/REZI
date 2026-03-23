from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from typing import Optional
from datetime import datetime, timedelta
from jose import JWTError, jwt
import bcrypt as _bcrypt
import os, uuid

from database import get_db
from models.user import User

router = APIRouter()

SECRET_KEY = os.getenv("SECRET_KEY", "rezi-super-secret-key-changez-en-prod")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7  # 7 jours

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")

UPLOAD_DIR = "uploads"
os.makedirs(f"{UPLOAD_DIR}/documents", exist_ok=True)
os.makedirs(f"{UPLOAD_DIR}/photos", exist_ok=True)

def hash_password(p: str) -> str:
    return _bcrypt.hashpw(p[:72].encode(), _bcrypt.gensalt()).decode()

def verify_password(plain: str, hashed: str) -> bool:
    try:
        return _bcrypt.checkpw(plain[:72].encode(), hashed.encode())
    except Exception:
        return False

def create_token(data):
    payload = data.copy()
    payload["exp"] = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)

def user_to_dict(user):
    return {
        "id": user.id, "email": user.email, "prenom": user.prenom,
        "nom": user.nom, "telephone": user.telephone or "",
        "role": user.role, "is_active": user.is_active,
        "documents_verified": user.documents_verified,
        "created_at": str(user.created_at) if user.created_at else None,
    }

async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    exc = HTTPException(status_code=401, detail="Token invalide ou expiré", headers={"WWW-Authenticate": "Bearer"})
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload.get("sub")
        if not user_id: raise exc
    except JWTError:
        raise exc
    user = db.query(User).filter(User.id == int(user_id)).first()
    if not user or not user.is_active: raise exc
    return user

async def get_current_active_user(current_user=Depends(get_current_user)):
    if not current_user.is_active: raise HTTPException(400, "Compte désactivé")
    return current_user

async def get_admin_user(current_user=Depends(get_current_user)):
    if current_user.role != "admin": raise HTTPException(403, "Accès admin requis")
    return current_user

# ── Routes ──
@router.post("/register")
async def register(
    email: str = Form(...), mot_de_passe: str = Form(...),
    nom: str = Form(...), prenom: str = Form(...),
    telephone: Optional[str] = Form(None),
    role: str = Form("usager"),
    db: Session = Depends(get_db)
):
    if db.query(User).filter(User.email == email.lower()).first():
        raise HTTPException(400, "Un compte existe déjà avec cet email")
    if role not in ["usager","proprietaire"]: role = "usager"
    if len(mot_de_passe) < 6: raise HTTPException(400, "Mot de passe trop court (min 6 caractères)")
    user = User(
        email=email.lower().strip(), hashed_password=hash_password(mot_de_passe),
        nom=nom.strip(), prenom=prenom.strip(), telephone=telephone, role=role,
        is_active=True, documents_verified=False,
    )
    db.add(user); db.commit(); db.refresh(user)
    token = create_token({"sub": str(user.id), "role": user.role})
    return {"access_token": token, "token_type": "bearer", "user": user_to_dict(user)}

@router.post("/login")
async def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == form_data.username.lower()).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(401, "Email ou mot de passe incorrect", headers={"WWW-Authenticate": "Bearer"})
    if not user.is_active: raise HTTPException(403, "Compte désactivé")
    token = create_token({"sub": str(user.id), "role": user.role})
    return {"access_token": token, "token_type": "bearer", "user": user_to_dict(user)}

@router.get("/me")
async def me(current_user=Depends(get_current_active_user)):
    return user_to_dict(current_user)

@router.put("/me")
async def update_me(
    nom: Optional[str] = Form(None), prenom: Optional[str] = Form(None),
    telephone: Optional[str] = Form(None),
    current_user=Depends(get_current_active_user), db: Session = Depends(get_db)
):
    if nom: current_user.nom = nom.strip()
    if prenom: current_user.prenom = prenom.strip()
    if telephone: current_user.telephone = telephone
    db.commit(); db.refresh(current_user)
    return user_to_dict(current_user)

@router.post("/change-password")
async def change_password(
    ancien_mot_de_passe: str = Form(...), nouveau_mot_de_passe: str = Form(...),
    current_user=Depends(get_current_active_user), db: Session = Depends(get_db)
):
    if not verify_password(ancien_mot_de_passe, current_user.hashed_password):
        raise HTTPException(400, "Ancien mot de passe incorrect")
    if len(nouveau_mot_de_passe) < 6: raise HTTPException(400, "Mot de passe trop court")
    current_user.hashed_password = hash_password(nouveau_mot_de_passe)
    db.commit()
    return {"message": "Mot de passe modifié avec succès"}
