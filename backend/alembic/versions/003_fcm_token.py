"""Add FCM token to users

Revision ID: 003_fcm_token
Revises: 002_messages
Create Date: 2026-03-21
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import text

revision = '003_fcm_token'
down_revision = '002_messages'
branch_labels = None
depends_on = None

def column_exists(table, column):
    conn = op.get_bind()
    result = conn.execute(text(
        f"SELECT column_name FROM information_schema.columns "
        f"WHERE table_name='{table}' AND column_name='{column}'"
    ))
    return result.fetchone() is not None

def upgrade():
    if not column_exists('users', 'fcm_token'):
        op.add_column('users', sa.Column('fcm_token', sa.String(), nullable=True))
    if not column_exists('users', 'fcm_platform'):
        op.add_column('users', sa.Column('fcm_platform', sa.String(), nullable=True, server_default='web'))

def downgrade():
    if column_exists('users', 'fcm_token'):
        op.drop_column('users', 'fcm_token')
    if column_exists('users', 'fcm_platform'):
        op.drop_column('users', 'fcm_platform')
