# ══ SERVICE EMAIL — Resend ══
import os, httpx, random, string
from datetime import datetime, timedelta

RESEND_API_KEY = os.getenv("RESEND_API_KEY", "re_Dm5mNHcq_Lb7U6z5d6LQuyFnKpRNPCtVM")
RESEND_FROM    = os.getenv("RESEND_FROM", "REZI <noreply@rezi.ink>")
APP_URL        = os.getenv("APP_URL", "https://rezi.ink")

def generer_otp(n=6):
    return ''.join(random.choices(string.digits, k=n))

def generer_token_reset():
    import secrets
    return secrets.token_urlsafe(32)

async def envoyer_email(to: str, subject: str, html: str) -> bool:
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                "https://api.resend.com/emails",
                headers={
                    "Authorization": f"Bearer {RESEND_API_KEY}",
                    "Content-Type": "application/json"
                },
                json={"from": RESEND_FROM, "to": [to], "subject": subject, "html": html},
                timeout=10
            )
            return resp.status_code == 200
    except Exception as e:
        print(f"Email error: {e}")
        return False

async def envoyer_otp(email: str, prenom: str, code: str) -> bool:
    html = f"""
    <div style="font-family:'Helvetica Neue',Arial,sans-serif;max-width:520px;margin:0 auto;background:#0b0f1a;color:#fff;border-radius:16px;overflow:hidden">
      <div style="background:linear-gradient(135deg,#f5a623,#e8855a);padding:32px;text-align:center">
        <div style="font-size:36px;font-weight:900;letter-spacing:6px;font-family:Georgia,serif">REZI</div>
        <div style="font-size:13px;opacity:.85;margin-top:4px;letter-spacing:2px;text-transform:uppercase">Application de réservation — Côte d'Ivoire</div>
      </div>
      <div style="padding:32px">
        <h2 style="margin:0 0 12px;font-size:22px">Bonjour {prenom} 👋</h2>
        <p style="color:#8892a4;font-size:14px;line-height:1.6;margin-bottom:24px">
          Voici votre code de vérification pour activer votre compte REZI.
        </p>
        <div style="background:#1c2640;border:2px solid #f5a623;border-radius:14px;padding:24px;text-align:center;margin-bottom:24px">
          <div style="font-size:42px;font-weight:900;letter-spacing:12px;color:#f5a623;font-family:monospace">{code}</div>
          <div style="font-size:12px;color:#8892a4;margin-top:8px">⏱️ Valable 10 minutes</div>
        </div>
        <p style="color:#8892a4;font-size:12px;line-height:1.6">
          Si vous n'avez pas créé de compte REZI, ignorez cet email.
        </p>
      </div>
      <div style="background:#131929;padding:16px;text-align:center;font-size:11px;color:#4a5568">
        REZI CI · contact@rezi.ci · <a href="{APP_URL}" style="color:#f5a623">garo21225.github.io/REZI</a>
      </div>
    </div>
    """
    return await envoyer_email(email, "🔐 Votre code de vérification REZI", html)

async def envoyer_bienvenue(email: str, prenom: str) -> bool:
    html = f"""
    <div style="font-family:'Helvetica Neue',Arial,sans-serif;max-width:520px;margin:0 auto;background:#0b0f1a;color:#fff;border-radius:16px;overflow:hidden">
      <div style="background:linear-gradient(135deg,#f5a623,#e8855a);padding:32px;text-align:center">
        <div style="font-size:36px;font-weight:900;letter-spacing:6px;font-family:Georgia,serif">REZI</div>
      </div>
      <div style="padding:32px">
        <h2 style="margin:0 0 12px;font-size:24px">Bienvenue sur REZI, {prenom} ! 🎉</h2>
        <p style="color:#8892a4;font-size:14px;line-height:1.6;margin-bottom:24px">
          Votre compte est activé. Vous pouvez maintenant réserver les meilleures résidences de Côte d'Ivoire.
        </p>
        <div style="display:flex;gap:12px;flex-direction:column;margin-bottom:24px">
          <div style="background:#1c2640;border-radius:10px;padding:14px;display:flex;align-items:center;gap:12px">
            <span style="font-size:24px">🗺️</span>
            <div><div style="font-weight:700;font-size:13px">Explorez la carte</div><div style="color:#8892a4;font-size:12px">Trouvez des résidences près de vous</div></div>
          </div>
          <div style="background:#1c2640;border-radius:10px;padding:14px;display:flex;align-items:center;gap:12px">
            <span style="font-size:24px">📅</span>
            <div><div style="font-weight:700;font-size:13px">Réservez en ligne</div><div style="color:#8892a4;font-size:12px">Paiement Mobile Money sécurisé</div></div>
          </div>
          <div style="background:#1c2640;border-radius:10px;padding:14px;display:flex;align-items:center;gap:12px">
            <span style="font-size:24px">🧭</span>
            <div><div style="font-weight:700;font-size:13px">Navigation GPS</div><div style="color:#8892a4;font-size:12px">Itinéraire vers votre résidence</div></div>
          </div>
        </div>
        <a href="{APP_URL}" style="display:block;background:linear-gradient(135deg,#f5a623,#e8855a);color:#fff;text-align:center;padding:14px;border-radius:10px;text-decoration:none;font-weight:700;font-size:15px">
          Accéder à REZI →
        </a>
      </div>
      <div style="background:#131929;padding:16px;text-align:center;font-size:11px;color:#4a5568">
        REZI CI · contact@rezi.ci
      </div>
    </div>
    """
    return await envoyer_email(email, "🏠 Bienvenue sur REZI — Côte d'Ivoire", html)

async def envoyer_reset_password(email: str, prenom: str, nouveau_mdp: str) -> bool:
    from urllib.parse import quote
    email_encoded = quote(email)
    html = f"""
    <div style="font-family:'Helvetica Neue',Arial,sans-serif;max-width:520px;margin:0 auto;background:#0b0f1a;color:#fff;border-radius:16px;overflow:hidden">
      <div style="background:linear-gradient(135deg,#f5a623,#e8855a);padding:32px;text-align:center">
        <div style="font-size:36px;font-weight:900;letter-spacing:6px;font-family:Georgia,serif">REZI</div>
      </div>
      <div style="padding:32px">
        <h2 style="margin:0 0 12px;font-size:22px">Bonjour {prenom} 🔑</h2>
        <p style="color:#8892a4;font-size:14px;line-height:1.6;margin-bottom:24px">
          Voici votre nouveau mot de passe temporaire. Connectez-vous et changez-le dès que possible.
        </p>
        <div style="background:#1c2640;border:2px solid #f5a623;border-radius:14px;padding:24px;text-align:center;margin-bottom:24px">
          <div style="font-size:11px;color:#8892a4;margin-bottom:8px;text-transform:uppercase;letter-spacing:1px">Mot de passe temporaire</div>
          <div style="font-size:28px;font-weight:900;color:#f5a623;font-family:monospace;letter-spacing:4px">{nouveau_mdp}</div>
        </div>
        <a href="{APP_URL}?reset=1&email={{email_encoded}}" style="display:block;background:linear-gradient(135deg,#f5a623,#e8855a);color:#fff;text-align:center;padding:14px;border-radius:10px;text-decoration:none;font-weight:700;font-size:15px">
          Créer mon nouveau mot de passe →
        </a>
        <p style="color:#8892a4;font-size:12px;line-height:1.6;margin-top:20px">
          Si vous n'avez pas demandé cette réinitialisation, contactez-nous immédiatement.
        </p>
      </div>
      <div style="background:#131929;padding:16px;text-align:center;font-size:11px;color:#4a5568">
        REZI CI · contact@rezi.ci
      </div>
    </div>
    """
    return await envoyer_email(email, "🔑 Votre nouveau mot de passe REZI", html)
