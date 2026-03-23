from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from typing import Optional
from datetime import datetime, timedelta
from jose import JWTError, jwt
import bcrypt as _bcrypt
import os

from database import get_db
from models.user import User

router = APIRouter()

SECRET_KEY = os.getenv("SECRET_KEY", "rezi-super-secret-key-changez-en-prod")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")

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
    return current_use
