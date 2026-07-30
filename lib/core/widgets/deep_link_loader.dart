import 'package:flutter/material.dart';
import 'package:imobareld/core/services/supabase_service.dart';
import 'package:imobareld/features/home/property_detail_screen.dart';
import 'package:imobareld/models/property_model.dart';

class DeepLinkLoader extends StatefulWidget {
  final String type; // 'property'
  final String id;

  const DeepLinkLoader({super.key, required this.type, required this.id});

  @override
  State<DeepLinkLoader> createState() => _DeepLinkLoaderState();
}

class _DeepLinkLoaderState extends State<DeepLinkLoader> {
  @override
  void initState() {
    super.initState();
    _loadAndNavigate();
  }

  Future<void> _loadAndNavigate() async {
    try {
      if (widget.type == 'property') {
        final Map<String, dynamic> data = await supabaseService.client
            .from('properties')
            .select('*, profiles(*)')
            .eq('id', widget.id)
            .single();
        
        // Aplatir les données du profil pour le modèle si nécessaire
        if (data['profiles'] != null) {
          data['owner_name'] = data['profiles']['full_name'];
          data['owner_phone'] = data['profiles']['phone'];
        }
        
        if (mounted) {
          final property = PropertyModel.fromMap(data, widget.id);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PropertyDetailScreen(property: property),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading deep link data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de charger l\'annonce.')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
