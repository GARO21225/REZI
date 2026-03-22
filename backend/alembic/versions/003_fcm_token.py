"""Add FCM token to users

Revision ID: 003_fcm_token
Revises: 002_messages
Create Date: 2026-03-21
"""
from alembic import op
import sqlalchemy as sa

revision = '003_fcm_token'
down_revision = '002_messages'
branch_labels = None
depends_on = None

def upgrade():
    op.add_column('users', sa.Column('fcm_token', sa.String(), nullable=True))
    op.add_column('users', sa.Column('fcm_platform', sa.String(), nullable=True, server_default='web'))

def downgrade():
    op.drop_column('users', 'fcm_token')
    op.drop_column('users', 'fcm_platform')
