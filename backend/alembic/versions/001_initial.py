"""Initial REZI tables

Revision ID: 001_initial
Revises: 
Create Date: 2026-03-21
"""
from alembic import op
import sqlalchemy as sa
from geoalchemy2 import Geometry

revision = '001_initial'
down_revision = None
branch_labels = None
depends_on = None

def upgrade():
    # Extension PostGIS

    # ── Users ──
    op.create_table('users',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('email', sa.String(), nullable=False, unique=True),
        sa.Column('nom', sa.String(), nullable=False),
        sa.Column('prenom', sa.String(), nullable=False),
        sa.Column('telephone', sa.String()),
        sa.Column('hashed_password', sa.String(), nullable=False),
        sa.Column('role', sa.String(), default='usager'),
        sa.Column('is_active', sa.Boolean(), default=True),
        sa.Column('is_verified', sa.Boolean(), default=False),
        sa.Column('carte_identite_url', sa.String()),
        sa.Column('justificatif_domicile_url', sa.String()),
        sa.Column('documents_verified', sa.Boolean(), default=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), onupdate=sa.func.now()),
    )
    op.create_index('ix_users_email', 'users', ['email'])

    # ── Residences ──
    op.create_table('residences',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('titre', sa.String(), nullable=False),
        sa.Column('description', sa.Text()),
        sa.Column('adresse', sa.String(), nullable=False),
        sa.Column('ville', sa.String(), nullable=False),
        sa.Column('pays', sa.String(), default="Côte d'Ivoire"),
        sa.Column('code_postal', sa.String()),
        sa.Column('latitude', sa.Float(), nullable=False),
        sa.Column('longitude', sa.Float(), nullable=False),
        sa.Column('geom', Geometry(geometry_type='POINT', srid=4326), nullable=True),
        sa.Column('type_logement', sa.String(), nullable=False),
        sa.Column('prix_par_nuit', sa.Float(), nullable=False),
        sa.Column('capacite', sa.Integer(), default=1),
        sa.Column('nb_chambres', sa.Integer(), default=1),
        sa.Column('nb_salles_bain', sa.Integer(), default=1),
        sa.Column('superficie', sa.Float()),
        sa.Column('equipements', sa.JSON(), default=[]),
        sa.Column('disponible', sa.Boolean(), default=True),
        sa.Column('photo_facade_url', sa.String(), nullable=False),
        sa.Column('photos_supplementaires', sa.JSON(), default=[]),
        sa.Column('proprietaire_id', sa.Integer(), sa.ForeignKey('users.id'), nullable=False),
        sa.Column('note_moyenne', sa.Float(), default=0.0),
        sa.Column('nb_avis', sa.Integer(), default=0),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), onupdate=sa.func.now()),
    )

    # ── Reservations ──
    op.create_table('reservations',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('usager_id', sa.Integer(), sa.ForeignKey('users.id'), nullable=False),
        sa.Column('residence_id', sa.Integer(), sa.ForeignKey('residences.id'), nullable=False),
        sa.Column('date_debut', sa.DateTime(), nullable=False),
        sa.Column('date_fin', sa.DateTime(), nullable=False),
        sa.Column('nb_personnes', sa.Integer(), default=1),
        sa.Column('prix_total', sa.Float(), nullable=False),
        sa.Column('statut', sa.String(), default='en_attente'),
        sa.Column('message', sa.Text()),
        sa.Column('note', sa.Integer()),
        sa.Column('commentaire', sa.Text()),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), onupdate=sa.func.now()),
    )

    # ── Paiements ──
    op.create_table('paiements',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('reservation_id', sa.Integer(), sa.ForeignKey('reservations.id'), nullable=False),
        sa.Column('usager_id', sa.Integer(), sa.ForeignKey('users.id'), nullable=False),
        sa.Column('montant', sa.Float(), nullable=False),
        sa.Column('montant_frais', sa.Float(), default=0.0),
        sa.Column('montant_total', sa.Float(), nullable=False),
        sa.Column('devise', sa.String(), default='XOF'),
        sa.Column('operateur', sa.String(), nullable=False),
        sa.Column('numero_telephone', sa.String(), nullable=False),
        sa.Column('reference_externe', sa.String()),
        sa.Column('reference_interne', sa.String(), unique=True),
        sa.Column('statut', sa.String(), default='en_attente'),
        sa.Column('message_statut', sa.Text()),
        sa.Column('callback_url', sa.String()),
        sa.Column('callback_recu', sa.Text()),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), onupdate=sa.func.now()),
        sa.Column('confirmed_at', sa.DateTime(timezone=True)),
    )

def downgrade():
    op.drop_table('paiements')
    op.drop_table('reservations')
    op.drop_table('residences')
    op.drop_table('users')
