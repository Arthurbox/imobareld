import 'package:flutter/material.dart';
import 'package:imobareld/core/services/supabase_service.dart';
import 'package:imobareld/models/message_model.dart';
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

  /// Récupère la liste des conversations via une fonction RPC Supabase (Optimisé pour la production)
  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final userId = supabaseService.client.auth.currentUser?.id;
      if (userId == null) return [];

      // Appel direct à la fonction SQL créée sur Supabase
      // Le serveur fait le tri, filtre les bloqués et renvoie juste ce qu'il faut !
      final response = await supabaseService.client
          .rpc('get_user_conversations', params: {'current_user_id': userId});

      // La réponse est déjà formatée exactement comme notre UI l'attend
      return List<Map<String, dynamic>>.from(response);

    } catch (e) {
      debugPrint("Erreur récupération conversations via RPC: $e");
      return [];
    }
  }

  /// Bloquer un utilisateur (Insère dans la table blocked_users)
  Future<bool> blockUser(String blockedId) async {
    try {
      final userId = supabaseService.client.auth.currentUser?.id;
      if (userId == null) return false;

      await supabaseService.client.from('blocked_users').insert({
        'blocker_id': userId,
        'blocked_id': blockedId,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint("Erreur lors du blocage: $e");
      return false;
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

      // 3. Appel à la Cloud Function Firebase (Gen 2 - Cloud Run)
      final url = Uri.parse('https://sendchatpush-6kjibs7jqa-uc.a.run.app');
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Internal-Key': 'imobareld_push_secret_2026_X9kZ3mR7',
        },
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
