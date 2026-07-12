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
  final Set<String> _selectedUserIds = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedUserIds.clear();
    });
  }

  void _confirmDeleteSelected(BuildContext context, AdminController controller) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer la sélection ?'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${_selectedUserIds.length} utilisateur(s) ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Suppression de ${_selectedUserIds.length} utilisateur(s) en cours...')),
                );
                
                for (var id in _selectedUserIds) {
                  await controller.deleteUser(id);
                }
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Utilisateurs supprimés avec succès !'), backgroundColor: Colors.green),
                  );
                  _clearSelection();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur:\n${e.toString()}'), 
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 10),
                    ),
                  );
                }
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminCtrl = Provider.of<AdminController>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _selectedUserIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _confirmDeleteSelected(context, adminCtrl),
              backgroundColor: Colors.red,
              icon: const Icon(Icons.delete, color: Colors.white),
              label: Text('Supprimer (${_selectedUserIds.length})', style: const TextStyle(color: Colors.white)),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
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
                if (_selectedUserIds.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.clear_all),
                    onPressed: _clearSelection,
                    tooltip: 'Désélectionner tout',
                  ),
                ]
              ],
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
                  padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 80),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final isSelected = _selectedUserIds.contains(user.id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? Colors.red : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ListTile(
                        onTap: () => _toggleSelection(user.id),
                        leading: Checkbox(
                          value: isSelected,
                          onChanged: (val) => _toggleSelection(user.id),
                          activeColor: Colors.red,
                        ),
                        title: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundImage: (user.profilePicture != null && user.profilePicture!.isNotEmpty)
                                  ? NetworkImage(user.profilePicture!)
                                  : null,
                              child: (user.profilePicture == null || user.profilePicture!.isEmpty)
                                  ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 10))
                                  : null,
                            ),
                            const SizedBox(width: 8),
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
      ),
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
}
