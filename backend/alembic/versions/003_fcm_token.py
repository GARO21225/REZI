"""Add FCM token to users

Revision ID: 003_fcm_token
Revises: 002_messages
Create Date: 2026-03-21
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.exc import OperationalError

revision = '003_fcm_token'
down_revision = '002_messages'
branch_labels = None
depends_on = None

def upgrade():
    try:
        op.add_column('users', sa.Column('fcm_token', sa.String(), nullable=True))
    except Exception:
        pass
    try:
        op.add_column('users', sa.Column('fcm_platform', sa.String(), nullable=True, server_default='web'))
    except Exception:
        pass

def downgrade():
    try:
        op.drop_column('users', 'fcm_token')
    except Exception:
        pass
    try:
        op.drop_column('users', 'fcm_platform')
    except Exception:
        pass
