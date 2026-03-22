from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect, Query
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_
from typing import Optional, Dict, List
from datetime import datetime
from pydantic import BaseModel
import json

from database import get_db
from models.message import Message, Conversation
from models.user import User
from routers.auth import get_current_active_user

router = APIRouter()

# ══ GESTIONNAIRE DE CONNEXIONS WEBSOCKET ══
class ConnectionManager:
    def __init__(self):
        # user_id -> list of active websocket connections
        self.active: Dict[int, List[WebSocket]] = {}

    async def connect(self, user_id: int, ws: WebSocket):
        await ws.accept()
        if user_id not in self.active:
            self.active[user_id] = []
        self.active[user_id].append(ws)

    def disconnect(self, user_id: int, ws: WebSocket):
        if user_id in self.active:
            self.active[user_id] = [w for w in self.active[user_id] if w != ws]
            if not self.active[user_id]:
                del self.active[user_id]

    async def send_to_user(self, user_id: int, data: dict):
        """Envoyer un message à toutes les connexions d'un utilisateur"""
        if user_id in self.active:
            dead = []
            for ws in self.active[user_id]:
                try:
                    await ws.send_json(data)
                except Exception:
                    dead.append(ws)
            for ws in dead:
                self.disconnect(user_id, ws)

    def is_online(self, user_id: int) -> bool:
        return user_id in self.active and len(self.active[user_id]) > 0

    def online_users(self) -> List[int]:
        return list(self.active.keys())

manager = ConnectionManager()


# ══ WEBSOCKET ENDPOINT ══
@router.websocket("/ws/{user_id}")
async def websocket_endpoint(
    websocket: WebSocket,
    user_id: int,
    token: str = Query(...),
    db: Session = Depends(get_db)
):
    # Vérifier le token
    from jose import jwt, JWTError
    from routers.auth import SECRET_KEY, ALGORITHM
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        token_user_id = int(payload.get("sub"))
        if token_user_id != user_id:
            await websocket.close(code=4001)
            return
    except (JWTError, Exception):
        await websocket.close(code=4001)
        return

    await manager.connect(user_id, websocket)

    # Notifier les contacts que l'utilisateur est en ligne
    await _notify_online_status(user_id, True, db)

    try:
        while True:
            data = await websocket.receive_json()
            msg_type = data.get("type")

            if msg_type == "message":
                await handle_new_message(user_id, data, db)

            elif msg_type == "typing":
                # Transmettre "en train d'écrire" à l'autre utilisateur
                conv_id = data.get("conversation_id")
                if conv_id:
                    conv = db.query(Conversation).filter(Conversation.id == conv_id).first()
                    if conv:
                        other_id = conv.user2_id if conv.user1_id == user_id else conv.user1_id
                        await manager.send_to_user(other_id, {
                            "type": "typing",
                            "user_id": user_id,
                            "conversation_id": conv_id,
                            "is_typing": data.get("is_typing", False)
                        })

            elif msg_type == "read":
                # Marquer les messages comme lus
                conv_id = data.get("conversation_id")
                if conv_id:
                    db.query(Message).filter(
                        Message.conversation_id == conv_id,
                        Message.sender_id != user_id,
                        Message.lu == False
                    ).update({"lu": True})
                    db.commit()

            elif msg_type == "ping":
                await websocket.send_json({"type": "pong"})

    except WebSocketDisconnect:
        manager.disconnect(user_id, websocket)
        await _notify_online_status(user_id, False, db)


async def handle_new_message(sender_id: int, data: dict, db: Session):
    """Traiter un nouveau message envoyé"""
    conv_id = data.get("conversation_id")
    contenu = data.get("contenu", "").strip()
    if not conv_id or not contenu:
        return

    conv = db.query(Conversation).filter(Conversation.id == conv_id).first()
    if not conv:
        return

    # Vérifier que l'expéditeur fait partie de la conversation
    if conv.user1_id != sender_id and conv.user2_id != sender_id:
        return

    # Sauvegarder le message
    msg = Message(
        conversation_id=conv_id,
        sender_id=sender_id,
        contenu=contenu,
        lu=False,
        created_at=datetime.utcnow()
    )
    db.add(msg)

    # Mettre à jour dernière activité conversation
    conv.dernier_message = contenu
    conv.derniere_activite = datetime.utcnow()
    db.commit()
    db.refresh(msg)

    # Déterminer le destinataire
    receiver_id = conv.user2_id if conv.user1_id == sender_id else conv.user1_id

    # Préparer le payload
    sender = db.query(User).filter(User.id == sender_id).first()
    payload = {
        "type": "message",
        "id": msg.id,
        "conversation_id": conv_id,
        "sender_id": sender_id,
        "sender_nom": f"{sender.prenom} {sender.nom}" if sender else "—",
        "contenu": contenu,
        "created_at": msg.created_at.isoformat(),
        "lu": False,
    }

    # Envoyer au destinataire (s'il est connecté)
    await manager.send_to_user(receiver_id, payload)
    # Confirmer à l'expéditeur
    await manager.send_to_user(sender_id, {**payload, "confirmed": True})


async def _notify_online_status(user_id: int, is_online: bool, db: Session):
    """Notifier les contacts du statut en ligne"""
    convs = db.query(Conversation).filter(
        or_(Conversation.user1_id == user_id, Conversation.user2_id == user_id)
    ).all()
    for conv in convs:
        other_id = conv.user2_id if conv.user1_id == user_id else conv.user1_id
        await manager.send_to_user(other_id, {
            "type": "presence",
            "user_id": user_id,
            "online": is_online
        })


# ══ REST API ══

@router.get("/conversations")
def get_conversations(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    convs = db.query(Conversation).filter(
        or_(Conversation.user1_id == current_user.id, Conversation.user2_id == current_user.id)
    ).order_by(Conversation.derniere_activite.desc()).all()

    result = []
    for conv in convs:
        other_id = conv.user2_id if conv.user1_id == current_user.id else conv.user1_id
        other = db.query(User).filter(User.id == other_id).first()
        unread = db.query(Message).filter(
            Message.conversation_id == conv.id,
            Message.sender_id != current_user.id,
            Message.lu == False
        ).count()
        result.append({
            "id": conv.id,
            "other_user": {
                "id": other.id,
                "nom": other.nom, "prenom": other.prenom,
                "initiales": f"{other.prenom[0]}{other.nom[0]}",
                "online": manager.is_online(other.id)
            },
            "residence_titre": conv.residence_titre,
            "dernier_message": conv.dernier_message,
            "derniere_activite": conv.derniere_activite.isoformat() if conv.derniere_activite else None,
            "non_lus": unread,
        })
    return result


@router.get("/conversations/{conv_id}/messages")
def get_messages(
    conv_id: int,
    limit: int = 50,
    before_id: Optional[int] = None,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    conv = db.query(Conversation).filter(Conversation.id == conv_id).first()
    if not conv: raise HTTPException(404, "Conversation introuvable")
    if conv.user1_id != current_user.id and conv.user2_id != current_user.id:
        raise HTTPException(403, "Non autorisé")

    q = db.query(Message).filter(Message.conversation_id == conv_id)
    if before_id: q = q.filter(Message.id < before_id)
    msgs = q.order_by(Message.created_at.desc()).limit(limit).all()

    # Marquer comme lus
    db.query(Message).filter(
        Message.conversation_id == conv_id,
        Message.sender_id != current_user.id,
        Message.lu == False
    ).update({"lu": True})
    db.commit()

    return [
        {
            "id": m.id,
            "sender_id": m.sender_id,
            "contenu": m.contenu,
            "lu": m.lu,
            "created_at": m.created_at.isoformat(),
        }
        for m in reversed(msgs)
    ]


@router.post("/conversations")
def start_conversation(
    other_user_id: int,
    residence_id: Optional[int] = None,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Démarrer ou récupérer une conversation avec un autre utilisateur"""
    # Vérifier si une conversation existe déjà
    existing = db.query(Conversation).filter(
        or_(
            and_(Conversation.user1_id == current_user.id, Conversation.user2_id == other_user_id),
            and_(Conversation.user1_id == other_user_id, Conversation.user2_id == current_user.id)
        )
    ).first()

    if existing:
        return {"id": existing.id, "existing": True}

    # Récupérer le titre de la résidence si fourni
    residence_titre = None
    if residence_id:
        from models.residence import Residence
        res = db.query(Residence).filter(Residence.id == residence_id).first()
        if res: residence_titre = res.titre

    conv = Conversation(
        user1_id=current_user.id,
        user2_id=other_user_id,
        residence_titre=residence_titre,
        derniere_activite=datetime.utcnow()
    )
    db.add(conv); db.commit(); db.refresh(conv)
    return {"id": conv.id, "existing": False}


@router.get("/online-users")
def get_online_users(current_user: User = Depends(get_current_active_user)):
    return {"online": manager.online_users()}
