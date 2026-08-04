import 'dart:convert';
import 'package:imobareld/core/widgets/responsive_layout.dart';
import 'package:imobareld/core/widgets/cached_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:imobareld/core/constants/app_colors.dart';
import 'package:imobareld/features/auth/auth_controller.dart';
import 'package:imobareld/features/chat/chat_list_screen.dart';
import 'package:imobareld/features/home/favorites_screen.dart';
import 'package:imobareld/core/services/accessibility_settings.dart';
import 'package:imobareld/features/settings/about_us_screen.dart';
import 'package:imobareld/features/settings/contact_us_screen.dart';
import 'package:imobareld/features/settings/legal_documents_screen.dart';
import 'package:imobareld/features/settings/faq_screen.dart';
import 'package:imobareld/features/profile/my_boosts_screen.dart';
import 'package:imobareld/features/owner/subscription_screen.dart';
import 'package:imobareld/features/owner/transaction_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool hideAppBar;
  const ProfileScreen({super.key, this.hideAppBar = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthController>(context, listen: false).currentUser;
    _nameController = TextEditingController(text: user?.name);
    // Initialiser le téléphone sans le préfixe +226
    String phone = user?.phone ?? '';
    if (phone.startsWith('+226 ')) {
      phone = phone.substring(5);
    } else if (phone.startsWith('+226')) {
      phone = phone.substring(4);
    }
    _phoneController = TextEditingController(text: phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    final auth = Provider.of<AuthController>(context, listen: false);
    // Ajouter le préfixe +226 si le champ n'est pas vide
    final String cleanPhone = _phoneController.text.trim();
    final String fullPhone = cleanPhone.isNotEmpty ? '+226 $cleanPhone' : '';
    
    final messenger = ScaffoldMessenger.of(context);
    
    bool success = await auth.updateProfile(
      name: _nameController.text.trim(),
      phone: fullPhone,
    );
    
    if (!mounted) return;
    
    if (success) {
      setState(() => _isEditing = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Erreur lors de la mise à jour'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickProfilePicture() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image != null) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final auth = Provider.of<AuthController>(context, listen: false);
      
      messenger.showSnackBar(
        const SnackBar(content: Text('Mise à jour de la photo de profil...')),
      );

      bool success = await auth.updateProfilePicture(image);
      
      if (!mounted) return;

      if (success) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Photo de profil mise à jour')),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('Erreur lors de la mise à jour de la photo'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {});
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, auth, _) {
        final user = auth.currentUser;
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Non connecté')));
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: widget.hideAppBar ? null : AppBar(
            title: Text('Mon Profil', style: TextStyle(color: Theme.of(context).primaryColor)),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            elevation: 0,
            actions: [
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primaryBlue),
                  onPressed: () => setState(() => _isEditing = true),
                )
              else
                IconButton(
                  icon: const Icon(Icons.save, color: AppColors.primaryBlue),
                  onPressed: _saveProfile,
                ),
            ],
          ),
          body: ResponsiveLayout(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: AppColors.primaryBlue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                child: Column(
                children: [
                  // Header Profil avec Avatar Photo
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Theme.of(context).dividerColor, width: 4),
                            boxShadow: AppColors.softShadow,
                          ),
                          child: _buildProfileImage(user.profilePicture, user.name),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickProfilePicture,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryBlue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          style: TextStyle(
                            fontSize: 24, 
                            fontWeight: FontWeight.bold, 
                            color: Theme.of(context).textTheme.titleLarge?.color
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (user.isVerified) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.verified, color: Colors.blue, size: 24),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (!_isEditing)
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _isEditing = true),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Modifier le profil'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                        foregroundColor: AppColors.primaryBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _saveProfile,
                      icon: const Icon(Icons.save, size: 16),
                      label: const Text('Enregistrer les modifications'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  const SizedBox(height: 24),
                  
                  // Informations
                  _buildInfoCard(
                    title: 'Informations personnelles',
                    children: [
                      _buildInfoTile(
                        label: 'Nom complet',
                        value: user.name,
                        isEditable: _isEditing,
                        controller: _nameController,
                        suffix: user.isVerified 
                            ? const Icon(Icons.verified, color: Colors.blue, size: 20) 
                            : null,
                      ),
                      const Divider(),
                      _buildInfoTile(
                        label: 'Email',
                        value: user.email,
                        isEditable: false,
                      ),
                      const Divider(),
                      _buildInfoTile(
                        label: 'Téléphone',
                        value: user.phone ?? 'Non renseigné',
                        isEditable: _isEditing,
                        controller: _phoneController,
                        prefixText: '+226 ',
                      ),
                      const Divider(),
                      _buildInfoTile(
                        label: 'Type de compte',
                        value: user.userType.toUpperCase(),
                        isEditable: false,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Raccourcis
                  _buildInfoCard(
                    title: 'Activités',
                    children: [
                      ListTile(
                        leading: const Icon(Icons.favorite, color: Colors.red),
                        title: Text('Mes Favoris', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                          );
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: Icon(Icons.message, color: Theme.of(context).primaryColor),
                        title: Text('Mes Discussions', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()));
                        },
                      ),
                      if (user.isOwner) ...[
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.home_work, color: AppColors.primaryOrange),
                          title: Text('Mes Annonces', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // Naviguer vers le tableau de bord propriétaire
                            Navigator.pushNamed(context, '/owner_dashboard');
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.rocket_launch, color: Colors.purple),
                          title: Text('Mes Boostes', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MyBoostsScreen()),
                            );
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.receipt_long, color: Colors.indigo),
                          title: Text('Historique des paiements', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
                            );
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.card_membership, color: Colors.teal),
                          title: Text('Abonnement', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                          subtitle: user.subscriptionStatus == 'trial' && user.trialEndsAt != null && user.trialEndsAt!.isAfter(DateTime.now())
                              ? const Text('Essai gratuit en cours', style: TextStyle(color: Colors.green, fontSize: 12))
                              : null,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
    
                  const SizedBox(height: 20),
    
                  // Autres
                  _buildInfoCard(
                    title: 'Général',
                    children: [
                      ListTile(
                        leading: Icon(Icons.help_outline, color: Theme.of(context).iconTheme.color),
                        title: Text('Centre d\'aide', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ContactUsScreen()),
                          );
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: Icon(Icons.question_answer_outlined, color: AppColors.primaryBlue),
                        title: Text('FAQ', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const FaqScreen()),
                          );
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: Icon(Icons.description, color: AppColors.primaryBlue),
                        title: Text('Conditions Générales', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LegalDocumentsScreen(isTermsOfService: true)),
                          );
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: Icon(Icons.privacy_tip, color: AppColors.primaryBlue),
                        title: Text('Politique de Confidentialité', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LegalDocumentsScreen(isTermsOfService: false)),
                          );
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: Icon(Icons.info_outline, color: Theme.of(context).iconTheme.color),
                        title: Text('À propos de IMOBARELD', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AboutUsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
    
                  const SizedBox(height: 20),
    
                  // Affichage (Mode Sombre/Clair)
                  _buildInfoCard(
                    title: 'Affichage',
                    children: [
                      Consumer<AccessibilitySettings>(
                        builder: (context, accessibility, _) {
                          return Column(
                            children: [
                              RadioGroup<ThemeMode>(
                                groupValue: accessibility.themeMode,
                                onChanged: (ThemeMode? value) {
                                  if (value != null) accessibility.setThemeMode(value);
                                },
                                child: Column(
                                  children: [
                                    RadioListTile<ThemeMode>(
                                      title: Text('Mode Sombre', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                                      secondary: const Icon(Icons.dark_mode, color: Colors.indigo),
                                      value: ThemeMode.dark,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    RadioListTile<ThemeMode>(
                                      title: Text('Mode Système', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                                      secondary: const Icon(Icons.brightness_auto, color: Colors.grey),
                                      value: ThemeMode.system,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
    
                  const SizedBox(height: 30),
                  
                  // Bouton Déconnexion
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        await auth.logout();
                        if (!mounted) return;
                        navigator.pushReplacementNamed('/login');
                      },
                      icon: const Icon(Icons.logout),
                      label: Text('Se déconnecter', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.white)), // Colors.white follows original style button (redAccent)
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bouton Supprimer mon compte
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () async {
                        final bool? confirm = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Supprimer mon compte'),
                              content: const Text(
                                'Êtes-vous sûr ? Cette action est irréversible et supprimera toutes vos données.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Annuler'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            );
                          },
                        );

                        if (confirm == true && mounted) {
                          final authController = Provider.of<AuthController>(context, listen: false);
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);
                          
                          final success = await authController.deleteAccount();
                          if (success) {
                            navigator.pushReplacementNamed('/login');
                          } else {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Erreur lors de la suppression du compte.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      label: const Text('Supprimer mon compte', style: TextStyle(color: Colors.red)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

  Widget _buildProfileImage(String? profilePicture, String? userName) {
    return CachedAvatar(
      imageUrl: profilePicture,
      name: userName,
      radius: 60,
      fontSize: 48,
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required String label,
    required String value,
    bool isEditable = false,
    TextEditingController? controller,
    String? prefixText,
    Widget? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color)),
          if (isEditable && controller != null)
            TextField(
              controller: controller,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                prefixText: prefixText,
                prefixStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold),
              ),
            )
          else
            Row(
              children: [
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                if (suffix != null) ...[
                  const SizedBox(width: 6),
                  suffix,
                ],
              ],
            ),
        ],
      ),
    );
  }
}

