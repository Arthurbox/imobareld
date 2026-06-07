import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:imobareld/core/widgets/cached_avatar.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/core/utils/amenity_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:imobareld/core/constants/app_colors.dart';
import 'package:imobareld/features/auth/auth_controller.dart';
import 'package:imobareld/features/chat/chat_detail_screen.dart';
import 'package:imobareld/features/chat/chat_list_screen.dart';
import 'package:imobareld/features/home/property_controller.dart';
import 'package:imobareld/models/property_model.dart';
import 'package:imobareld/models/user_model.dart';
import 'package:imobareld/models/review_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:imobareld/core/widgets/cached_image.dart';
import 'package:imobareld/core/widgets/full_screen_image_viewer.dart';
import 'package:imobareld/core/widgets/banner_ad_widget.dart';
import 'package:imobareld/core/utils/share_utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PropertyDetailScreen extends StatefulWidget {
  final PropertyModel property;

  const PropertyDetailScreen({super.key, required this.property});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  int _currentImageIndex = 0;
  UserModel? _owner;
  bool _isLoadingOwner = true;
  late PageController _pageController;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  List<String> _currentVideoUrls = [];
  bool _isUploadingVideo = false;
  bool _isUploadingImages = false;
  bool _isInitializingVideo = false;
  int _activeVideoIndex = -1;
  Future<List<ReviewModel>>? _reviewsFuture;
  GoogleMapController? _mapController;


  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _currentVideoUrls = List.from(widget.property.videoUrls);

    _loadOwnerInfo();
    if (_currentVideoUrls.isNotEmpty) {
      _initVideo(0);
    }
    _loadFavorites();
    _loadReviews();
  }

  void _loadReviews() {
    final propertyController = Provider.of<PropertyController>(context, listen: false);
    _reviewsFuture = propertyController.getReviews(widget.property.id!);
  }

  Future<void> _loadFavorites() async {
    final controller = Provider.of<PropertyController>(context, listen: false);
    await controller.loadFavorites();
  }

  Future<void> _initVideo(int videoListIndex) async {
    if (_currentVideoUrls.isEmpty || videoListIndex >= _currentVideoUrls.length) return;
    
    final String videoUrl = _currentVideoUrls[videoListIndex];
    if (mounted) setState(() {
      _isInitializingVideo = true;
      _activeVideoIndex = widget.property.images.length + videoListIndex;
    });

    try {
      if (_chewieController != null) {
        _chewieController!.dispose();
        _chewieController = null;
      }
      if (_videoPlayerController != null) {
        await _videoPlayerController!.dispose();
        _videoPlayerController = null;
      }
      
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

      if (_videoPlayerController != null) {
        await _videoPlayerController!.initialize();
      }

      // Configuration de Chewie
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio > 0 
            ? _videoPlayerController!.value.aspectRatio 
            : 16 / 9,
        placeholder: Container(color: Colors.black, child: const Center(child: CircularProgressIndicator())),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                'Erreur lecteur: $errorMessage', 
                style: const TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Erreur d\'initialisation vidéo: $e');
    } finally {
      if (mounted) setState(() => _isInitializingVideo = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadOwnerInfo() async {
    if (!mounted) return;
    setState(() { _isLoadingOwner = true; });
    final auth = Provider.of<AuthController>(context, listen: false);
    
    if (widget.property.ownerId.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoadingOwner = false;
          _owner = null;
        });
      }
      return;
    }
    
    final owner = await auth.getUserById(widget.property.ownerId);
    if (mounted) {
      setState(() {
        _owner = owner;
        _isLoadingOwner = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    await _loadOwnerInfo();
    if (_currentVideoUrls.isNotEmpty) {
      await _initVideo(0);
    }
    if (mounted) {
      setState(() {
        _loadReviews();
      });
    }
  }

  Future<void> _pickAndAddImages() async {
    final controller = Provider.of<PropertyController>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    
    if (images.isEmpty) return;

    if (!mounted) return;
    setState(() => _isUploadingImages = true);
    messenger.showSnackBar(
      const SnackBar(content: Text('Compression et ajout des images...')),
    );

    try {
      final newImages = await controller.updatePropertyImages(widget.property.id!, images);
      
      if (newImages != null && mounted) {
        setState(() {
          widget.property.images.clear();
          widget.property.images.addAll(newImages);
          _isUploadingImages = false;
        });
        
        // Aller à la dernière image ajoutée
        _pageController.animateToPage(
          newImages.length - 1,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );

        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Photos ajoutées et affichées !')),
          );
        }
      } else {
        if (mounted) {
          setState(() => _isUploadingImages = false);
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Échec de l\'ajout des images.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImages = false);
        messenger.showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'ajout des images.')),
        );
      }
    }
  }

  Future<void> _pickAndAddVideo() async {
    final controller = Provider.of<PropertyController>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;
    
    if (!mounted) return;
    setState(() => _isUploadingVideo = true);
    
    messenger.showSnackBar(
      const SnackBar(content: Text('Compression et envoi de la vidéo en cours...')),
    );

    try {
      final newVideos = await controller.updatePropertyVideo(widget.property.id!, video);
      
      if (newVideos != null && mounted) {
        setState(() {
          _currentVideoUrls = List.from(newVideos);
          widget.property.videoUrls.clear();
          widget.property.videoUrls.addAll(newVideos);
          _isUploadingVideo = false;
        });
        
        // Aller à la dernière vidéo ajoutée
        final totalIndex = widget.property.images.length + _currentVideoUrls.length - 1;
        _pageController.animateToPage(
          totalIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );

        // On initialise la dernière vidéo ajoutée
        await _initVideo(_currentVideoUrls.length - 1);
        
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Vidéo ajoutée et affichée !')),
          );
        }
      } else {
        if (mounted) {
          setState(() => _isUploadingVideo = false);
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Échec de l\'ajout de la vidéo.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout vidéo: $e');
      if (mounted) {
        setState(() => _isUploadingVideo = false);
        messenger.showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'envoi de la vidéo.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _handleRefresh,
            displacement: 80,
            color: AppColors.primaryBlue,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 1. Carousel d'images
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 350,
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: widget.property.images.length + _currentVideoUrls.length + (_isUploadingImages || _isUploadingVideo ? 1 : 0),
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                            
                            final bool isVideoSlide = index >= widget.property.images.length;
                            
                            if (isVideoSlide) {
                              _initVideo(index - widget.property.images.length);
                            } else if (_videoPlayerController != null && _videoPlayerController!.value.isPlaying) {
                              _videoPlayerController!.pause();
                            }
                          },
                          itemBuilder: (context, index) {
                            final bool isVideoSlide = index >= widget.property.images.length;

                            // SI CHARGEMENT EN COURS (Dernier item)
                            if ((_isUploadingImages || _isUploadingVideo) && index == (widget.property.images.length + _currentVideoUrls.length)) {
                              return Container(
                                color: Colors.black,
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(color: Colors.white),
                                      SizedBox(height: 16),
                                      Text('Ajout en cours...', style: TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                ),
                              );
                            }

                            // SI VIDÉO
                            if (isVideoSlide) {
                              final int videoIdx = index - widget.property.images.length;
                              return Container(
                                color: Colors.black,
                                  child: (_isInitializingVideo && _activeVideoIndex == index)
                                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                                  : (_activeVideoIndex == index && _chewieController != null)
                                    ? Chewie(controller: _chewieController!)
                                    : Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.play_circle_outline, color: Colors.white, size: 50),
                                            const SizedBox(height: 10),
                                            Text('Cliquer pour charger la vidéo ${videoIdx + 1}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                              );
                            }

                            // Les photos (index direct car la vidéo est à la fin)
                            final String imageUrl = widget.property.images[index];

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FullScreenImageViewer(
                                      images: widget.property.images,
                                      initialIndex: index,
                                      heroTagPrefix: 'prop_${widget.property.id}',
                                    ),
                                  ),
                                );
                              },
                              child: Hero(
                                tag: 'prop_${widget.property.id}_$index',
                                child: CachedImage(
                                  imageUrl: imageUrl,
                                  width: double.infinity,
                                ),
                              ),
                            );
                          },
                        ),
                        // Flèches de navigation
                        if ((widget.property.images.length + _currentVideoUrls.length) > 1)
                          Positioned.fill(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Flèche Gauche
                                _currentImageIndex > 0
                                    ? IconButton(
                                        icon: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.3),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                                        ),
                                        onPressed: () {
                                          _pageController.previousPage(
                                            duration: const Duration(milliseconds: 300),
                                            curve: Curves.easeInOut,
                                          );
                                        },
                                      )
                                    : const SizedBox(width: 48),
                                // Flèche Droite
                                _currentImageIndex < (widget.property.images.length + _currentVideoUrls.length - 1)
                                    ? IconButton(
                                        icon: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.3),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                                        ),
                                        onPressed: () {
                                          _pageController.nextPage(
                                            duration: const Duration(milliseconds: 300),
                                            curve: Curves.easeInOut,
                                          );
                                        },
                                      )
                                    : const SizedBox(width: 48),
                              ],
                            ),
                          ),
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              widget.property.images.length + _currentVideoUrls.length,
                              (index) => GestureDetector(
                                onTap: () => _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                                child: Container(
                                  width: 8.0,
                                  height: 8.0,
                                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentImageIndex == index ? Colors.white : Colors.white.withOpacity(0.4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Badge "Vidéo" si on est sur une slide de vidéo
                        if (_currentImageIndex >= widget.property.images.length)
                          Positioned(
                            top: 50 + MediaQuery.of(context).padding.top,
                            right: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.play_circle_fill, color: Colors.white, size: 14),
                                  const SizedBox(width: 5),
                                  Text('VIDÉO ${_currentImageIndex - widget.property.images.length + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // 2. Contenu
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        widget.property.category,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.primaryBlue,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const Text(' • ', style: TextStyle(color: Colors.grey)),
                                    Flexible(
                                      child: Text(
                                        widget.property.transactionType,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: widget.property.transactionType == 'Vente' ? AppColors.primaryOrange : AppColors.primaryBlue,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: RichText(
                                textAlign: TextAlign.right,
                                text: TextSpan(
                                  style: const TextStyle(
                                    color: AppColors.primaryOrange,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Roboto',
                                  ),
                                  children: [
                                    TextSpan(text: '${widget.property.price.toInt()} FCFA '),
                                    if (widget.property.transactionType != 'Vente')
                                      TextSpan(
                                        text: '/ ${widget.property.priceDuration.toLowerCase()}',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          children: [
                            Text(
                              widget.property.title,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.titleLarge?.color,
                              ),
                            ),
                            if (widget.property.isCertified)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.purple.withOpacity(0.2)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified_user, color: Colors.purple, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'CERTIFIÉ',
                                      style: TextStyle(
                                        color: Colors.purple,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.orange, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              widget.property.averageRating.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${widget.property.reviewCount} avis)',
                              style: TextStyle(color: AppColors.textLight, fontSize: 14),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => _showReviewSheet(context),
                              icon: const Icon(Icons.rate_review_outlined, size: 18),
                              label: const Text('Noter'),
                              style: TextButton.styleFrom(foregroundColor: AppColors.primaryBlue),
                            ),
                            const Spacer(),
                            const Icon(Icons.favorite, color: Colors.red, size: 20),
                            const SizedBox(width: 4),
                            Consumer<PropertyController>(
                              builder: (context, propCtrl, _) {
                                final count = propCtrl.getLikesCount(widget.property.id!, widget.property.likesCount);
                                return Text(
                                  '$count',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: AppColors.primaryBlue, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              widget.property.quartier,
                              style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7), fontSize: 14),
                            ),
                            const SizedBox(width: 20),
                            if (widget.property.category != 'Boutiques' && widget.property.category != 'Magasins') ...[
                              const Icon(Icons.king_bed, color: AppColors.primaryBlue, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                widget.property.category == 'Terrains' 
                                    ? '${widget.property.pieces} m²'
                                    : '${widget.property.pieces} pièces',
                                style: TextStyle(color: AppColors.textLight, fontSize: 14),
                              ),
                            ],
                          ],
                        ),
                        const Divider(height: 40),
                        Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.property.description,
                          style: TextStyle(
                            fontSize: 15,
                            color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8),
                            height: 1.5,
                          ),
                        ),
                        
                        // NOUVEAU BLOC CONDITIONS
                        if (widget.property.transactionType == 'Location' && (widget.property.rentAdvanceMonths > 0 || widget.property.securityDepositMonths > 0)) ...[
                          const SizedBox(height: 24),
                          Text(
                            'Conditions de location',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.titleLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (widget.property.rentAdvanceMonths > 0)
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBlue.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text('Avance sur loyer', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                                        const SizedBox(height: 4),
                                        Text('${widget.property.rentAdvanceMonths} mois', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                                      ],
                                    ),
                                  ),
                                ),
                              if (widget.property.rentAdvanceMonths > 0 && widget.property.securityDepositMonths > 0)
                                const SizedBox(width: 12),
                              if (widget.property.securityDepositMonths > 0)
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryOrange.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.primaryOrange.withOpacity(0.2)),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text('Caution', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                                        const SizedBox(height: 4),
                                        Text('${widget.property.securityDepositMonths} mois', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryOrange)),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                        
                        const SizedBox(height: 20),
                        const Center(child: BannerAdWidget()),
                        const SizedBox(height: 100), // Espace pour la barre de contact
                        
                        if (widget.property.amenities.isNotEmpty) ...[
                          const Divider(height: 40),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Équipements et services',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.titleLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 60,
                                height: 3,
                                color: Colors.white.withOpacity(0.2), // Simple line
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: widget.property.amenities.map((amenity) {
                              final icon = AmenityUtils.getIcon(amenity);
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: theme.dividerColor),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(icon, size: 20, color: AppColors.primaryBlue),
                                    const SizedBox(width: 8),
                                      Text(
                                        amenity,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: theme.textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 30),

                        // SECTION CARTE — visible uniquement si les coordonnées existent
                        if (widget.property.latitude != null && widget.property.longitude != null) ...[
                          Text(
                            'Emplacement',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.titleLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (kIsWeb)
                            GestureDetector(
                              onTap: _launchNavigation,
                              child: Container(
                                height: 220,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: theme.cardColor,
                                  border: Border.all(color: theme.dividerColor),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.map_outlined, size: 48, color: AppColors.primaryBlue),
                                    const SizedBox(height: 12),
                                    Text(
                                      '${widget.property.latitude!.toStringAsFixed(5)}, ${widget.property.longitude!.toStringAsFixed(5)}',
                                      style: TextStyle(color: AppColors.textLight, fontSize: 13),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      onPressed: _launchNavigation,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryBlue,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      icon: const Icon(Icons.open_in_new, size: 16),
                                      label: const Text('Voir sur Google Maps'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                children: [
                                  SizedBox(
                                    height: 220,
                                    child: GoogleMap(
                                      mapType: MapType.normal,
                                      initialCameraPosition: CameraPosition(
                                        target: LatLng(
                                          widget.property.latitude!,
                                          widget.property.longitude!,
                                        ),
                                        zoom: 15,
                                      ),
                                      markers: {
                                        Marker(
                                          markerId: const MarkerId('property'),
                                          position: LatLng(
                                            widget.property.latitude!,
                                            widget.property.longitude!,
                                          ),
                                          infoWindow: InfoWindow(
                                            title: widget.property.title,
                                            snippet: widget.property.quartier,
                                          ),
                                        ),
                                      },
                                      onMapCreated: (controller) {
                                        _mapController = controller;
                                      },
                                      zoomControlsEnabled: false,
                                      myLocationButtonEnabled: false,
                                      mapToolbarEnabled: true,
                                      scrollGesturesEnabled: true,
                                      zoomGesturesEnabled: true,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 16,
                                    right: 16,
                                    child: ElevatedButton.icon(
                                      onPressed: _launchNavigation,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryBlue,
                                        foregroundColor: Colors.white,
                                        elevation: 4,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      icon: const Icon(Icons.navigation, color: Colors.white, size: 16),
                                      label: const Text(
                                        'Itinéraire',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 30),
                        ],

                        Text(
                          'Avis des clients',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildReviewsList(),
                        const SizedBox(height: 100), // Espace pour la barre de contact
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bouton retour flottant (Nettoyé pour n'avoir qu'un seul bouton)
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

          // Boutons d'action (Partage + Actions propriétaire)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 20,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bouton Partage (Toujours visible)
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

          // Barre de contact fixe en bas
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
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
                   _isLoadingOwner 
                     ? CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey.shade100,
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
                        ),
                      )
                    : CachedAvatar(
                        radius: 30,
                        imageUrl: _owner?.profilePicture,
                        name: _owner?.name ?? widget.property.ownerName ?? '...',
                      ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _isLoadingOwner 
                                  ? (widget.property.ownerName ?? 'Initialisation...') 
                                  : (_owner?.name ?? widget.property.ownerName ?? 'Propriétaire inconnu'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_owner != null && _owner!.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, color: Colors.blue, size: 16),
                            ],
                          ],
                        ),
                        Text(
                          'Propriétaire',
                          style: TextStyle(color: AppColors.textLight, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Boutons de contact
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
                      
                      final ownerId = _owner?.id;
                      final ownerName = _owner?.name;

                      // Si l'utilisateur est le PROPRIÉTAIRE de l'annonce
                      if (currentUser.id == ownerId) {
                         // On le redirige vers sa liste de discussions (Inbox)
                         Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChatListScreen()),
                        );
                      } else if (ownerId != null && ownerName != null) {
                        // Sinon (Locataire), on ouvre le chat avec le propriétaire
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatDetailScreen(
                              otherUserId: ownerId,
                              otherUserName: ownerName,
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
                        boxShadow: isDark ? [] : [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Consumer<AuthController>(
                        builder: (context, auth, _) => Icon(
                          Icons.chat_bubble_outline, 
                          color: auth.currentUser?.id == _owner?.id 
                              ? AppColors.primaryOrange 
                              : AppColors.primaryBlue
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      final phone = _owner?.phone ?? widget.property.ownerPhone;
                      final name = _owner?.name ?? widget.property.ownerName ?? 'le propriétaire';
                      if (phone != null && phone.isNotEmpty) {
                         _showContactOptions(context, phone, name);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Aucun numéro de téléphone disponible.')),
                        );
                      }
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
            ),
          ),
        ],
      ),
    );
  }


  void _showContactOptions(BuildContext context, String phoneNumber, String name) {

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
                  'Contacter $name',
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
                      path: phoneNumber,
                    );
                    try {
                      if (await canLaunchUrl(launchUri)) {
                        await launchUrl(launchUri);
                      } else {
                        throw 'Impossible';
                      }
                    } catch (e) {
                       if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Impossible de lancer l\'appel.')),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withOpacity(0.1), // WhatsApp Green
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.message, color: Color(0xFF25D366)), 
                  ),
                  title: const Text('WhatsApp'),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(context);
                    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), ''); 
                    final Uri whatsappUri = Uri.parse('https://wa.me/$cleanNumber');
                    
                    try {
                      if (await canLaunchUrl(whatsappUri)) {
                        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
                      } else {
                         throw 'Impossible';
                      }
                    } catch (e) {
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Impossible d\'ouvrir WhatsApp.')),
                        );
                      }
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

    // Utilisation de google.navigation pour forcer le mode navigation
    // C'est beaucoup plus précis que geo: ou search: à l'arrivée
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

  Widget _buildReviewsList() {
    return FutureBuilder<List<ReviewModel>>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) {
          debugPrint('Erreur d\'affichage des avis: ${snapshot.error}');
          return Text('Erreur: ${snapshot.error}');
        }
        
        final reviews = snapshot.data ?? [];
        if (reviews.isEmpty) return const Text('Aucun avis pour le moment.');

        return Column(
          children: reviews.map((review) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CachedAvatar(
                imageUrl: review.userProfilePicture,
                name: review.userName,
                radius: 20,
              ),
              title: Row(
                children: [
                   Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                   const Spacer(),
                   Row(
                     children: List.generate(5, (index) => Icon(
                       Icons.star, 
                       size: 14, 
                       color: index < review.rating ? Colors.orange : Colors.grey[300],
                     )),
                   ),
                ],
              ),
              subtitle: Text(review.comment),
            );
          }).toList(),
        );
      },
    );
  }
}

