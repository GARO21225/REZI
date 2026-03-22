"""
Service d'intégration Mobile Money pour la Côte d'Ivoire
Supporte : Orange Money, MTN MoMo, Wave, Moov Money

En production, remplacer les appels simulés par les vraies API :
- Orange Money CI : https://developer.orange.com/apis/om-webpay-ci
- MTN MoMo : https://momodeveloper.mtn.com/
- Wave : https://docs.wave.com/
- Moov Money : API Flooz
"""

import httpx
import uuid
import os
import json
from datetime import datetime
from typing import Optional

ORANGE_MONEY_BASE = os.getenv("ORANGE_MONEY_URL", "https://api.orange.com/orange-money-webpay/ci/v1")
ORANGE_MONEY_TOKEN = os.getenv("ORANGE_MONEY_TOKEN", "")

MTN_MOMO_BASE = os.getenv("MTN_MOMO_URL", "https://sandbox.momodeveloper.mtn.com")
MTN_MOMO_KEY = os.getenv("MTN_MOMO_SUBSCRIPTION_KEY", "")
MTN_MOMO_USER = os.getenv("MTN_MOMO_USER_ID", "")
MTN_MOMO_API_KEY = os.getenv("MTN_MOMO_API_KEY", "")

WAVE_BASE = os.getenv("WAVE_URL", "https://api.wave.com/v1")
WAVE_API_KEY = os.getenv("WAVE_API_KEY", "")

CALLBACK_BASE = os.getenv("CALLBACK_BASE_URL", "http://localhost:8000")


def generer_reference() -> str:
    return f"PCR-{datetime.now().strftime('%Y%m%d')}-{str(uuid.uuid4())[:8].upper()}"


async def initier_paiement_orange_money(
    numero: str,
    montant: float,
    reference: str,
    description: str
) -> dict:
    """
    Initie un paiement Orange Money CI.
    Doc officielle: https://developer.orange.com/apis/om-webpay-ci
    """
    # SIMULATION (remplacer par vraie API en production)
    if os.getenv("ENV", "development") == "development":
        return {
            "succes": True,
            "reference_externe": f"OM-{uuid.uuid4().hex[:12].upper()}",
            "pay_token": f"token_{uuid.uuid4().hex}",
            "payment_url": f"https://api.orange.com/pay?token=demo_{reference}",
            "message": "Paiement Orange Money initié (mode simulation)",
            "operateur": "orange_money"
        }

    # PRODUCTION
    async with httpx.AsyncClient() as client:
        resp = await client.post(
            f"{ORANGE_MONEY_BASE}/webpayment",
            headers={
                "Authorization": f"Bearer {ORANGE_MONEY_TOKEN}",
                "Content-Type": "application/json"
            },
            json={
                "merchant_key": os.getenv("ORANGE_MERCHANT_KEY"),
                "currency": "OUV",
                "order_id": reference,
                "amount": int(montant),
                "return_url": f"{CALLBACK_BASE}/api/paiements/callback/orange",
                "cancel_url": f"{CALLBACK_BASE}/api/paiements/annule",
                "notif_url": f"{CALLBACK_BASE}/api/paiements/webhook/orange",
                "lang": "fr",
                "reference": reference
            },
            timeout=30
        )
        data = resp.json()
        if resp.status_code == 200:
            return {
                "succes": True,
                "reference_externe": data.get("pay_token"),
                "payment_url": data.get("payment_url"),
                "operateur": "orange_money"
            }
        return {"succes": False, "message": data.get("message", "Erreur Orange Money")}


async def initier_paiement_mtn_momo(
    numero: str,
    montant: float,
    reference: str,
    description: str
) -> dict:
    """
    Initie un paiement MTN MoMo (Collections API).
    Doc: https://momodeveloper.mtn.com/
    """
    if os.getenv("ENV", "development") == "development":
        return {
            "succes": True,
            "reference_externe": f"MTN-{uuid.uuid4().hex[:12].upper()}",
            "message": "Paiement MTN MoMo initié (mode simulation). Validez sur votre téléphone.",
            "operateur": "mtn_momo"
        }

    # PRODUCTION : MTN MoMo Collections API
    async with httpx.AsyncClient() as client:
        # Créer un UUID de transaction
        transaction_id = str(uuid.uuid4())
        
        resp = await client.post(
            f"{MTN_MOMO_BASE}/collection/v1_0/requesttopay",
            headers={
                "Authorization": f"Bearer {MTN_MOMO_API_KEY}",
                "X-Reference-Id": transaction_id,
                "X-Target-Environment": os.getenv("MTN_ENV", "sandbox"),
                "Ocp-Apim-Subscription-Key": MTN_MOMO_KEY,
                "Content-Type": "application/json"
            },
            json={
                "amount": str(int(montant)),
                "currency": "XOF",
                "externalId": reference,
                "payer": {"partyIdType": "MSISDN", "partyId": numero.replace("+", "").replace(" ", "")},
                "payerMessage": description,
                "payeeNote": f"PCR ou Loger - {reference}"
            },
            timeout=30
        )
        if resp.status_code == 202:
            return {"succes": True, "reference_externe": transaction_id, "operateur": "mtn_momo"}
        return {"succes": False, "message": "Erreur MTN MoMo"}


async def initier_paiement_wave(
    numero: str,
    montant: float,
    reference: str,
    description: str
) -> dict:
    """
    Initie un paiement Wave CI.
    Doc: https://docs.wave.com/
    """
    if os.getenv("ENV", "development") == "development":
        return {
            "succes": True,
            "reference_externe": f"WAVE-{uuid.uuid4().hex[:12].upper()}",
            "wave_launch_url": f"https://pay.wave.com/m/demo_{reference}",
            "message": "Lien de paiement Wave généré (mode simulation)",
            "operateur": "wave"
        }

    async with httpx.AsyncClient() as client:
        resp = await client.post(
            f"{WAVE_BASE}/checkout/sessions",
            headers={
                "Authorization": f"Bearer {WAVE_API_KEY}",
                "Content-Type": "application/json"
            },
            json={
                "amount": str(int(montant)),
                "currency": "XOF",
                "client_reference": reference,
                "success_url": f"{CALLBACK_BASE}/api/paiements/success",
                "error_url": f"{CALLBACK_BASE}/api/paiements/error",
            },
            timeout=30
        )
        data = resp.json()
        if resp.status_code == 200:
            return {
                "succes": True,
                "reference_externe": data.get("id"),
                "wave_launch_url": data.get("wave_launch_url"),
                "operateur": "wave"
            }
        return {"succes": False, "message": data.get("message", "Erreur Wave")}


async def initier_paiement_moov(
    numero: str,
    montant: float,
    reference: str,
    description: str
) -> dict:
    """Moov Money (Flooz) — simulation"""
    if os.getenv("ENV", "development") == "development":
        return {
            "succes": True,
            "reference_externe": f"MOOV-{uuid.uuid4().hex[:12].upper()}",
            "message": "Paiement Moov Money initié (mode simulation)",
            "operateur": "moov_money"
        }
    return {"succes": False, "message": "Moov Money non configuré"}


async def verifier_statut_paiement(operateur: str, reference_externe: str) -> dict:
    """Vérifie le statut d'un paiement auprès de l'opérateur"""
    if os.getenv("ENV", "development") == "development":
        # Simulation : après 10 secondes, on considère le paiement confirmé
        return {"statut": "confirme", "message": "Paiement confirmé (simulation)"}

    if operateur == "mtn_momo":
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"{MTN_MOMO_BASE}/collection/v1_0/requesttopay/{reference_externe}",
                headers={
                    "Authorization": f"Bearer {MTN_MOMO_API_KEY}",
                    "X-Target-Environment": os.getenv("MTN_ENV", "sandbox"),
                    "Ocp-Apim-Subscription-Key": MTN_MOMO_KEY,
                },
                timeout=15
            )
            data = resp.json()
            statut_map = {"SUCCESSFUL": "confirme", "FAILED": "echoue", "PENDING": "initie"}
            return {"statut": statut_map.get(data.get("status"), "en_attente")}

    return {"statut": "en_attente"}


# Calcul des frais selon l'opérateur
FRAIS_OPERATEURS = {
    "orange_money": 0.02,   # 2%
    "mtn_momo": 0.015,      # 1.5%
    "wave": 0.01,           # 1%
    "moov_money": 0.02,     # 2%
}

def calculer_frais(montant: float, operateur: str) -> float:
    taux = FRAIS_OPERATEURS.get(operateur, 0.02)
    return round(montant * taux)
