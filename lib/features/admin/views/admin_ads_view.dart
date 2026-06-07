import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:video_compress/video_compress.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:imobareld/core/constants/app_colors.dart';
import 'package:imobareld/features/home/ad_controller.dart';
import 'package:imobareld/features/home/realisation_controller.dart';
import 'package:imobareld/features/auth/auth_controller.dart';
import 'package:imobareld/models/ad_model.dart';
import 'package:imobareld/models/realisation_model.dart';
import 'package:imobareld/core/widgets/cached_image.dart';

// 5. VUE GESTION DES PUBLICITÉS ET RÉALISATIONS
class AdminAdsView extends StatefulWidget {
  const AdminAdsView({super.key});

  @override
  State<AdminAdsView> createState() => _AdminAdsViewState();
}

class _AdminAdsViewState extends State<AdminAdsView> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _addNewAd(String type) async {
    final XFile? file = type == 'image'
        ? await _picker.pickImage(source: ImageSource.gallery)
        : await _picker.pickVideo(source: ImageSource.gallery);

    if (file == null) return;

    if (kIsWeb && type == 'video' && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sur Web, les vidéos ne sont pas compressées. Préférez des fichiers < 50 Mo.'),
          duration: Duration(seconds: 4),
        ),
      );
    }

    final bytes = await file.readAsBytes();
    if (bytes.length > 15 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fichier trop volumineux (> 15Mo).')),
        );
      }
      return;
    }

    final TextEditingController urlController = TextEditingController();

    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isPublishing = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(type == 'image' ? 'Nouvelle Image Pub' : 'Nouvelle Vidéo Pub'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (type == 'image')
                    SizedBox(
                      height: 100,
                      width: double.infinity,
                      child: Image.memory(bytes, fit: BoxFit.cover),
                    )
                  else
                    const Column(
                      children: [
                        Icon(Icons.video_file, size: 50, color: AppColors.primaryBlue),
                        Text('Vidéo sélectionnée'),
                      ],
                    ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: urlController,
                    enabled: !isPublishing,
                    decoration: const InputDecoration(
                      labelText: 'URL cible (optionnel)',
                      hintText: 'https://...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (isPublishing)
                    const Padding(
                      padding: EdgeInsets.only(top: 15),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
              actions: [
                if (!isPublishing)
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                if (!isPublishing)
                  ElevatedButton(
                    onPressed: () async {
                      setDialogState(() => isPublishing = true);
                      
                      final adController = Provider.of<AdController>(context, listen: false);
                      
                      final String? uploadedUrl = await adController.uploadAdImage(file);
                      
                      if (uploadedUrl == null) {
                        setDialogState(() => isPublishing = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Erreur lors de l\'upload de l\'image.'))
                          );
                        }
                        return;
                      }

                      final newAd = AdModel(
                        imageUrl: uploadedUrl,
                        targetUrl: urlController.text.trim().isEmpty ? null : urlController.text.trim(),
                        createdAt: DateTime.now(),
                        priority: 0,
                        type: type,
                      );
                      
                      if (!context.mounted) return;
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      
                      bool success = await adController.addAd(newAd);
                      
                      if (success) {
                        navigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Publicité publiée avec succès !'))
                        );
                      } else {
                        setDialogState(() => isPublishing = false);
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Erreur lors de la publication.'))
                        );
                      }
                    },
                    child: const Text('Publier'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addNewRealisation(String type) async {
    final XFile? file = type == 'image'
        ? await _picker.pickImage(source: ImageSource.gallery)
        : await _picker.pickVideo(source: ImageSource.gallery);

    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (bytes.length > 50 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fichier trop volumineux (> 50Mo).')),
        );
      }
      return;
    }

    final TextEditingController titleController = TextEditingController();
    final TextEditingController descController = TextEditingController();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isPublishing = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(type == 'image' ? 'Nouvelle Réalisation (Image)' : 'Nouvelle Réalisation (Vidéo)'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (type == 'image')
                      SizedBox(
                        height: 100,
                        width: double.infinity,
                        child: Image.memory(bytes, fit: BoxFit.cover),
                      )
                    else
                      FutureBuilder<Uint8List?>(
                        future: kIsWeb ? Future.value(null) : VideoCompress.getByteThumbnail(file.path, quality: 50),
                        builder: (context, thumbSnapshot) {
                          if (thumbSnapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(
                              height: 100,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          if (thumbSnapshot.hasData && thumbSnapshot.data != null) {
                            return SizedBox(
                              height: 120,
                              width: double.infinity,
                              child: Image.memory(thumbSnapshot.data!, fit: BoxFit.cover),
                            );
                          }
                          return const Column(
                            children: [
                              Icon(Icons.video_file, size: 50, color: AppColors.primaryBlue),
                              Text('Vidéo sélectionnée'),
                            ],
                          );
                        },
                      ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descController,
                      enabled: !isPublishing,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optionnelle)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (isPublishing)
                      const Padding(
                        padding: EdgeInsets.only(top: 15),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
              actions: [
                if (!isPublishing)
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                if (!isPublishing)
                  ElevatedButton(
                    onPressed: () async {
                      setDialogState(() => isPublishing = true);
                      
                      final realController = Provider.of<RealisationController>(context, listen: false);
                      final authController = Provider.of<AuthController>(context, listen: false);
                      final user = authController.currentUser;
                      
                      if (user == null) return;
                      
                      String? videoUrl;
                      String? thumbnailUrl;
                      List<String> images = [];
                      List<String> videoUrls = [];

                      if (type == 'video') {
                        // Upload Vidéo avec miniature
                        videoUrl = await realController.compressAndUploadVideo(file);
                        thumbnailUrl = await realController.generateThumbnail(file);
                        
                        if (videoUrl != null) videoUrls.add(videoUrl);
                        if (thumbnailUrl != null) images.add(thumbnailUrl);
                      } else {
                        // Upload Image classique
                        final String? uploadedUrl = await realController.uploadMedia(file);
                        if (uploadedUrl != null) images.add(uploadedUrl);
                      }
                      
                      if (images.isEmpty && videoUrls.isEmpty) {
                        setDialogState(() => isPublishing = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Erreur lors de l\'upload.'))
                          );
                        }
                        return;
                      }

                      final newRealisation = RealisationModel(
                        ownerId: user.id,
                        title: '',
                        description: descController.text.trim(),
                        images: images,
                        videoUrls: videoUrls,
                        createdAt: DateTime.now(),
                      );
                      
                      bool success = await realController.addRealisation(newRealisation);
                      
                      if (!context.mounted) return;
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      
                      if (success) {
                        navigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Réalisation ajoutée avec succès !'))
                        );
                      } else {
                        setDialogState(() => isPublishing = false);
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Erreur lors de la création.'))
                        );
                      }
                    },
                    child: const Text('Publier'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmAdDelete(BuildContext context, AdModel ad, AdController controller) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cette publicité ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              final success = await controller.deleteAd(ad.id!);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Publicité supprimée.' : 'Erreur lors de la suppression.'),
                    backgroundColor: success ? null : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmRealisationDelete(BuildContext context, RealisationModel prop, RealisationController controller) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cette réalisation ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              final success = await controller.deleteRealisation(prop.id!);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Réalisation supprimée.' : 'Erreur lors de la suppression.'),
                    backgroundColor: success ? null : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: TabBar(
            tabs: [
              Tab(text: 'Publicités (Bannières)'),
              Tab(text: 'Nos Réalisations'),
            ],
            labelColor: AppColors.primaryBlue,
            indicatorColor: AppColors.primaryBlue,
          ),
        ),
        body: TabBarView(
          children: [
            _buildAdsTab(context),
            _buildRealisationsTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAdsTab(BuildContext context) {
    final adController = Provider.of<AdController>(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<AdModel>>(
        stream: adController.allAdsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Erreur: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final ads = snapshot.data ?? [];
          if (ads.isEmpty) return const Center(child: Text('Aucune publicité enregistrée.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ads.length,
            itemBuilder: (context, index) {
              final ad = ads[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: ad.isActive ? 4 : 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    if (ad.type == 'image')
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            ad.isActive ? Colors.transparent : Colors.grey,
                            BlendMode.saturation,
                          ),
                          child: CachedImage(imageUrl: ad.imageUrl, height: 120, width: double.infinity),
                        ),
                      )
                    else
                      Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: ad.isActive ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.videocam, size: 40, color: ad.isActive ? AppColors.primaryBlue : Colors.grey),
                              Text(ad.isActive ? 'Publicité Vidéo' : 'Vidéo (Inactive)', style: TextStyle(color: ad.isActive ? null : Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ListTile(
                      title: Text(ad.targetUrl ?? 'Sans lien de redirection', style: TextStyle(decoration: ad.isActive ? null : TextDecoration.lineThrough)),
                      subtitle: Text('Type: ${ad.type == 'image' ? 'Image' : 'Vidéo'} • Créé le: ${ad.createdAt.toString().split(' ')[0]}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: ad.isActive,
                            onChanged: (val) => adController.updateAd(ad.copyWith(isActive: val)),
                            activeColor: Colors.green,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _confirmAdDelete(context, ad, adController),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => _addNewAd('video'),
            heroTag: 'add_video_ad',
            mini: true,
            backgroundColor: Colors.orange,
            child: const Icon(Icons.videocam, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: () => _addNewAd('image'),
            heroTag: 'add_image_ad',
            mini: true,
            backgroundColor: AppColors.primaryBlue,
            child: const Icon(Icons.image, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildRealisationsTab(BuildContext context) {
    final realController = Provider.of<RealisationController>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<RealisationModel>>(
        stream: realController.realisationsStream,
        initialData: realController.realisations,
        builder: (context, snapshot) {
          final realisations = snapshot.data ?? [];

          if (snapshot.hasError && realisations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off, size: 60, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur de connexion au serveur :\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => setState(() {}),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting && realisations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (realisations.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aucune réalisation enregistrée.'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: realisations.length,
            itemBuilder: (context, index) {
              final prop = realisations[index];
              final isVideo = prop.videoUrls.isNotEmpty;
              final cover = prop.images.isNotEmpty ? prop.images.first : null;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    if (cover != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: CachedImage(imageUrl: cover, height: 160, width: double.infinity),
                      )
                    else if (isVideo)
                      Container(
                        height: 160,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: const Center(
                          child: Icon(Icons.videocam, size: 40, color: Colors.white),
                        ),
                      )
                    else
                      Container(
                        height: 100,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
                    ListTile(
                      title: Text(prop.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(prop.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _confirmRealisationDelete(context, prop, realController),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => _addNewRealisation('video'),
            heroTag: 'add_video_realisation',
            mini: true,
            backgroundColor: Colors.orange,
            child: const Icon(Icons.videocam, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: () => _addNewRealisation('image'),
            heroTag: 'add_image_realisation',
            mini: true,
            backgroundColor: AppColors.primaryBlue,
            child: const Icon(Icons.image, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
