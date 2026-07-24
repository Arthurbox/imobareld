import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/core/constants/app_colors.dart';
import 'package:imobareld/features/auth/auth_controller.dart';
import 'package:imobareld/features/home/property_controller.dart';
import 'package:imobareld/models/property_model.dart';
import 'package:imobareld/core/utils/amenity_utils.dart';
import 'package:imobareld/core/constants/bf_locations.dart';
import 'package:imobareld/features/home/location_picker_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
class AddPropertyScreen extends StatefulWidget {
  final PropertyModel? propertyToEdit;
  const AddPropertyScreen({super.key, this.propertyToEdit});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _piecesController = TextEditingController();
  final _rentAdvanceController = TextEditingController();
  final _securityDepositController = TextEditingController();
  
  String _selectedCategory = 'Appartement';
  String _selectedCity = 'Ouagadougou';
  String _selectedQuartier = 'Ouaga 2000';
  String _selectedPeriod = 'mois'; // 'mois' ou 'jour'
  String _selectedTransactionType = 'Location'; // 'Location' ou 'Vente'
  bool _isAddingOther = false;
  final _newQuartierController = TextEditingController();
  final List<XFile> _selectedImages = [];
  final Map<String, Uint8List> _selectedImageBytes = {}; // Stockage des octets pour prévisualisation
  final List<XFile> _selectedVideos = [];
  List<String> _existingImages = []; 
  final List<String> _existingVideos = [];
  final ImagePicker _picker = ImagePicker();
  static const int _maxMediaTotal = 20;
  LatLng? _selectedLocation;

  List<String> _selectedAmenities = [];

  final List<String> _categories = ['Appartement','Cours Uniques','Cours Communes', 'Magasins', 'Boutiques','Terrains'];
  
  List<String> get _availableQuartiers => BfLocations.quartiersOf(_selectedCity);

  List<String> get _currentAvailableAmenities {
    if (_selectedCategory == 'Cours Communes') {
      return ['Sonabel', 'ONEA'];
    }
    if (_selectedCategory == 'Cours Uniques') {
      return ['Wifi', 'Climatisation', 'Piscine', 'Eau chaude', 'Sonabel', 'ONEA'];
    }
    return [
      'Wifi', 'Climatisation', 'Piscine', 'Eau chaude', 'Parking', 
      'Netflix', 'Canal+', 'Gaz', 'Frigo', 'Micro-ondes', 'Sécurité 24/7',
      'Sonabel', 'ONEA'
    ];
  }

  @override
  void initState() {
    super.initState();
    if (widget.propertyToEdit != null) {
      final p = widget.propertyToEdit!;
      _titleController.text = p.title;
      _descController.text = p.description;
      _priceController.text = p.price.toStringAsFixed(0);
      _piecesController.text = p.pieces.toString();
      _selectedCategory = _categories.contains(p.category) ? p.category : _categories.first;
      _selectedPeriod = p.priceDuration;
      _selectedTransactionType = p.transactionType;
      _selectedAmenities = List.from(p.amenities);
      _rentAdvanceController.text = p.rentAdvanceMonths > 0 ? p.rentAdvanceMonths.toString() : '';
      _securityDepositController.text = p.securityDepositMonths > 0 ? p.securityDepositMonths.toString() : '';

      _selectedCity = BfLocations.cities.contains(p.city) ? p.city : BfLocations.cities.first;
      final quartiers = BfLocations.quartiersOf(_selectedCity);
      if (quartiers.contains(p.quartier)) {
        _selectedQuartier = p.quartier;
        _isAddingOther = false;
      } else if (p.quartier.isNotEmpty) {
        _isAddingOther = true;
        _selectedQuartier = quartiers.isNotEmpty ? quartiers.first : '';
        _newQuartierController.text = p.quartier;
      } else {
        _selectedQuartier = quartiers.isNotEmpty ? quartiers.first : '';
      }
      _existingImages = List.from(p.images);
      _existingVideos.clear();
      _existingVideos.addAll(p.videoUrls);
      
      if (p.latitude != null && p.longitude != null) {
        _selectedLocation = LatLng(p.latitude!, p.longitude!);
      }
    }
  }

  Future<void> _pickImages() async {
    final int currentTotal = _selectedImages.length + _existingImages.length + _selectedVideos.length + _existingVideos.length;
    if (currentTotal >= _maxMediaTotal) {
      _showLimitReached();
      return;
    }

    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      for (var image in images) {
        if (_selectedImages.length + _existingImages.length + _selectedVideos.length + _existingVideos.length >= _maxMediaTotal) break;
        final bytes = await image.readAsBytes();
        _selectedImageBytes[image.path] = bytes;
        _selectedImages.add(image);
      }
      setState(() {});
    }
  }

  Future<void> _pickImageFromCamera() async {
    if (_selectedImages.length + _existingImages.length + _selectedVideos.length + _existingVideos.length >= _maxMediaTotal) {
      _showLimitReached();
      return;
    }
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes[image.path] = bytes;
        _selectedImages.add(image);
      });
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    if (_selectedImages.length + _existingImages.length + _selectedVideos.length + _existingVideos.length >= _maxMediaTotal) {
      _showLimitReached();
      return;
    }
    final XFile? video = await _picker.pickVideo(source: source);
    if (video != null) {
      setState(() {
        _selectedVideos.add(video);
      });
    }
  }

  void _showLimitReached() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Limite de 20 médias atteinte.'), backgroundColor: Colors.orange),
    );
  }

  void _showMediaPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primaryBlue),
              title: const Text('Galerie Photos'),
              onTap: () {
                Navigator.pop(context);
                _pickImages();
              },
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primaryBlue),
                title: const Text('Prendre une Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
            ListTile(
              leading: const Icon(Icons.video_library, color: Colors.red),
              title: const Text('Galerie Vidéos'),
              onTap: () {
                Navigator.pop(context);
                _pickVideo(ImageSource.gallery);
              },
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.red),
                title: const Text('Enregistrer une Vidéo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(ImageSource.camera);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitFormat() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty && _existingImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter au moins une image')),
      );
      return;
    }

    final auth = Provider.of<AuthController>(context, listen: false);
    final propertyCtrl = Provider.of<PropertyController>(context, listen: false);

    try {
      final List<String> uploadedUrls = await propertyCtrl.compressAndUploadImages(_selectedImages);

      final List<String> uploadedVideoUrls = [];
      for (var v in _selectedVideos) {
        final url = await propertyCtrl.compressAndUploadVideo(v);
        if (url != null) uploadedVideoUrls.add(url);
      }

      if ((uploadedUrls.isEmpty && _selectedImages.isNotEmpty) || (uploadedVideoUrls.isEmpty && _selectedVideos.isNotEmpty)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du téléchargement des médias')),
        );
        return;
      }

      String quartierFinal = _isAddingOther ? _newQuartierController.text.trim() : _selectedQuartier;
      String cityFinal = _selectedCity;
      
      if (_isAddingOther && quartierFinal.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez saisir le nom du quartier')),
        );
        return;
      }

      List<String> finalImages = [..._existingImages, ...uploadedUrls];
      List<String> finalVideos = [..._existingVideos, ...uploadedVideoUrls];

      int totalSize = 0;
      for (var img in finalImages) {
        totalSize += img.length;
      }

      if (totalSize > 10000000) { // Limite augmentée à 10 Mo pour Django
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Les images sont trop volumineuses (${(totalSize / (1024 * 1024)).toStringAsFixed(1)} Mo). maximum 10 Mo.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      bool success;
      if (widget.propertyToEdit != null) {
        PropertyModel updatedProperty = PropertyModel(
            id: widget.propertyToEdit!.id,
            ownerId: widget.propertyToEdit!.ownerId,
            title: _titleController.text,
            description: _descController.text,
            category: _selectedCategory,
            price: double.parse(_priceController.text),
            city: cityFinal,
            quartier: quartierFinal,
            images: finalImages,
            videoUrls: finalVideos,
            pieces: (_selectedCategory == 'Boutiques' || _selectedCategory == 'Magasins') ? 0 : (int.tryParse(_piecesController.text) ?? 0),
            createdAt: widget.propertyToEdit!.createdAt,
            latitude: _selectedLocation?.latitude,
            longitude: _selectedLocation?.longitude,
            isOwnerVerified: widget.propertyToEdit!.isOwnerVerified,            priceDuration: _selectedPeriod,
            transactionType: _selectedTransactionType,
            amenities: (_selectedCategory == 'Appartement' || _selectedCategory == 'Cours Uniques' || _selectedCategory == 'Cours Communes') ? _selectedAmenities : [],
            rentAdvanceMonths: _selectedTransactionType == 'Location' ? (int.tryParse(_rentAdvanceController.text) ?? 0) : 0,
            securityDepositMonths: _selectedTransactionType == 'Location' ? (int.tryParse(_securityDepositController.text) ?? 0) : 0,
        );
        success = await propertyCtrl.updateProperty(updatedProperty);
      } else {
        PropertyModel newProperty = PropertyModel(
          ownerId: auth.currentUser!.id,
          title: _titleController.text,
          description: _descController.text,
          category: _selectedCategory,
          price: double.parse(_priceController.text),
          city: cityFinal,
          quartier: quartierFinal,
          images: finalImages,
          videoUrls: finalVideos,
          pieces: (_selectedCategory == 'Boutiques' || _selectedCategory == 'Magasins') ? 0 : (int.tryParse(_piecesController.text) ?? 0),
          createdAt: DateTime.now(),
          latitude: _selectedLocation?.latitude,
          longitude: _selectedLocation?.longitude,
          isOwnerVerified: auth.currentUser!.isVerified,          priceDuration: _selectedPeriod,
          transactionType: _selectedTransactionType,
          amenities: (_selectedCategory == 'Appartement' || _selectedCategory == 'Cours Uniques' || _selectedCategory == 'Cours Communes') ? _selectedAmenities : [],
          rentAdvanceMonths: _selectedTransactionType == 'Location' ? (int.tryParse(_rentAdvanceController.text) ?? 0) : 0,
          securityDepositMonths: _selectedTransactionType == 'Location' ? (int.tryParse(_securityDepositController.text) ?? 0) : 0,
        );
        success = await propertyCtrl.addProperty(newProperty);
      }

      if (success) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.propertyToEdit != null ? 'Annonce modifiée !' : 'Annonce publiée !')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la publication.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Erreur lors de la publication: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.propertyToEdit != null ? 'Modifier l\'annonce' : 'Publier une annonce'),
        foregroundColor: AppColors.primaryBlue,
        elevation: 0,
      ),
      body: Consumer<PropertyController>(
        builder: (context, propertyCtrl, _) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Form(
                      key: _formKey,
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Photos & Vidéos du bien', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Text('Jusqu\'à 20 médias au total (Photos/Vidéos)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 110,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            GestureDetector(
                              onTap: _showMediaPickerOptions,
                              child: Container(
                                width: 100,
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo, color: AppColors.primaryBlue),
                                    SizedBox(height: 4),
                                    Text('Ajouter', style: TextStyle(fontSize: 12, color: AppColors.primaryBlue)),
                                  ],
                                ),
                              ),
                            ),
                            // -- PHOTOS EXISTANTES --
                            ..._existingImages.map((imgUrl) => _buildMediaThumbnail(
                              url: imgUrl, 
                              onDelete: () => setState(() => _existingImages.remove(imgUrl))
                            )),
                            
                            // -- VIDÉOS EXISTANTES --
                            ..._existingVideos.map((videoUrl) => _buildMediaThumbnail(
                              url: videoUrl, 
                              isVideo: true,
                              onDelete: () => setState(() => _existingVideos.remove(videoUrl))
                            )),

                            // -- NOUVELLES PHOTOS --
                            ..._selectedImages.map((file) => _buildMediaThumbnail(
                              file: file, 
                              onDelete: () => setState(() {
                                _selectedImageBytes.remove(file.path);
                                _selectedImages.remove(file);
                              })
                            )),

                            // -- NOUVELLES VIDÉOS --
                            ..._selectedVideos.map((file) => _buildMediaThumbnail(
                              file: file, 
                              isVideo: true,
                              onDelete: () => setState(() => _selectedVideos.remove(file))
                            )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Titre de l\'annonce', border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Requis' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Prix', 
                                hintText: 'FCFA',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                              validator: (v) => v!.isEmpty ? 'Requis' : null,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (_selectedCategory == 'Boutiques' || _selectedCategory == 'Magasins')
                            Expanded(
                              flex: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.grey.shade50,
                                ),
                                child: const Text(
                                  '/ mois',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          else if (_selectedTransactionType == 'Location')
                            Expanded(
                              flex: 4,
                              child: DropdownButtonFormField<String>(
                                value: _selectedPeriod.toLowerCase(),
                                isExpanded: true,
                                items: ['mois', 'jour'].map((p) => DropdownMenuItem(
                                  value: p, 
                                  child: Text('/ $p', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                )).toList(),
                                onChanged: (v) => setState(() => _selectedPeriod = v!),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(), 
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                ),
                              ),
                            ),
                          const SizedBox(width: 6),
                          if (_selectedCategory != 'Boutiques' && _selectedCategory != 'Magasins')
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _piecesController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: _selectedCategory == 'Terrains' ? 'Superficie (m2)' : 'Pièces', 
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                                validator: (v) {
                                  if (_selectedCategory == 'Boutiques' || _selectedCategory == 'Magasins') return null;
                                  return (v == null || v.isEmpty) ? 'Requis' : null;
                                },
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              isExpanded: true,
                              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _selectedCategory = v;
                                    if (v == 'Boutiques' || v == 'Magasins') _selectedPeriod = 'mois';
                                    if (v != 'Terrains') _selectedTransactionType = 'Location';
                                    if (v != 'Appartement' && v != 'Cours Uniques' && v != 'Cours Communes') _selectedAmenities = [];
                                  });
                                }
                              },
                              decoration: const InputDecoration(labelText: 'Catégorie', border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCity,
                              isExpanded: true,
                              items: BfLocations.cities.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  final newQuartiers = BfLocations.quartiersOf(v);
                                  setState(() {
                                    _selectedCity = v;
                                    _isAddingOther = false;
                                    _selectedQuartier = newQuartiers.isNotEmpty ? newQuartiers.first : '';
                                  });
                                }
                              },
                              decoration: const InputDecoration(labelText: 'Ville', border: OutlineInputBorder()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _isAddingOther 
                        ? TextFormField(
                            controller: _newQuartierController,
                            decoration: InputDecoration(
                              labelText: 'Nouveau quartier', 
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => setState(() {
                                  _isAddingOther = false;
                                  _selectedQuartier = _availableQuartiers.isNotEmpty ? _availableQuartiers.first : '';
                                }),
                              ),
                            ),
                            validator: (v) => _isAddingOther && (v == null || v.isEmpty) ? 'Requis' : null,
                          )
                        : DropdownButtonFormField<String>(
                            value: _availableQuartiers.contains(_selectedQuartier) ? _selectedQuartier : (_availableQuartiers.isNotEmpty ? _availableQuartiers.first : null),
                            isExpanded: true,
                            items: [
                              ..._availableQuartiers.map((q) => DropdownMenuItem(value: q, child: Text(q, overflow: TextOverflow.ellipsis))),
                              const DropdownMenuItem(value: '__other__', child: Text('Autre (Saisir...)')),
                            ],
                            onChanged: (v) {
                              if (v == '__other__') {
                                setState(() => _isAddingOther = true);
                              } else {
                                setState(() {
                                  _isAddingOther = false;
                                  _selectedQuartier = v!;
                                });
                              }
                            },
                            decoration: const InputDecoration(labelText: 'Quartier', border: OutlineInputBorder()),
                          ),
                      const SizedBox(height: 16),
                      if (_selectedCategory == 'Terrains') ...[
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 8),
                          child: Text('Type de transaction', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text('À Louer')),
                                selected: _selectedTransactionType == 'Location',
                                onSelected: (selected) {
                                  if (selected) setState(() => _selectedTransactionType = 'Location');
                                },
                                selectedColor: AppColors.primaryBlue.withOpacity(0.2),
                                backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.grey.shade100,
                                labelStyle: TextStyle(
                                  color: _selectedTransactionType == 'Location' ? AppColors.primaryBlue : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87),
                                  fontWeight: _selectedTransactionType == 'Location' ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text('À Vendre')),
                                selected: _selectedTransactionType == 'Vente',
                                onSelected: (selected) {
                                  if (selected) setState(() => _selectedTransactionType = 'Vente');
                                },
                                selectedColor: AppColors.primaryOrange.withOpacity(0.2),
                                backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.grey.shade100,
                                labelStyle: TextStyle(
                                  color: _selectedTransactionType == 'Vente' ? AppColors.primaryOrange : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87),
                                  fontWeight: _selectedTransactionType == 'Vente' ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _descController,
                        maxLines: 4,
                        decoration: const InputDecoration(labelText: 'Description détaillée', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      if (_selectedTransactionType == 'Location') ...[
                        const Text('Conditions de location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _rentAdvanceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Avance sur loyer',
                                  suffixText: 'mois',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) {
                                  if (v != null && v.isNotEmpty && int.tryParse(v) == null) return 'Entier valide requis';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _securityDepositController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Caution',
                                  suffixText: 'mois',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) {
                                  if (v != null && v.isNotEmpty && int.tryParse(v) == null) return 'Entier valide requis';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (_selectedCategory == 'Appartement' || _selectedCategory == 'Cours Uniques' || _selectedCategory == 'Cours Communes') ...[
                        const Text('Équipements et services', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _currentAvailableAmenities.map((amenity) {
                            final isSelected = _selectedAmenities.contains(amenity);
                            final icon = AmenityUtils.getIcon(amenity);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) _selectedAmenities.remove(amenity);
                                  else _selectedAmenities.add(amenity);
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primaryBlue : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300),
                                  boxShadow: isSelected ? [BoxShadow(color: AppColors.primaryBlue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey[600]),
                                    const SizedBox(width: 8),
                                    Text(
                                      amenity,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.grey[800],
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final LatLng? location = await Navigator.push<LatLng>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LocationPickerScreen(
                                initialLocation: _selectedLocation,
                              ),
                            ),
                          );
                          if (location != null) {
                            setState(() => _selectedLocation = location);
                          }
                        },
                        icon: const Icon(Icons.map_outlined),
                        label: Text(
                          _selectedLocation == null
                              ? 'Ajouter un Emplacement sur la carte'
                              : 'Emplacement sélectionné ✓',
                          style: TextStyle(
                            color: _selectedLocation == null ? AppColors.textLight : Colors.green,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          side: BorderSide(
                            color: _selectedLocation == null ? AppColors.border : Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: propertyCtrl.isLoading ? null : _submitFormat,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: propertyCtrl.isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('PUBLIER L\'ANNONCE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
               ),
              ),
              ),
              if (propertyCtrl.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
  Widget _buildMediaThumbnail({String? url, XFile? file, bool isVideo = false, required VoidCallback onDelete}) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 10),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 100,
              height: 100,
              color: isVideo ? Colors.black87 : Colors.grey[200],
              child: url != null 
                ? (isVideo 
                    ? const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 40))
                    : Image.network(url, width: 100, height: 100, fit: BoxFit.cover))
                : (file != null 
                    ? (isVideo 
                        ? const Center(child: Icon(Icons.video_library, color: Colors.white, size: 40))
                        : (_selectedImageBytes.containsKey(file.path)
                            ? Image.memory(_selectedImageBytes[file.path]!, width: 100, height: 100, fit: BoxFit.cover)
                            : const Center(child: CircularProgressIndicator())))
                    : const SizedBox()),
            ),
          ),
          if (isVideo)
            Positioned(
              bottom: 5,
              left: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                child: const Text('Vidéo', style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: onDelete,
              child: const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.red,
                child: Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

