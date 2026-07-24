import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/features/admin/admin_controller.dart';
import 'package:intl/intl.dart';

class AdminChatManagerView extends StatefulWidget {
  const AdminChatManagerView({super.key});

  @override
  State<AdminChatManagerView> createState() => _AdminChatManagerViewState();
}

class _AdminChatManagerViewState extends State<AdminChatManagerView> {
  final Set<String> _selectedPairs = {};
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    final controller = Provider.of<AdminController>(context, listen: false);
    final convs = await controller.getAllConversationsAdmin();
    setState(() {
      _conversations = convs;
      _isLoading = false;
    });
  }

  void _toggleSelection(String pairKey) {
    setState(() {
      if (_selectedPairs.contains(pairKey)) {
        _selectedPairs.remove(pairKey);
      } else {
        _selectedPairs.add(pairKey);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedPairs.clear());
  }

  void _confirmDeleteSelected() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer les discussions ?'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${_selectedPairs.length} discussion(s) ? Cette action est irréversible et effacera tous les messages entre ces utilisateurs.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final controller = Provider.of<AdminController>(context, listen: false);
              
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Suppression de ${_selectedPairs.length} discussion(s) en cours...')),
                );
                
                for (var pairKey in _selectedPairs) {
                  final conv = _conversations.firstWhere((c) => c['pair_key'] == pairKey);
                  await controller.deleteConversationAdmin(conv['user1_id'], conv['user2_id']);
                }
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Discussions supprimées avec succès !'), backgroundColor: Colors.green),
                  );
                  _clearSelection();
                  _loadConversations(); // Recharger la liste
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

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Chats'),
        actions: [
          if (_selectedPairs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearSelection,
              tooltip: 'Désélectionner tout',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversations,
          ),
        ],
      ),
      floatingActionButton: _selectedPairs.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _confirmDeleteSelected,
              backgroundColor: Colors.red,
              icon: const Icon(Icons.delete, color: Colors.white),
              label: Text('Supprimer (${_selectedPairs.length})', style: const TextStyle(color: Colors.white)),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? const Center(child: Text('Aucune discussion trouvée.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16).copyWith(bottom: 80),
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final conv = _conversations[index];
                    final pairKey = conv['pair_key'];
                    final isSelected = _selectedPairs.contains(pairKey);

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
                        onTap: () => _toggleSelection(pairKey),
                        leading: Checkbox(
                          value: isSelected,
                          onChanged: (val) => _toggleSelection(pairKey),
                          activeColor: Colors.red,
                        ),
                        title: Text(
                          '${conv['user1_name']} & ${conv['user2_name']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              conv['last_message'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(conv['last_message_time']),
                              style: TextStyle(fontSize: 10, color: theme.textTheme.bodySmall?.color),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
