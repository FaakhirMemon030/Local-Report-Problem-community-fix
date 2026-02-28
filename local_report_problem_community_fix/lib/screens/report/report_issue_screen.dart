import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/auth_provider.dart';
import '../../providers/problem_provider.dart';
import '../../services/location_service.dart';
import '../../services/storage_service.dart';
import '../../models/problem_model.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'road';

  // Cross-platform image handling
  XFile? _pickedFile;
  Uint8List? _imageBytes;

  LatLng? _currentLocation;
  String _address = 'Tap to detect location';
  bool _isUploading = false;
  bool _locationLoading = false;

  final LocationService _locationService = LocationService();
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    setState(() => _locationLoading = true);
    try {
      final pos = await _locationService.getCurrentLocation();
      if (pos != null && mounted) {
        final loc = LatLng(pos.latitude, pos.longitude);
        setState(() => _currentLocation = loc);
        final placemark = await _locationService.getAddressFromLatLng(loc);
        if (placemark != null && mounted) {
          setState(() {
            _address = [
              placemark.street,
              placemark.locality,
              placemark.administrativeArea,
            ].where((s) => s != null && s!.isNotEmpty).join(', ');
          });
        }
      } else if (mounted) {
        setState(() => _address = 'Could not get location');
      }
    } catch (e) {
      if (mounted) setState(() => _address = 'Location error: $e');
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  Future<void> _pickImage({bool fromCamera = false}) async {
    try {
      final source = fromCamera ? ImageSource.camera : ImageSource.gallery;
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1024,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _pickedFile = picked;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            if (!kIsWeb) // Camera not supported on web
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(fromCamera: true);
                },
              ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(fromCamera: false);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    // Validate form
    if (!_formKey.currentState!.validate()) return;

    // Validate image
    if (_pickedFile == null || _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please add a photo of the issue')),
      );
      return;
    }

    // Validate location — use default if not detected
    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Location not detected. Tap the location row to retry.')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final problemProvider = Provider.of<ProblemProvider>(context, listen: false);

    if (authProvider.currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not logged in. Please login again.')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final problemId = DateTime.now().millisecondsSinceEpoch.toString();

      // Upload image
      final imageUrl = await _storageService.uploadProblemImageXFile(_pickedFile!, problemId);

      if (imageUrl == null) {
        throw Exception('Image upload failed. Check your internet connection.');
      }

      // Create problem document
      final problem = ProblemModel(
        problemId: problemId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _selectedCategory,
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        address: _address,
        imageUrl: imageUrl,
        reportedBy: authProvider.currentUserId!,
        voteCount: 0,
        priorityScore: 0.0,
        status: ProblemStatus.pending,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        city: authProvider.userModel?.city ?? '',
        district: '',
      );

      await problemProvider.reportProblem(problem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Report submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Civic Issue')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image picker
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _imageBytes != null ? Colors.blue : Colors.grey.shade300,
                      width: _imageBytes != null ? 2 : 1,
                    ),
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text('Tap to add photo', style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Location row
              GestureDetector(
                onTap: _fetchLocation,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _locationLoading
                            ? const Row(children: [
                                SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                                SizedBox(width: 8),
                                Text('Detecting location...'),
                              ])
                            : Text(
                                _address,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                      ),
                      const Icon(Icons.refresh, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Issue Title',
                  hintText: 'e.g. Broken road near main bazaar',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the issue in detail...',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Please describe the issue' : null,
              ),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  {'value': 'road', 'label': '🛣️ Road'},
                  {'value': 'garbage', 'label': '🗑️ Garbage'},
                  {'value': 'water', 'label': '💧 Water'},
                  {'value': 'electricity', 'label': '⚡ Electricity'},
                  {'value': 'drainage', 'label': '🌊 Drainage'},
                  {'value': 'other', 'label': '📌 Other'},
                ].map((c) => DropdownMenuItem<String>(
                  value: c['value'],
                  child: Text(c['label']!),
                )).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),

              const SizedBox(height: 32),

              // Submit button
              if (_isUploading)
                Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      'Uploading report...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _submitReport,
                    icon: const Icon(Icons.send),
                    label: const Text('Submit Report', style: TextStyle(fontSize: 16)),
                  ),
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
