from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from sqlalchemy import Column, Integer, String, DateTime
from typing import Optional
from datetime import datetime, timedelta
from jose import JWTError, jwt
import bcrypt as _bcrypt
import os, shutil, uuid, random, string

from database import get_db, Base
from models.user import User

router = APIRouter()

SECRET_KEY = os.getenv("SECRET_KEY", "rezi-super-secret-key-changez-en-prod")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")

UPLOAD_DIR = "uploads"
os.makedirs(f"{UPLOAD_DIR}/documents", exist_ok=True)
os.makedirs(f"{UPLOAD_DIR}/photos", exist_ok=True)

# ── Stockage OTP en mémoire (simple) ──
OTP_STORE = {}  # {email: {code, prenom, nom, tel, password, expires}}
RESET_STORE = {}  # {email: expires}

def hash_password(p: str) -> str:
    return _bcrypt.hashpw(p[:72].encode(), _bcrypt.gensalt()).decode()

def verify_password(plain: str, hashed: str) -> bool:
    try:
        return _bcrypt.checkpw(plain[:72].encode(), hashed.encode())
    except Exception:
        return False

def save_file(upload, folder):
    ext = upload.filename.split(".")[-1].lower()
    if ext not in ["jpg","jpeg","png","pdf","webp"]:
        raise HTTPException(400, f"Format non autorisé : {ext}")
    filename = f"{uuid.uuid4()}.{ext}"
    path = f"{UPLOAD_DIR}/{folder}/{filename}"
    with open(path, "wb") as f:
        shutil.copyfileobj(upload.file, f)
    return f"/{path}"

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

# ── ÉTAPE 1 : Demander OTP ──
@router.post("/register/request-otp")
async def request_otp(
    email: str = Form(...), mot_de_passe: str = Form(...),
    nom: str = Form(...), prenom: str = Form(...),
    telephone: Optional[str] = Form(None),
    role: str = Form("usager"),
    db: Session = Depends(get_db)
):
    from services.email_service import generer_otp, envoyer_otp
    if db.query(User).filter(User.email == email.lower()).first():
        raise HTTPException(400, "Un compte existe déjà avec cet email")
    if len(mot_de_passe) < 6:
        raise HTTPException(400, "Mot de passe trop court (min 6 caractères)")
    code = generer_otp(6)
    OTP_STORE[email.lower()] = {
        "code": code, "prenom": prenom, "nom": nom,
        "telephone": telephone, "password": mot_de_passe,
        "role": role if role in ["usager","proprietaire"] else "usager",
        "expires": datetime.utcnow() + timedelta(minutes=10)
    }
    sent = await envoyer_otp(email, prenom, code)
    return {"message": "Code envoyé", "email_sent": sent}

# ── ÉTAPE 2 : Vérifier OTP et créer compte ──
@router.post("/register/verify-otp")
async def verify_otp(
    email: str = Form(...),
    code: str = Form(...),
    db: Session = Depends(get_db)
):
    from services.email_service import envoyer_bienvenue
    data = OTP_STORE.get(email.lower())
    if not data:
        raise HTTPException(400, "Aucune demande d'inscription trouvée pour cet email")
    if datetime.utcnow() > data["expires"]:
        del OTP_STORE[email.lower()]
        raise HTTPException(400, "Code expiré. Recommencez l'inscription")
    if data["code"] != code.strip():
        raise HTTPException(400, "Code incorrect")

    # Créer le compte
    user = User(
        email=email.lower().strip(), hashed_password=hash_password(data["password"]),
        nom=data["nom"].strip(), prenom=data["prenom"].strip(),
        telephone=data["telephone"], role=data["role"],
        is_active=True, documents_verified=False,
    )
    db.add(user); db.commit(); db.refresh(user)
    del OTP_STORE[email.lower()]

    # Envoyer email de bienvenue
    await envoyer_bienvenue(email, data["prenom"])

    token = create_token({"sub": str(user.id), "role": user.role})
    return {"access_token": token, "token_type": "bearer", "user": user_to_dict(user)}

# ── Ancien register (fallback si OTP désactivé) ──
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
    if len(mot_de_passe) < 6: raise HTTPException(400, "Mot de passe trop court")
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

@router.post("/forgot-password")
async def forgot_password(email: str = Form(...), db: Session = Depends(get_db)):
    from services.email_service import envoyer_reset_password, generer_otp
    user = db.query(User).filter(User.email == email.lower()).first()
    # Toujours retourner succès pour la sécurité
    if not user:
        return {"message": "Si cet email existe, vous recevrez un nouveau mot de passe"}
    # Générer un nouveau mot de passe temporaire
    nouveau_mdp = generer_otp(8)
    user.hashed_password = hash_password(nouveau_mdp)
    db.commit()
    await envoyer_reset_password(email, user.prenom, nouveau_mdp)
    return {"message": "Nouveau mot de passe envoyé par email"}

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
