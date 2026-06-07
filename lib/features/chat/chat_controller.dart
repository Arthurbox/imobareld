import 'package:flutter/material.dart';
import 'package:imobareld/core/services/supabase_service.dart';
import 'package:imobareld/models/message_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatController extends ChangeNotifier {
  StreamSubscription? _messagesSubscription;
  String? _activeChatId;

  // Liste locale des messages
  List<MessageModel> _currentChatMessages = [];
  List<MessageModel> get currentChatMessages => _currentChatMessages;
  bool _isLoadingMessages = false;
  bool get isLoadingMessages => _isLoadingMessages;

  /// Arrêter l'écoute du stream (renommé pour l'UI)
  void disconnectWebSocket() {
    _messagesSubscription?.cancel();
    _activeChatId = null;
    _currentChatMessages.clear();
  }

  /// Récupère la liste des conversations de l'utilisateur actuel via Supabase
  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final userId = supabaseService.client.auth.currentUser?.id;
      if (userId == null) return [];

      // Technique : Récupérer les derniers messages où l'utilisateur est présent
      // Pour une version simple, on récupère les messages distincts par interlocuteur
      final data = await supabaseService.client
          .from('messages')
          .select('*, sender:sender_id(user_name, profile_picture), receiver:receiver_id(user_name, profile_picture)')
          .or('sender_id.eq.$userId,receiver_id.eq.$userId')
          .order('timestamp', ascending: false);
      
      // Regrouper par interlocuteur pour simuler une liste de conversations
      final Map<String, Map<String, dynamic>> conversations = {};
      
      for (var msg in (data as List)) {
        final otherId = msg['sender_id'] == userId ? msg['receiver_id'] : msg['sender_id'];
        if (!conversations.containsKey(otherId)) {
          final otherProfile = msg['sender_id'] == userId ? msg['receiver'] : msg['sender'];
          conversations[otherId] = {
            'id': otherId,
            'other_user_name': otherProfile?['user_name'] ?? 'Utilisateur',
            'other_user_picture': otherProfile?['profile_picture'],
            'last_message': msg['message'],
            'last_message_time': msg['timestamp'],
            'is_read': msg['is_read'],
          };
        }
      }

      return conversations.values.toList();
    } catch (e) {
      debugPrint("Erreur récupération conversations Supabase: $e");
      return [];
    }
  }

  /// Se connecte au flux Realtime de Supabase
  Future<void> connectToChat(String currentUserId, String otherUserId) async {
    _activeChatId = otherUserId;
    _isLoadingMessages = true;
    notifyListeners();

    try {
      // 1. Charger l'historique initial
      final data = await supabaseService.client
          .from('messages')
          .select()
          .or('and(sender_id.eq.$currentUserId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$currentUserId)')
          .order('timestamp', ascending: false)
          .limit(50);

      _currentChatMessages = (data as List).map((m) => MessageModel.fromMap(m, m['id'].toString())).toList();
      _isLoadingMessages = false;
      notifyListeners();

      // 2. Écouter les nouveaux messages (Realtime)
      _messagesSubscription?.cancel();
      _messagesSubscription = supabaseService.client
          .from('messages')
          .stream(primaryKey: ['id'])
          .order('timestamp', ascending: false)
          .listen((List<Map<String, dynamic>> messages) {
            // Filtrer les messages pour cet échange précis
            final filtered = messages.where((m) => 
              (m['sender_id'] == currentUserId && m['receiver_id'] == otherUserId) ||
              (m['sender_id'] == otherUserId && m['receiver_id'] == currentUserId)
            ).toList();

            _currentChatMessages = filtered.map((m) => MessageModel.fromMap(m, m['id'].toString())).toList();
            notifyListeners();
          });

    } catch (e) {
      debugPrint("Erreur connexion Realtime Supabase: $e");
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  /// Envoie un message via Supabase
  Future<void> sendMessage(String content, [String? receiverId]) async {
    final finalReceiverId = receiverId ?? _activeChatId;
    if (content.trim().isEmpty || finalReceiverId == null) return;
    
    try {
      final userId = supabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      final messageContent = content.trim();

      // --- MISE À JOUR OPTIMISTE (AFFICHAGE IMMÉDIAT) ---
      final temporaryMessage = MessageModel(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        senderId: userId,
        receiverId: finalReceiverId,
        message: messageContent,
        isRead: false,
        timestamp: DateTime.now(),
      );
      
      // Ajouter au début de la liste (les messages récents sont en haut)
      _currentChatMessages.insert(0, temporaryMessage);
      notifyListeners();

      // --- ENVOI RÉEL À SUPABASE ---
      await supabaseService.client.from('messages').insert({
        'sender_id': userId,
        'receiver_id': finalReceiverId,
        'message': messageContent,
      });
      // Le flux Realtime s'occupera d'ajouter le vrai message à la liste automatiquement (ou confirmera celui-ci)

      // --- ENVOI NOTIFICATION PUSH ---
      _sendPushNotification(finalReceiverId, messageContent);

    } catch (e) {
      debugPrint("Erreur envoi message Supabase: $e");
      // En cas d'erreur réseau, on pourrait retirer le message optimiste ici
    }
  }

  @override
  void dispose() {
    disconnectWebSocket();
    super.dispose();
  }

  /// Appelle la Cloud Function Firebase pour envoyer une notification FCM au destinataire
  Future<void> _sendPushNotification(String receiverId, String message) async {
    try {
      // 1. Récupérer le FCM token du destinataire
      final response = await supabaseService.client
          .from('profiles')
          .select('fcm_token')
          .eq('id', receiverId)
          .maybeSingle();

      if (response == null || response['fcm_token'] == null || response['fcm_token'].toString().isEmpty) return;
      
      final String fcmToken = response['fcm_token'];
      
      // 2. Mon nom pour le titre
      final myId = supabaseService.client.auth.currentUser?.id;
      if (myId == null) return;
      final myProfile = await supabaseService.client
          .from('profiles')
          .select('user_name')
          .eq('id', myId)
          .maybeSingle();
      final senderName = myProfile?['user_name'] ?? 'Nouveau message';

      // 3. Appel à la Cloud Function Firebase
      // Assure-toi que cette URL correspond bien à ta fonction une fois déployée sur le plan Blaze
      final url = Uri.parse('https://us-central1-imobareld.cloudfunctions.net/sendChatPush');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fcm_token': fcmToken,
          'title': senderName,
          'body': message,
        }),
      );
      debugPrint('Push response: ${res.statusCode} - ${res.body}');
    } catch (e) {
      debugPrint("Erreur _sendPushNotification: $e");
    }
  }
}
