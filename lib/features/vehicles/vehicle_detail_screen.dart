import 'package:flutter/material.dart';
import 'package:imobareld/core/widgets/cached_avatar.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/core/constants/app_colors.dart';
import 'package:imobareld/models/vehicle_model.dart';
import 'package:imobareld/models/reservation_model.dart';
import 'package:imobareld/features/vehicles/rental_controller.dart';
import 'package:imobareld/features/auth/auth_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'package:imobareld/core/widgets/full_screen_image_viewer.dart';
import 'package:imobareld/models/user_model.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:imobareld/features/chat/chat_list_screen.dart';
import 'package:imobareld/features/chat/chat_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:imobareld/core/widgets/cached_image.dart';
import 'package:imobareld/core/utils/share_utils.dart';
class VehicleDetailScreen extends StatefulWidget {
  final VehicleModel vehicle;

  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  UserModel? _owner;
  bool _isLoadingOwner = false;

  // Carousel & Video
  late PageController _pageController;
  int _currentImageIndex = 0;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitializingVideo = false;
  int _activeVideoIndex = -1;

  // Options de location
  bool _withDriver = false;
  int _numberOfDays = 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadOwnerInfo();
    
    if (widget.vehicle.videoUrls.isNotEmpty) {
      _initVideo(0);
    }
  }

  Future<void> _initVideo(int videoListIndex) async {
    if (widget.vehicle.videoUrls.isEmpty || videoListIndex >= widget.vehicle.videoUrls.length) return;
    
    final String videoUrl = widget.vehicle.videoUrls[videoListIndex];
    if (mounted) setState(() {
      _isInitializingVideo = true;
      _activeVideoIndex = widget.vehicle.images.length + videoListIndex;
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

      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio > 0 
            ? _videoPlayerController!.value.aspectRatio 
            : 16 / 9,
        placeholder: Container(color: Colors.black, child: const Center(child: CircularProgressIndicator())),
      );
    } catch (e) {
      debugPrint('Erreur d\'initialisation vidéo véhicule: $e');
    } finally {
      if (mounted) setState(() => _isInitializingVideo = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _loadOwnerInfo() async {
    if (!mounted) return;
    setState(() { _isLoadingOwner = true; });
    final auth = Provider.of<AuthController>(context, listen: false);
    
    if (widget.vehicle.ownerId.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoadingOwner = false;
          _owner = null;
        });
      }
      return;
    }
    
    final owner = await auth.getUserById(widget.vehicle.ownerId);
    if (mounted) {
      setState(() {
        _owner = owner;
        _isLoadingOwner = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    await _loadOwnerInfo();
    if (widget.vehicle.videoUrls.isNotEmpty) {
      await _initVideo(0);
    }
    if (mounted) setState(() {});
  }

  // Documents
  XFile? _cnibiImage; // Recto
  XFile? _cnibBackImage; // Verso
  XFile? _licenseImage;
  final ImagePicker _picker = ImagePicker();

  // Calcul du prix
  double get _totalPrice {
    double basePrice = widget.vehicle.pricePerDay * _numberOfDays;
    double driverCost = _withDriver ? (5000.0 * _numberOfDays) : 0.0;
    return basePrice + driverCost;
  }

  Future<void> _pickDocument(String docType) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (docType == 'cnib_recto') {
          _cnibiImage = image;
        } else if (docType == 'cnib_verso') {
          _cnibBackImage = image;
        } else {
          _licenseImage = image;
        }
      });
    }
  }


  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_cnibiImage == null || _cnibBackImage == null || _licenseImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez joindre tous vos documents (CNIB Recto, Verso et Permis)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authController = Provider.of<AuthController>(context, listen: false);
    final rentalController =
        Provider.of<RentalController>(context, listen: false);
    final currentUser = authController.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté pour faire une réservation.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Téléchargement des documents (Multipart)
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vérification et envoi des documents...')),
    );

    final List<String> uploadedUrls = await rentalController.compressAndUploadImages([
      _cnibiImage!,
      _cnibBackImage!,
      _licenseImage!,
    ]);

    if (uploadedUrls.length < 3) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Erreur lors du téléchargement des documents.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final reservation = ReservationModel(
      vehicleId: widget.vehicle.id,
      vehicleModel: widget.vehicle.model,
      vehicleCompanyName: widget.vehicle.companyName,
      ownerId: widget.vehicle.ownerId,
      userId: currentUser.id,
      userName: currentUser.name,
      userEmail: currentUser.email,
      userPhone: currentUser.phone,
      numberOfDays: _numberOfDays,
      withDriver: _withDriver,
      totalPrice: _totalPrice,
      cnibImage: uploadedUrls[0],
      cnibBackImage: uploadedUrls[1],
      licenseImage: uploadedUrls[2],
      createdAt: DateTime.now(),
    );

    final success = await rentalController.submitReservation(reservation);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Demande de location envoyée avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '❌ Erreur lors de l\'envoi. Vérifiez votre connexion et réessayez.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rentalController = Provider.of<RentalController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Détails du véhicule"),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => ShareUtils.shareVehicle(widget.vehicle),
            tooltip: 'Partager ce véhicule',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        displacement: 20,
        color: AppColors.primaryBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. CAROUSEL MÉDIAS
              Stack(
                children: [
                  SizedBox(
                    height: 300,
                    width: double.infinity,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                        
                        // Si on arrive sur une vidéo, on l'initialise
                        if (index >= widget.vehicle.images.length) {
                          _initVideo(index - widget.vehicle.images.length);
                        }
                      },
                      itemCount: widget.vehicle.images.length + widget.vehicle.videoUrls.length,
                      itemBuilder: (context, index) {
                        if (index < widget.vehicle.images.length) {
                          // Section Image
                          final imageUrl = widget.vehicle.images[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullScreenImageViewer(
                                    images: widget.vehicle.images,
                                    initialIndex: index,
                                    heroTagPrefix: 'vehicle_${widget.vehicle.id}',
                                  ),
                                ),
                              );
                            },
                            child: Hero(
                              tag: 'vehicle_${widget.vehicle.id}_$index',
                              child: CachedImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 300,
                              ),
                            ),
                          );
                        } else {
                          // Section Vidéo
                          final videoIndex = index - widget.vehicle.images.length;
                          return Container(
                            height: 300,
                            color: Colors.black,
                            child: _activeVideoIndex == index && _chewieController != null && !_isInitializingVideo
                                ? Chewie(controller: _chewieController!)
                                : Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      const Icon(Icons.play_circle_outline, color: Colors.white, size: 80),
                                      if (_isInitializingVideo && _activeVideoIndex == index)
                                        const CircularProgressIndicator(color: Colors.white),
                                      if (_activeVideoIndex != index)
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () => _initVideo(videoIndex),
                                            child: const SizedBox.expand(),
                                          ),
                                        ),
                                    ],
                                  ),
                          );
                        }
                      },
                    ),
                  ),
                  
                  // Indicateur de page
                  if (widget.vehicle.images.length + widget.vehicle.videoUrls.length > 1)
                    Positioned(
                      bottom: 15,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.vehicle.images.length + widget.vehicle.videoUrls.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == index
                                  ? AppColors.primaryBlue
                                  : Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  // Badge type média
                  Positioned(
                    top: 15,
                    right: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _currentImageIndex < widget.vehicle.images.length 
                          ? '${_currentImageIndex + 1}/${widget.vehicle.images.length}'
                          : 'Vidéo ${(_currentImageIndex - widget.vehicle.images.length) + 1}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. INFOS CLÉS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.vehicle.companyName.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.indigo,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.vehicle.model,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primaryBlue),
                          ),
                          child: Column(
                            children: [
                              Text(
                                "${widget.vehicle.pricePerDay.toStringAsFixed(0)} F",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              const Text(
                                "/ jour",
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 3. CONDITIONS
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E1E2A)
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: isDark
                                ? Colors.white24
                                : Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "CONDITIONS DE LOCATION",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.vehicle.description.isNotEmpty
                                ? widget.vehicle.description
                                : "• Permis de conduire valide obligatoire.\n• Caution requise.\n• Carburant à la charge du locataire.",
                            style: TextStyle(
                                color: Colors.grey[800], height: 1.5),
                          ),
                        ],
                      ),
                    ),

                    // 4. FORMULAIRE DE RÉSERVATION
                    const Text(
                      "Formulaire de Réservation",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cursive'),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E2A) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: isDark
                                ? Colors.indigo.shade700
                                : Colors.indigo.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo
                                .withValues(alpha: isDark ? 0.15 : 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Option Chauffeur
                            Text("Type de location",
                                style: TextStyle(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.bold)),
                            RadioGroup<bool>(
                              groupValue: _withDriver,
                              onChanged: (val) => setState(() => _withDriver = val!),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: RadioListTile<bool>(
                                      title: const Text("Sans chauffeur",
                                          style: TextStyle(fontSize: 14)),
                                      value: false,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  Expanded(
                                    child: RadioListTile<bool>(
                                      title: const Text("Avec chauffeur",
                                          style: TextStyle(fontSize: 14)),
                                      value: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_withDriver)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: Text(
                                  "5000 FCFA / jour pour le chauffeur",
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange,
                                      fontStyle: FontStyle.italic),
                                ),
                              ),

                            const SizedBox(height: 20),

                            // Nombre de jours
                            TextFormField(
                              initialValue: "1",
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "Nombre de jours",
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                              ),
                              validator: (val) {
                                final n = int.tryParse(val ?? '');
                                if (n == null || n < 1) {
                                  return 'Entrez un nombre de jours valide';
                                }
                                return null;
                              },
                              onChanged: (val) {
                                setState(() {
                                  _numberOfDays = int.tryParse(val) ?? 1;
                                });
                              },
                            ),

                            const SizedBox(height: 20),

                            // Total
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primaryBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("PRIX TOTAL ESTIMÉ :",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                    "${_totalPrice.toStringAsFixed(0)} FCFA",
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primaryBlue),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Documents
                            const Text("Documents à joindre",
                                style:
                                    TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),

                            _buildDocUploader("CNIB (Recto)",
                                _cnibiImage, () => _pickDocument('cnib_recto')),
                            const SizedBox(height: 12),
                            _buildDocUploader("CNIB (Verso)",
                                _cnibBackImage, () => _pickDocument('cnib_verso')),
                            const SizedBox(height: 12),
                            _buildDocUploader("Permis de conduire",
                                _licenseImage, () => _pickDocument('license')),

                            const SizedBox(height: 30),

                            // Bouton Envoyer
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: rentalController.isLoading
                                    ? null
                                    : _submitRequest,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                ),
                                child: rentalController.isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text("ENVOYER",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // SECTION CONTACT PROPRIÉTAIRE
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E1E2A) : Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    offset: const Offset(0, -5),
                                    blurRadius: 10,
                                  ),
                                ],
                                borderRadius: const BorderRadius.all(Radius.circular(20)),
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
                                      name: _isLoadingOwner ? '...' : (_owner?.name ?? 'Propriétaire'),
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
                                                _isLoadingOwner ? 'Chargement...' : (_owner?.name ?? 'Propriétaire inconnu'),
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
                                          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Bouton Chat
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
                                      if (currentUser.id == ownerId) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const ChatListScreen()),
                                        );
                                      } else if (ownerId != null && ownerName != null) {
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
                                        color: isDark ? Colors.grey.shade800 : Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryOrange, size: 24),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Bouton Appel
                                  GestureDetector(
                                    onTap: () async {
                                      final phone = _owner?.phone;
                                      if (phone != null && phone.isNotEmpty) {
                                        final uri = Uri.parse('tel:$phone');
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri);
                                        } else {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Impossible de lancer l\'appel.')),
                                          );
                                        }
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Numéro de téléphone non disponible.')),
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: const BoxDecoration(
                                        color: AppColors.primaryBlue,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.phone, color: Colors.white, size: 24),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocUploader(
      String label, XFile? file, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
              color: Colors.grey.shade400, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(12),
          color: file != null
              ? Colors.green.withValues(alpha: 0.1)
              : (isDark ? const Color(0xFF2C2C2C) : Colors.white),
        ),
        child: Row(
          children: [
            Icon(
              file != null
                  ? Icons.check_circle
                  : Icons.cloud_upload_outlined,
              color: file != null ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                file != null ? "$label ajouté" : "Ajouter $label",
                style: TextStyle(
                  color: file != null
                      ? Colors.green[800]
                      : (isDark ? Colors.white70 : Colors.grey[700]),
                  fontWeight:
                      file != null ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (file != null)
              const Icon(Icons.edit, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

