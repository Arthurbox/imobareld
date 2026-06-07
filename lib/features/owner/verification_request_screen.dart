import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:imobareld/features/auth/auth_controller.dart';
import 'package:imobareld/core/constants/app_colors.dart';

class VerificationRequestScreen extends StatefulWidget {
  const VerificationRequestScreen({super.key});

  @override
  State<VerificationRequestScreen> createState() => _VerificationRequestScreenState();
}

class _VerificationRequestScreenState extends State<VerificationRequestScreen> {
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _submitVerification(BuildContext context) async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un document.')),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final authController = Provider.of<AuthController>(context, listen: false);
    
    // Convert to Base64
    List<int> imageBytes = await _selectedImage!.readAsBytes();
    String base64Image = base64Encode(imageBytes);

    final success = await authController.submitVerificationRequest([base64Image]);

    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Demande envoyée avec succès !')),
      );
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification du Profil'),
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        foregroundColor: theme.iconTheme.color,
        iconTheme: IconThemeData(color: theme.iconTheme.color),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pour obtenir le badge "Vérifié", veuillez télécharger une photo de votre pièce d\'identité (CNI, Passeport).',
              style: TextStyle(fontSize: 16, color: theme.textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 24),
            
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.white24 : Colors.grey[400]!),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb ? Image.network(_selectedImage!.path, fit: BoxFit.cover) : Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file, size: 50, color: isDark ? Colors.grey[400] : Colors.grey),
                          const SizedBox(height: 8),
                          Text('Appuyez pour ajouter un document', style: TextStyle(color: isDark ? Colors.grey[300] : Colors.black54)),
                        ],
                      ),
              ),
            ),
            
            const Spacer(),
            
            Consumer<AuthController>(
              builder: (context, auth, _) {
                return ElevatedButton(
                  onPressed: auth.isLoading ? null : () => _submitVerification(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Envoyer la demande',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
