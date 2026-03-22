from fastapi import FastAPI, Depends, HTTPException, status, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from typing import List, Optional
import uvicorn
import os

from database import get_db, engine, Base
from routers import auth, residences, users, reservations, paiements, messages, notifications
from models import user, residence, reservation, paiement, message

# Create tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="REZI API",
    description="API de réservation géolocalisée — Côte d'Ivoire",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*", "https://garo21225.github.io", "http://localhost:3000", "http://localhost:8080"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Static files for uploads
os.makedirs("uploads/photos", exist_ok=True)
os.makedirs("uploads/documents", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# Routers
app.include_router(auth.router, prefix="/api/auth", tags=["Authentification"])
app.include_router(users.router, prefix="/api/users", tags=["Utilisateurs"])
app.include_router(residences.router, prefix="/api/residences", tags=["Résidences"])
app.include_router(reservations.router, prefix="/api/reservations", tags=["Réservations"])
app.include_router(paiements.router, prefix="/api/paiements", tags=["Paiements Mobile Money"])
app.include_router(messages.router, prefix="/api/messages", tags=["Messagerie"])
app.include_router(notifications.router, prefix="/api/notifications", tags=["Notifications Push"])

@app.get("/")
def root():
    return {"message": "Bienvenue sur REZI API", "version": "1.0.0"}

@app.get("/health")
def health():
    return {"status": "ok"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
