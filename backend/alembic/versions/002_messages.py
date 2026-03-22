"""Add conversations and messages tables

Revision ID: 002_messages
Revises: 001_initial
Create Date: 2026-03-21
"""
from alembic import op
import sqlalchemy as sa

revision = '002_messages'
down_revision = '001_initial'
branch_labels = None
depends_on = None

def upgrade():
    op.create_table('conversations',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('user1_id', sa.Integer(), sa.ForeignKey('users.id'), nullable=False),
        sa.Column('user2_id', sa.Integer(), sa.ForeignKey('users.id'), nullable=False),
        sa.Column('residence_titre', sa.String()),
        sa.Column('dernier_message', sa.Text()),
        sa.Column('derniere_activite', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_table('messages',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('conversation_id', sa.Integer(), sa.ForeignKey('conversations.id'), nullable=False),
        sa.Column('sender_id', sa.Integer(), sa.ForeignKey('users.id'), nullable=False),
        sa.Column('contenu', sa.Text(), nullable=False),
        sa.Column('lu', sa.Boolean(), default=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index('ix_messages_conv', 'messages', ['conversation_id'])
    op.create_index('ix_messages_sender', 'messages', ['sender_id'])

def downgrade():
    op.drop_table('messages')
    op.drop_table('conversations')
