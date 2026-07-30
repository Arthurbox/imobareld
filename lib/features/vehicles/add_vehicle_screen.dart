import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:imobareld/features/vehicles/vehicle_controller.dart';
import 'package:imobareld/models/vehicle_model.dart';
import 'package:imobareld/features/auth/auth_controller.dart';
import 'package:imobareld/core/constants/app_colors.dart';
import 'package:imobareld/core/constants/bf_locations.dart';

class AddVehicleScreen extends StatefulWidget {
  final VehicleModel? vehicleToEdit;
  const AddVehicleScreen({super.key, this.vehicleToEdit});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late final TextEditingController _companyController;
  late final TextEditingController _modelController;
  late final TextEditingController _priceController;
  late final TextEditingController _descController;

  // Media
  final List<XFile> _selectedImages = [];
  final List<XFile> _selectedVideos = [];
  final Map<String, Uint8List> _selectedImageBytes = {};
  List<String> _existingImages = [];
  List<String> _existingVideos = [];
  final int _maxMediaTotal = 20;

  final ImagePicker _picker = ImagePicker();
  
  // City
  String _selectedCity = 'Ouagadougou';

  @override
  void initState() {
    super.initState();
    _companyController = TextEditingController(text: widget.vehicleToEdit?.companyName);
    _modelController = TextEditingController(text: widget.vehicleToEdit?.model);
    _priceController = TextEditingController(
      text: widget.vehicleToEdit != null 
          ? widget.vehicleToEdit!.pricePerDay.toStringAsFixed(0) 
          : ''
    );
    _descController = TextEditingController(text: widget.vehicleToEdit?.description);
    _selectedCity = widget.vehicleToEdit?.city ?? 'Ouagadougou';

    if (widget.vehicleToEdit != null) {
      _existingImages = List.from(widget.vehicleToEdit!.images);
      _existingVideos = List.from(widget.vehicleToEdit!.videoUrls);
    }
  }

  @override
  void dispose() {
    _companyController.dispose();
    _modelController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  int get _totalMediaCount => _selectedImages.length + _selectedVideos.length + _existingImages.length + _existingVideos.length;

  Future<void> _pickImages() async {
    if (_totalMediaCount >= _maxMediaTotal) {
      _showLimitReached();
      return;
    }
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 70);
    if (images.isNotEmpty) {
      for (var img in images) {
        if (_totalMediaCount < _maxMediaTotal) {
          _selectedImages.add(img);
          final bytes = await img.readAsBytes();
          _selectedImageBytes[img.path] = bytes;
        }
      }
      setState(() {});
    }
  }

  Future<void> _pickImageFromCamera() async {
    if (_totalMediaCount >= _maxMediaTotal) {
      _showLimitReached();
      return;
    }
    final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (image != null) {
      setState(() {
        _selectedImages.add(image);
      });
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes[image.path] = bytes;
      });
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    if (_totalMediaCount >= _maxMediaTotal) {
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
              leading: const Icon(Icons.video_library, color: Colors.blue),
              title: const Text('Galerie Vidéos'),
              onTap: () {
                Navigator.pop(context);
                _pickVideo(ImageSource.gallery);
              },
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.blue),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty && _existingImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter au moins une image du véhicule')),
      );
      return;
    }

    final vehicleCtrl = Provider.of<VehicleController>(context, listen: false);
    final authCtrl = Provider.of<AuthController>(context, listen: false);
    
    if (authCtrl.currentUser == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur : Vous devez être connecté.')),
      );
      return;
    }

    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Optimisation et envoi des médias...')),
      );

      // Upload Images
      final List<String> uploadedImages = await vehicleCtrl.compressAndUploadImages(_selectedImages);
      
      // Upload Videos
      final List<String> uploadedVideos = [];
      for (var v in _selectedVideos) {
        final url = await vehicleCtrl.compressAndUploadVideo(v);
        if (url != null) uploadedVideos.add(url);
      }

      final List<String> finalImages = [..._existingImages, ...uploadedImages];
      final List<String> finalVideos = [..._existingVideos, ...uploadedVideos];

      if (finalImages.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du téléchargement des images.'), backgroundColor: Colors.red),
        );
        return;
      }

      final vehicle = VehicleModel(
        id: widget.vehicleToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        companyName: _companyController.text.trim(),
        model: _modelController.text.trim(),
        city: _selectedCity,
        pricePerDay: double.parse(_priceController.text.replaceAll(' ', '')),
        images: finalImages,
        videoUrls: finalVideos,
        description: _descController.text.trim(),
        ownerId: authCtrl.currentUser!.id,
        createdAt: widget.vehicleToEdit?.createdAt ?? DateTime.now(),
      );

      bool success;
      if (widget.vehicleToEdit != null) {
        success = await vehicleCtrl.updateVehicle(vehicle);
      } else {
        success = await vehicleCtrl.addVehicle(vehicle);
      }

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.vehicleToEdit != null ? 'Véhicule modifié !' : 'Véhicule ajouté !')),
        );
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'opération.')),
        );
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Une erreur est survenue: $e')),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<VehicleController>(context).isLoading;
    final isEditing = widget.vehicleToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Modifier le véhicule" : "Ajouter un véhicule"),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Photos & Vidéos du véhicule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Text('Jusqu\'à 20 médias au total', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                              border: Border.all(color: Colors.grey.shade300),
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
                        // Existants
                        ..._existingImages.map((url) => _buildMediaThumbnail(
                          url: url,
                          onDelete: () => setState(() => _existingImages.remove(url)),
                        )),
                        ..._existingVideos.map((url) => _buildMediaThumbnail(
                          url: url,
                          isVideo: true,
                          onDelete: () => setState(() => _existingVideos.remove(url)),
                        )),
                        // Nouveaux
                        ..._selectedImages.map((file) => _buildMediaThumbnail(
                          file: file,
                          onDelete: () => setState(() {
                            _selectedImages.remove(file);
                            _selectedImageBytes.remove(file.path);
                          }),
                        )),
                        ..._selectedVideos.map((file) => _buildMediaThumbnail(
                          file: file,
                          isVideo: true,
                          onDelete: () => setState(() => _selectedVideos.remove(file)),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _companyController,
                    decoration: const InputDecoration(
                      labelText: "Nom de l'entreprise / Loueur",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Requis' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _modelController,
                    decoration: const InputDecoration(
                      labelText: "Modèle du véhicule",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.directions_car),
                    ),
                     validator: (value) => value == null || value.isEmpty ? 'Requis' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Prix par jour (FCFA)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.monetization_on),
                      suffixText: "FCFA",
                    ),
                     validator: (value) {
                       if (value == null || value.isEmpty) return 'Requis';
                       if (double.tryParse(value.replaceAll(' ', '')) == null) return 'Prix invalide';
                       return null;
                     },
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _selectedCity,
                    dropdownColor: Theme.of(context).cardColor,
                    decoration: const InputDecoration(
                      labelText: "Ville",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    items: BfLocations.cities.map((city) {
                      return DropdownMenuItem(
                        value: city,
                        child: Text(city),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCity = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Description (Optionnel)",
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isEditing ? "ENREGISTRER LES MODIFICATIONS" : "AJOUTER LE VÉHICULE",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

