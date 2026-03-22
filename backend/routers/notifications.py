"""
REZI — Router notifications push FCM
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional

from database import get_db
from models.user import User
from routers.auth import get_current_active_user
from services.firebase_notifications import envoyer_notification, envoyer_notification_multiple, NOTIF_TYPES

router = APIRouter()


class FCMTokenUpdate(BaseModel):
    fcm_token: str
    platform: Optional[str] = "web"   # web | android | ios


class NotifTest(BaseModel):
    type_notif: str = "nouveau_message"
    donnees: Optional[dict] = {}


# ── Enregistrer le token FCM de l'appareil ──
@router.post("/token")
async def enregistrer_token(
    data: FCMTokenUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Sauvegarder le token FCM après permission accordée"""
    current_user.fcm_token = data.fcm_token
    current_user.fcm_platform = data.platform
    db.commit()
    return {"message": "Token FCM enregistré", "platform": data.platform}


# ── Supprimer le token (déconnexion / désabonnement) ──
@router.delete("/token")
async def supprimer_token(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    current_user.fcm_token = None
    db.commit()
    return {"message": "Désabonné des notifications push"}


# ── Tester une notification ──
@router.post("/test")
async def tester_notification(
    data: NotifTest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    if not current_user.fcm_token:
        raise HTTPException(400, "Aucun token FCM enregistré pour cet utilisateur")
    if data.type_notif not in NOTIF_TYPES:
        raise HTTPException(400, f"Type inconnu. Disponibles: {list(NOTIF_TYPES.keys())}")
    result = await envoyer_notification(current_user.fcm_token, data.type_notif, data.donnees)
    return result


# ── Notification administrative (admin uniquement) ──
@router.post("/broadcast")
async def broadcast_notification(
    data: NotifTest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    if current_user.role != "admin":
        raise HTTPException(403, "Accès réservé aux admins")
    tokens = [u.fcm_token for u in db.query(User).filter(User.fcm_token.isnot(None)).all()]
    if not tokens:
        raise HTTPException(400, "Aucun token FCM disponible")
    result = await envoyer_notification_multiple(tokens, data.type_notif, data.donnees)
    return {**result, "total_tokens": len(tokens)}
