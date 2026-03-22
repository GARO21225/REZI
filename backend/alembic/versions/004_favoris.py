"""Add favoris table

Revision ID: 004_favoris
Revises: 003_fcm_token
Create Date: 2026-03-21
"""
from alembic import op
import sqlalchemy as sa

revision = '004_favoris'
down_revision = '003_fcm_token'

def upgrade():
    op.create_table('favoris',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('user_id', sa.Integer(), sa.ForeignKey('users.id'), nullable=False),
        sa.Column('residence_id', sa.Integer(), sa.ForeignKey('residences.id'), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index('ix_favoris_user', 'favoris', ['user_id'])

def downgrade():
    op.drop_table('favoris')
