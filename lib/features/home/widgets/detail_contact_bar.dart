import 'package:flutter/material.dart';
import 'package:imobareld/core/constants/app_colors.dart';
import 'package:imobareld/core/constants/user_roles.dart';
import 'package:imobareld/core/widgets/cached_avatar.dart';
import 'package:imobareld/features/auth/auth_controller.dart';
import 'package:imobareld/features/chat/chat_detail_screen.dart';
import 'package:imobareld/features/chat/chat_list_screen.dart';
import 'package:imobareld/models/property_model.dart';
import 'package:imobareld/models/user_model.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Barre de contact fixe en bas de l'écran de détail d'une propriété.
/// Permet de voir les infos du propriétaire, d'envoyer un message via le chat
/// ou de contacter par téléphone/WhatsApp/SMS.
class DetailContactBar extends StatelessWidget {
  final PropertyModel property;
  final UserModel? owner;
  final bool isLoadingOwner;

  const DetailContactBar({
    super.key,
    required this.property,
    required this.owner,
    required this.isLoadingOwner,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -5),
            blurRadius: 10,
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Row(
        children: [
          // ── Avatar ──
          isLoadingOwner
              ? CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey.shade100,
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                )
              : CachedAvatar(
                  radius: 30,
                  imageUrl: owner?.profilePicture,
                  name: owner?.name ?? property.ownerName ?? '...',
                ),
          const SizedBox(width: 15),

          // ── Infos Propriétaire ──
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isLoadingOwner
                            ? (property.ownerName ?? 'Initialisation...')
                            : (owner?.name ?? property.ownerName ?? 'Propriétaire inconnu'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (owner != null && owner!.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, color: Colors.blue, size: 16),
                    ],
                  ],
                ),
                const Text(
                  'Propriétaire',
                  style: TextStyle(color: AppColors.textLight, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // ── Bouton Chat ──
          GestureDetector(
            onTap: () {
              final auth = Provider.of<AuthController>(context, listen: false);
              final currentUser = auth.currentUser;
              if (currentUser == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez vous connecter pour envoyer un message.')),
                );
                return;
              }

              final ownerId = owner?.id ?? property.ownerId;
              final ownerName = owner?.name ?? property.ownerName ?? 'Propriétaire';

              // ─────────────────────────────────────────────────────────────
              // LOGIQUE DE CHAT AGENCE IMOBARELD
              //
              // • Propriétaire de l'annonce → sa boîte de réception (Inbox)
              // • Admin (agence) → chat direct avec le vrai propriétaire
              //   (pour coordonner la visite/transaction)
              // • Client / Locataire → chat avec l'AGENCE uniquement
              //   (le client ne contacte jamais le proprio directement)
              // ─────────────────────────────────────────────────────────────

              if (currentUser.id == ownerId) {
                // Le proprio consulte sa propre annonce → Inbox
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatListScreen()),
                );
              } else if (currentUser.isAdmin) {
                // L'admin (agence) ouvre le chat avec le VRAI propriétaire
                // pour coordonner la visite ou la transaction
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatDetailScreen(
                      otherUserId: ownerId,
                      otherUserName: ownerName,
                    ),
                  ),
                );
              } else {
                // Client / Locataire → chat avec l'AGENCE IMOBARELD
                // L'agence joue le rôle d'intermédiaire
                if (UserRoles.agencyUserId == 'REMPLACE_PAR_TON_UUID_SUPABASE') {
                  // Sécurité : si l'ID n'est pas encore configuré, on prévient
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Configuration agence incomplète. Contactez-nous par téléphone.'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatDetailScreen(
                      otherUserId: UserRoles.agencyUserId,
                      otherUserName: UserRoles.agencyName,
                    ),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                shape: BoxShape.circle,
                boxShadow: isDark
                    ? []
                    : [
                        const BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
              ),
              child: Consumer<AuthController>(
                builder: (context, auth, _) => Icon(
                  Icons.chat_bubble_outline,
                  color: auth.currentUser?.id == owner?.id
                      ? AppColors.primaryOrange
                      : AppColors.primaryBlue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // ── Bouton Téléphone ──
          GestureDetector(
            onTap: () {
              final name = owner?.name ?? property.ownerName ?? 'le propriétaire';
              _showContactOptions(context, name);
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.phone, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  void _showContactOptions(BuildContext context, String name) {
    final authController = context.read<AuthController>();
    final isAdmin = authController.currentUser?.isAdmin ?? false;
    
    // Numéro de l'agence par défaut
    const String agencyPhone = '+22657428929';
    
    // Le vrai numéro du propriétaire se trouve soit dans owner.phone, soit dans property.ownerPhone
    final String? realOwnerPhone = (owner != null && owner!.phone != null && owner!.phone!.isNotEmpty)
        ? owner!.phone
        : (property.ownerPhone != null && property.ownerPhone!.isNotEmpty ? property.ownerPhone : null);
    
    // Si l'utilisateur est admin et que le propriétaire a un numéro valide
    final String contactPhone = (isAdmin && realOwnerPhone != null) ? realOwnerPhone : agencyPhone;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isAdmin && contactPhone != agencyPhone
                      ? 'Contacter $name (Numéro Propriétaire)'
                      : 'Contacter l\'agence',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phone, color: Colors.blue),
                  ),
                  title: const Text('Appel téléphonique'),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(context);
                    final Uri launchUri = Uri(
                      scheme: 'tel',
                      path: contactPhone,
                    );
                    try {
                      if (await canLaunchUrl(launchUri)) {
                        await launchUrl(launchUri);
                      } else {
                        throw 'Impossible';
                      }
                    } catch (e) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Impossible de lancer l\'appel.')),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.message, color: Color(0xFF25D366)),
                  ),
                  title: const Text('WhatsApp'),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(context);
                    final cleanNumber = contactPhone.replaceAll(RegExp(r'[^\d+]'), '');
                    final String message = "Bonjour, je suis intéressé par le bien \"${property.title}\" (Réf: ${property.referenceCode}). Pouvez-vous me donner plus d'informations ?";
                    final Uri whatsappUri = Uri.parse('https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}');

                    try {
                      if (await canLaunchUrl(whatsappUri)) {
                        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
                      } else {
                        throw 'Impossible';
                      }
                    } catch (e) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Impossible d\'ouvrir WhatsApp.')),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sms, color: Colors.orange),
                  ),
                  title: const Text('Envoyer un SMS'),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(context);
                    final cleanNumber = contactPhone.replaceAll(RegExp(r'[^\d+]'), '');
                    final String message = "Bonjour, je suis intéressé par le bien \"${property.title}\" (Réf: ${property.referenceCode}). Pouvez-vous me donner plus d'informations ?";
                    final Uri smsUri = Uri(
                      scheme: 'sms', 
                      path: cleanNumber,
                      queryParameters: <String, String>{
                        'body': message,
                      },
                    );

                    try {
                      if (await canLaunchUrl(smsUri)) {
                        await launchUrl(smsUri);
                      } else {
                        throw 'Impossible';
                      }
                    } catch (e) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Impossible de lancer l\'application SMS.')),
                      );
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
