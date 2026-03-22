"""Add avis table

Revision ID: 005_avis
Revises: 004_favoris
Create Date: 2026-03-21
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = '005_avis'
down_revision = '004_favoris'

def upgrade():
    op.create_table('avis',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('residence_id', sa.Integer(), sa.ForeignKey('residences.id'), nullable=False),
        sa.Column('user_id', sa.Integer(), sa.ForeignKey('users.id'), nullable=False),
        sa.Column('reservation_id', sa.Integer(), sa.ForeignKey('reservations.id'), nullable=True),
        sa.Column('note', sa.Float(), nullable=False),
        sa.Column('texte', sa.Text()),
        sa.Column('sous_notes', sa.JSON()),
        sa.Column('reponse', sa.JSON()),
        sa.Column('verifie', sa.Boolean(), default=False),
        sa.Column('publie', sa.Boolean(), default=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index('ix_avis_residence', 'avis', ['residence_id'])
    op.create_index('ix_avis_user', 'avis', ['user_id'])

def downgrade():
    op.drop_table('avis')
