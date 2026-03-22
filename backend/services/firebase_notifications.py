"""
REZI — Service de notifications push Firebase Cloud Messaging
Installation : pip install firebase-admin
Config      : Télécharger serviceAccountKey.json depuis Firebase Console
              → Paramètres du projet → Comptes de service → Générer une clé privée
"""
import os
import json
import logging
from typing import Optional, List
from datetime import datetime

logger = logging.getLogger(__name__)

# ── Initialisation Firebase Admin SDK ──
try:
    import firebase_admin
    from firebase_admin import credentials, messaging

    # Chercher le fichier de credentials
    cred_path = os.getenv('FIREBASE_CREDENTIALS_PATH', 'serviceAccountKey.json')
    if os.path.exists(cred_path):
        cred = credentials.Certificate(cred_path)
        if not firebase_admin._apps:
            firebase_admin.initialize_app(cred)
        FIREBASE_AVAILABLE = True
        logger.info("✅ Firebase Admin SDK initialisé")
    else:
        FIREBASE_AVAILABLE = False
        logger.warning(f"⚠️ Firebase credentials non trouvés: {cred_path}")
except ImportError:
    FIREBASE_AVAILABLE = False
    logger.warning("⚠️ firebase-admin non installé. Notifications push désactivées.")


# ══ TYPES DE NOTIFICATIONS ══
NOTIF_TYPES = {
    'reservation_confirmee': {
        'title':  '✅ Réservation confirmée !',
        'body':   'Votre séjour à {titre} est confirmé.',
        'icon':   '/icons/icon-192.png',
        'url':    '/dashboard/historique',
    },
    'paiement_recu': {
        'title':  '💳 Paiement reçu',
        'body':   'Vous avez reçu {montant} FCFA pour {titre}.',
        'icon':   '/icons/icon-192.png',
        'url':    '/dashboard/revenus',
    },
    'nouveau_message': {
        'title':  '💬 Nouveau message',
        'body':   '{expediteur} vous a envoyé un message.',
        'icon':   '/icons/icon-192.png',
        'url':    '/messages',
    },
    'nouvel_avis': {
        'title':  '⭐ Nouvel avis',
        'body':   '{utilisateur} a laissé une note de {note}/5 sur {titre}.',
        'icon':   '/icons/icon-192.png',
        'url':    '/dashboard/residences',
    },
    'reservation_annulee': {
        'title':  '❌ Réservation annulée',
        'body':   'La réservation pour {titre} a été annulée.',
        'icon':   '/icons/icon-192.png',
        'url':    '/dashboard/historique',
    },
    'residence_publiee': {
        'title':  '🏠 Résidence publiée',
        'body':   'Votre résidence "{titre}" est maintenant en ligne.',
        'icon':   '/icons/icon-192.png',
        'url':    '/dashboard/residences',
    },
    'promo': {
        'title':  '🎉 Offre REZI',
        'body':   '{message}',
        'icon':   '/icons/icon-192.png',
        'url':    '/',
    },
}


async def envoyer_notification(
    fcm_token: str,
    type_notif: str,
    donnees: dict = None,
    silent: bool = False
) -> dict:
    """
    Envoyer une notification push à un utilisateur.
    
    Args:
        fcm_token: Token FCM de l'appareil de l'utilisateur
        type_notif: Type de notification (voir NOTIF_TYPES)
        donnees: Variables à injecter dans le template
        silent: Si True, notification silencieuse (data-only)
    
    Returns:
        dict avec status et message_id
    """
    if not FIREBASE_AVAILABLE:
        logger.warning(f"Firebase non disponible, simulation: {type_notif}")
        return {"status": "simulated", "type": type_notif}

    template = NOTIF_TYPES.get(type_notif, {
        'title': '🏠 REZI', 'body': str(donnees), 'url': '/', 'icon': '/icons/icon-192.png'
    })
    donnees = donnees or {}

    try:
        title = template['title'].format(**donnees)
        body  = template['body'].format(**donnees)
    except KeyError:
        title = template['title']
        body  = template['body']

    try:
        message = messaging.Message(
            token=fcm_token,
            notification=None if silent else messaging.Notification(
                title=title,
                body=body,
                image=template.get('icon'),
            ),
            data={
                'type':  type_notif,
                'url':   template.get('url', '/'),
                'title': title,
                'body':  body,
                'timestamp': str(int(datetime.utcnow().timestamp())),
                **(donnees or {}),
            },
            android=messaging.AndroidConfig(
                priority='high',
                notification=messaging.AndroidNotification(
                    sound='default',
                    click_action='FLUTTER_NOTIFICATION_CLICK',
                ) if not silent else None,
            ),
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(
                        sound='default',
                        badge=1,
                        content_available=True,
                    )
                )
            ),
            webpush=messaging.WebpushConfig(
                notification=messaging.WebpushNotification(
                    title=title,
                    body=body,
                    icon=template.get('icon', '/icons/icon-192.png'),
                    badge='/icons/icon-72.png',
                    tag=type_notif,
                    vibrate=[200, 100, 200],
                    actions=[
                        messaging.WebpushNotificationAction('voir', '👁️ Voir'),
                        messaging.WebpushNotificationAction('ignorer', '✕ Ignorer'),
                    ]
                ) if not silent else None,
                fcm_options=messaging.WebpushFCMOptions(link=template.get('url', '/'))
            )
        )
        response = messaging.send(message)
        logger.info(f"✅ Notification envoyée: {response}")
        return {"status": "sent", "message_id": response}

    except messaging.UnregisteredError:
        logger.warning(f"Token FCM invalide/expiré: {fcm_token[:20]}...")
        return {"status": "unregistered"}
    except Exception as e:
        logger.error(f"Erreur envoi notification: {e}")
        return {"status": "error", "error": str(e)}


async def envoyer_notification_multiple(
    tokens: List[str],
    type_notif: str,
    donnees: dict = None
) -> dict:
    """Envoyer une notification à plusieurs utilisateurs (multicast)"""
    if not FIREBASE_AVAILABLE or not tokens:
        return {"status": "simulated", "count": len(tokens)}

    template = NOTIF_TYPES.get(type_notif, {'title':'REZI','body':'','url':'/','icon':''})
    donnees = donnees or {}
    try:
        title = template['title'].format(**donnees)
        body  = template['body'].format(**donnees)
    except KeyError:
        title, body = template['title'], template['body']

    try:
        message = messaging.MulticastMessage(
            tokens=tokens[:500],  # FCM limite à 500
            notification=messaging.Notification(title=title, body=body),
            data={'type': type_notif, 'url': template.get('url', '/'), **{k:str(v) for k,v in donnees.items()}},
            webpush=messaging.WebpushConfig(
                notification=messaging.WebpushNotification(
                    title=title, body=body,
                    icon=template.get('icon', '/icons/icon-192.png'),
                    badge='/icons/icon-72.png',
                )
            )
        )
        response = messaging.send_each_for_multicast(message)
        logger.info(f"Multicast: {response.success_count}/{len(tokens)} succès")
        return {
            "status": "sent",
            "success": response.success_count,
            "failure": response.failure_count
        }
    except Exception as e:
        logger.error(f"Erreur multicast: {e}")
        return {"status": "error", "error": str(e)}
