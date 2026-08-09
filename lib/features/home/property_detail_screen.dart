import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chewie/chewie.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'package:imobareld/core/constants/app_colors.dart';
import 'package:imobareld/core/utils/share_utils.dart';
import 'package:imobareld/features/auth/auth_controller.dart';
import 'package:imobareld/features/home/property_controller.dart';
import 'package:imobareld/models/property_model.dart';
import 'package:imobareld/models/review_model.dart';
import 'package:imobareld/models/user_model.dart';

// Nouveaux widgets extraits
import 'widgets/detail_amenities_section.dart';
import 'widgets/detail_contact_bar.dart';
import 'widgets/detail_description_section.dart';
import 'widgets/detail_info_header.dart';
import 'widgets/detail_map_section.dart';
import 'widgets/detail_media_carousel.dart';
import 'widgets/detail_reviews_section.dart';

class PropertyDetailScreen extends StatefulWidget {
  final PropertyModel property;

  const PropertyDetailScreen({super.key, required this.property});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  GoogleMapController? _mapController;
  Future<List<ReviewModel>>? _reviewsFuture;
  UserModel? _owner;
  bool _isLoadingOwner = true;

  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImages = false;
  bool _isUploadingVideo = false;

  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitializingVideo = false;
  int _activeVideoIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadOwnerInfo();
    _loadReviews();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _loadReviews() {
    final propertyController = Provider.of<PropertyController>(context, listen: false);
    _reviewsFuture = propertyController.getReviews(widget.property.id!);
  }

  Future<void> _loadOwnerInfo() async {
    try {
      if (widget.property.ownerId != null) {
        final response = await Supabase.instance.client
            .from('users')
            .select()
            .eq('id', widget.property.ownerId!)
            .maybeSingle();

        if (response != null && mounted) {
          setState(() {
            _owner = UserModel.fromMap(response, response['id'].toString());
            _isLoadingOwner = false;
          });
        } else if (mounted) {
          setState(() {
            _isLoadingOwner = false;
          });
        }
      } else {
         if (mounted) {
          setState(() {
            _isLoadingOwner = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement du propriétaire: $e');
      if (mounted) {
        setState(() {
          _isLoadingOwner = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    _loadReviews();
    await _loadOwnerInfo();
  }

  Future<void> _pickAndAddImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(imageQuality: 70);
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _isUploadingImages = true;
          _currentImageIndex = widget.property.images.length + widget.property.videoUrls.length; // Aller à la slide de chargement
        });
        _pageController.jumpToPage(_currentImageIndex);

        final propertyController = Provider.of<PropertyController>(context, listen: false);
        
        final newImages = await propertyController.updatePropertyImages(widget.property.id!, pickedFiles);
        bool success = newImages != null;
        
        if (mounted) {
          setState(() {
            _isUploadingImages = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? 'Images ajoutées avec succès' : 'Erreur lors de l\'ajout des images'),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Erreur sélection images: $e');
      if (mounted) setState(() => _isUploadingImages = false);
    }
  }

  Future<void> _pickAndAddVideo() async {
    try {
      final XFile? pickedVideo = await _picker.pickVideo(source: ImageSource.gallery);
      if (pickedVideo != null) {
        setState(() {
          _isUploadingVideo = true;
          _currentImageIndex = widget.property.images.length + widget.property.videoUrls.length;
        });
        _pageController.jumpToPage(_currentImageIndex);

        final propertyController = Provider.of<PropertyController>(context, listen: false);
        
        final newVideos = await propertyController.updatePropertyVideo(widget.property.id!, pickedVideo);
        bool success = newVideos != null;
        
        if (mounted) {
          setState(() {
            _isUploadingVideo = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? 'Vidéo ajoutée avec succès' : 'Erreur lors de l\'ajout de la vidéo'),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Erreur sélection vidéo: $e');
      if (mounted) setState(() => _isUploadingVideo = false);
    }
  }

  Future<void> _initVideo(String url, int index) async {
    if (_activeVideoIndex == index && _chewieController != null) return; // Déjà initialisée

    setState(() {
      _isInitializingVideo = true;
      _activeVideoIndex = index;
    });

    _videoPlayerController?.dispose();
    _chewieController?.dispose();

    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));
    
    try {
      await _videoPlayerController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(child: Text('Erreur vidéo: $errorMessage', style: const TextStyle(color: Colors.white)));
        },
      );
      if (mounted) setState(() => _isInitializingVideo = false);
    } catch (e) {
      debugPrint("Erreur initialisation vidéo: $e");
      if (mounted) setState(() => _isInitializingVideo = false);
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentImageIndex = index;
    });
    
    // Gérer l'arrêt de la vidéo si on quitte la slide
    if (_activeVideoIndex != -1 && index != _activeVideoIndex) {
      _chewieController?.pause();
    }

    // Gérer le lancement automatique de la vidéo
    final int videoIndex = index - widget.property.images.length;
    if (videoIndex >= 0 && videoIndex < widget.property.videoUrls.length) {
      _initVideo(widget.property.videoUrls[videoIndex], index);
    }
  }

  void _showReportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Signaler l\'annonce',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.report, color: Colors.red),
                  title: const Text('Arnaque / Fausse annonce'),
                  onTap: () => _submitReport(context, 'Arnaque / Fausse annonce'),
                ),
                ListTile(
                  leading: const Icon(Icons.explicit, color: Colors.orange),
                  title: const Text('Contenu inapproprié'),
                  onTap: () => _submitReport(context, 'Contenu inapproprié'),
                ),
                ListTile(
                  leading: const Icon(Icons.category, color: Colors.blue),
                  title: const Text('Mauvaise catégorie'),
                  onTap: () => _submitReport(context, 'Mauvaise catégorie'),
                ),
                ListTile(
                  leading: const Icon(Icons.more_horiz, color: Colors.grey),
                  title: const Text('Autre'),
                  onTap: () => _submitReport(context, 'Autre'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitReport(BuildContext context, String reason) async {
    Navigator.pop(context);
    final userId = Provider.of<AuthController>(context, listen: false).currentUser?.id;
    final messenger = ScaffoldMessenger.of(context);

    try {
      await Supabase.instance.client.from('reports').insert({
        'property_id': widget.property.id,
        'reported_by': userId ?? 'anonymous',
        'reason': reason,
        'created_at': DateTime.now().toIso8601String(),
        'status': 'pending'
      });

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Signalement envoyé avec succès.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
           const SnackBar(
            content: Text('Le signalement a été pris en compte localement.'),
            backgroundColor: Colors.blueGrey,
          ),
        );
      }
    }
  }

  void _showReviewSheet(BuildContext context) {
    final TextEditingController commentController = TextEditingController();
    double selectedRating = 5.0;
    final authController = Provider.of<AuthController>(context, listen: false);
    final propertyController = Provider.of<PropertyController>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Votre avis',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.orange,
                      size: 32,
                    ),
                    onPressed: () {
                      setModalState(() => selectedRating = index + 1.0);
                    },
                  );
                }),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Laissez un commentaire...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (authController.currentUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veuillez vous connecter')),
                    );
                    return;
                  }

                  final review = ReviewModel(
                    propertyId: widget.property.id!,
                    userId: authController.currentUser!.id,
                    userName: authController.currentUser!.name,
                    userProfilePicture: authController.currentUser!.profilePicture,
                    rating: selectedRating,
                    comment: commentController.text.trim(),
                    createdAt: DateTime.now(),
                  );

                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  
                  final success = await propertyController.addReview(review);
                  
                  if (!mounted) return;
                  
                  if (success) {
                    navigator.pop();
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Merci pour votre avis !')),
                      );
                      setState(() {
                        _loadReviews();
                      });
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppColors.primaryBlue,
                ),
                child: const Text('Publier l\'avis'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchNavigation() async {
    final lat = widget.property.latitude;
    final lng = widget.property.longitude;
    if (lat == null || lng == null) return;

    final googleNavUrl = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final appleNavUrl = Uri.parse('https://maps.apple.com/?q=$lat,$lng');
    final browserUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');

    try {
      if (await canLaunchUrl(googleNavUrl)) {
        await launchUrl(googleNavUrl);
      } else if (await canLaunchUrl(appleNavUrl)) {
        await launchUrl(appleNavUrl);
      } else {
        await launchUrl(browserUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur: Impossible de lancer la navigation.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Carousel Media (Images + Videos)
                  DetailMediaCarousel(
                    images: widget.property.images,
                    videoUrls: widget.property.videoUrls,
                    pageController: _pageController,
                    currentImageIndex: _currentImageIndex,
                    isUploadingImages: _isUploadingImages,
                    isUploadingVideo: _isUploadingVideo,
                    isInitializingVideo: _isInitializingVideo,
                    activeVideoIndex: _activeVideoIndex,
                    chewieController: _chewieController,
                    propertyId: widget.property.id!,
                    onPageChanged: _onPageChanged,
                  ),

                  // 2. Contenu scrollable
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          )
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 3. En-tête informatif
                            DetailInfoHeader(
                              property: widget.property,
                              onShowReviewSheet: () => _showReviewSheet(context),
                            ),
                            const Divider(height: 40),

                            // 4. Description & Conditions
                            DetailDescriptionSection(property: widget.property),

                            // 5. Équipements
                            DetailAmenitiesSection(property: widget.property),
                            const SizedBox(height: 30),

                            // 6. Carte Google Maps
                            DetailMapSection(
                              property: widget.property,
                              onLaunchNavigation: _launchNavigation,
                              onMapCreated: (controller) => _mapController = controller,
                            ),

                            // 7. Section Avis
                            Text(
                              'Avis des clients',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.titleLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 10),
                            DetailReviewsSection(reviewsFuture: _reviewsFuture),
                            
                            // Espace pour la barre de contact fixe
                            const SizedBox(height: 100), 
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Boutons flottants ──

            // Bouton retour
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20,
              child: CircleAvatar(
                backgroundColor: theme.cardColor,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlue),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // Actions partage & upload
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 20,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundColor: theme.cardColor,
                    child: IconButton(
                      icon: const Icon(Icons.share, color: AppColors.primaryBlue),
                      onPressed: () => ShareUtils.shareProperty(widget.property),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Consumer<AuthController>(
                    builder: (context, auth, _) {
                      if (auth.currentUser?.id == widget.property.ownerId) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              backgroundColor: theme.cardColor,
                              child: IconButton(
                                icon: const Icon(Icons.add_a_photo, color: AppColors.primaryOrange),
                                onPressed: _pickAndAddImages,
                              ),
                            ),
                            const SizedBox(width: 10),
                            CircleAvatar(
                              backgroundColor: theme.cardColor,
                              child: _isUploadingVideo
                                  ? const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.video_call, color: AppColors.primaryBlue),
                                      onPressed: _pickAndAddVideo,
                                    ),
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),

            // Bouton signaler
            Positioned(
              top: 50 + MediaQuery.of(context).padding.top,
              right: 20,
              child: GestureDetector(
                onTap: () => _showReportSheet(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flag, color: Colors.white, size: 24),
                ),
              ),
            ),

            // ── Barre de contact ──
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: DetailContactBar(
                property: widget.property,
                owner: _owner,
                isLoadingOwner: _isLoadingOwner,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
