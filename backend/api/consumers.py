import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.contrib.auth import get_user_model
from .models import Message
from .serializers import MessageSerializer

User = get_user_model()

class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.user = self.scope['user']
        # Si l'utilisateur n'est pas authentifié par le JWTAuthMiddleware, on refuse
        if not self.user.is_authenticated:
            await self.close()
            return

        self.other_user_id = self.scope['url_route']['kwargs']['user_id']
        
        # Générer un nom de salle (room) unique et identique peu importe qui initie la connexion
        user_ids = sorted([str(self.user.id), str(self.other_user_id)])
        self.room_group_name = f'chat_{user_ids[0]}_{user_ids[1]}'

        # Rejoindre le groupe (room) Channel
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )

        await self.accept()

    async def disconnect(self, close_code):
        # Quitter le groupe
        if hasattr(self, 'room_group_name'):
            await self.channel_layer.group_discard(
                self.room_group_name,
                self.channel_name
            )

    # Réception d'un message depuis le WebSocket (du client vers le serveur)
    async def receive(self, text_data):
        text_data_json = json.loads(text_data)
        message_content = text_data_json.get('message')
        
        if not message_content:
            return

        # Enregistrer le message en base de données
        msg_instance = await self.save_message(self.user.id, self.other_user_id, message_content)
        msg_data = await self.serialize_message(msg_instance)

        # Diffuser le message au groupe complet (expéditeur et destinataire)
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'chat_message',
                'message': msg_data
            }
        )

    # Réception d'un message depuis le groupe Channel (broadcast)
    async def chat_message(self, event):
        message_data = event['message']

        # Envoi au websocket
        await self.send(text_data=json.dumps({
            'message': message_data
        }))

    @database_sync_to_async
    def save_message(self, sender_id, receiver_id, message_content):
        sender = User.objects.get(id=sender_id)
        receiver = User.objects.get(id=receiver_id)
        msg = Message.objects.create(
            sender=sender,
            receiver=receiver,
            message=message_content,
            isRead=False
        )
        return msg

    @database_sync_to_async
    def serialize_message(self, message_instance):
        return MessageSerializer(message_instance).data
