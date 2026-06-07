import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/features/admin/admin_controller.dart';
import 'package:imobareld/models/user_model.dart';

// 2. VUE UTILISATEURS
class AdminUsersView extends StatefulWidget {
  const AdminUsersView({super.key});

  @override
  State<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<AdminUsersView> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminCtrl = Provider.of<AdminController>(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchCtrl,
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            onChanged: (val) {
              setState(() => _searchQuery = val);
            },
            decoration: InputDecoration(
              hintText: 'Rechercher un utilisateur...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<UserModel>>(
            stream: adminCtrl.allUsersStream(query: _searchQuery),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Erreur: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
              }

              var users = snapshot.data ?? [];
              
              // Filtrage Optimistic UI
              users = users.where((u) => !adminCtrl.isPendingDeletion(u.id)).toList();
              if (users.isEmpty) {
                return const Center(child: Text('Aucun utilisateur trouvé'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: (user.profilePicture != null && user.profilePicture!.isNotEmpty)
                            ? NetworkImage(user.profilePicture!)
                            : null,
                        child: (user.profilePicture == null || user.profilePicture!.isEmpty)
                            ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?')
                            : null,
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text(user.name, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).textTheme.titleMedium?.color))),
                          if (user.isVerified) const Icon(Icons.verified, color: Colors.blue, size: 16),
                        ],
                      ),
                      subtitle: Text('${user.email}\n${user.userType}', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!user.isSupremeAdmin) ...[
                            IconButton(
                              icon: Icon(
                                user.role == 'admin' ? Icons.security : Icons.security_outlined,
                                color: user.role == 'admin' ? Colors.purple : Colors.grey,
                              ),
                              onPressed: () => _toggleAdmin(context, user, adminCtrl),
                              tooltip: user.role == 'admin' ? 'Retirer Admin' : 'Nommer Admin',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _confirmDelete(context, user, adminCtrl),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _toggleAdmin(BuildContext context, UserModel targetUser, AdminController controller) {
    String newRole = targetUser.role == 'admin' ? 'user' : 'admin';
    String action = targetUser.role == 'admin' ? 'retirer les droits admin' : 'nommer administrateur';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(targetUser.name),
        content: Text('Voulez-vous $action cet utilisateur ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // fermer dialog
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mise à jour en cours...')),
                );
                await controller.updateRole(targetUser.id, newRole);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${targetUser.name} est maintenant ${newRole == 'admin' ? 'Administrateur' : 'Utilisateur'}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur SQL:\n${e.toString()}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 10),
                    ),
                  );
                }
              }
            },
            child: const Text('Confirmer', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, UserModel user, AdminController controller) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cet utilisateur ?'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${user.name} ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Suppression de ${user.name} en cours...')),
                );
                
                await controller.deleteUser(user.id);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Utilisateur supprimé avec succès !'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur SQL:\n${e.toString()}'), 
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 10),
                    ),
                  );
                  debugPrint('🚨 ERREUR COMPLETE RPC : $e');
                }
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
