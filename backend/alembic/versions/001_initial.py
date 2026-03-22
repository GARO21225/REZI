"""Initial REZI tables

Revision ID: 001_initial
Revises:
Create Date: 2026-03-21
"""
from alembic import op
import sqlalchemy as sa

revision = '001_initial'
down_revision = None
branch_labels = None
depends_on = None

def upgrade():
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
        sa.Column('fcm_token', sa.String()),
        sa.Column('fcm_platform', sa.String(), default='web'),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True)),
    )
    op.create_table('residences',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('proprietaire_id', sa.Integer(), sa.ForeignKey('users.id')),
        sa.Column('titre', sa.String(), nullable=False),
        sa.Column('adresse', sa.String()),
        sa.Column('ville', sa.String()),
        sa.Column('commune', sa.String()),
        sa.Column('quartier', sa.String()),
        sa.Column('latitude', sa.Float()),
        sa.Column('longitude', sa.Float()),
        sa.Column('type_logement', sa.String()),
        sa.Column('prix_par_nuit', sa.Float()),
        sa.Column('capacite', sa.Integer()),
        sa.Column('nb_chambres', sa.Integer()),
        sa.Column('nb_salles_bain', sa.Integer()),
        sa.Column('superficie', sa.Float()),
        sa.Column('description', sa.Text()),
        sa.Column('equipements', sa.JSON()),
        sa.Column('photo_facade_url', sa.String()),
        sa.Column('photos_supplementaires', sa.JSON()),
        sa.Column('disponible', sa.Boolean(), default=True),
        sa.Column('note_moyenne', sa.Float(), default=0),
        sa.Column('nb_avis', sa.Integer(), default=0),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_table('reservations',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('residence_id', sa.Integer(), sa.ForeignKey('residences.id')),
        sa.Column('usager_id', sa.Integer(), sa.ForeignKey('users.id')),
        sa.Column('date_debut', sa.Date()),
        sa.Column('date_fin', sa.Date()),
        sa.Column('nb_personnes', sa.Integer()),
        sa.Column('prix_total', sa.Float()),
        sa.Column('statut', sa.String(), default='en_attente'),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_table('paiements',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('reservation_id', sa.Integer(), sa.ForeignKey('reservations.id')),
        sa.Column('montant', sa.Float()),
        sa.Column('operateur', sa.String()),
        sa.Column('telephone', sa.String()),
        sa.Column('statut', sa.String(), default='en_attente'),
        sa.Column('reference', sa.String()),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

def downgrade():
    op.drop_table('paiements')
    op.drop_table('reservations')
    op.drop_table('residences')
    op.drop_table('users')
