import 'dart:typed_data';
import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/problem_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/problem_provider.dart';
import '../../services/location_service.dart';
import '../../services/storage_service.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});
  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();

  String _selectedCategory = 'road';

  // Image
  XFile? _pickedFile;
  Uint8List? _imageBytes;

  // Location
  LatLng? _location;
  String _address = 'Tap to detect GPS location';
  bool _locationLoading = false;
  bool _locationFromExif = false;

  // State
  bool _isUploading = false;

  final _locationService = LocationService();
  final _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _detectGPSLocation();
  }

  // ─── GPS from device ──────────────────────────────────────────────────────
  Future<void> _detectGPSLocation() async {
    setState(() {
      _locationLoading = true;
      _locationFromExif = false;
    });
    try {
      final pos = await _locationService.getCurrentLocation();
      if (pos != null && mounted) {
        await _applyLatLng(LatLng(pos.latitude, pos.longitude), fromExif: false);
      } else if (mounted) {
        setState(() => _address = 'Location unavailable — enter manually or use photo');
      }
    } catch (_) {
      if (mounted) setState(() => _address = 'Could not detect location');
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  // ─── Apply a LatLng and reverse geocode ──────────────────────────────────
  Future<void> _applyLatLng(LatLng latLng, {bool fromExif = false}) async {
    setState(() {
      _location = latLng;
      _latCtrl.text = latLng.latitude.toStringAsFixed(6);
      _lngCtrl.text = latLng.longitude.toStringAsFixed(6);
      _locationFromExif = fromExif;
    });
    try {
      final placemarks = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        setState(() => _address = [p.street, p.locality, p.administrativeArea]
            .where((s) => s != null && s!.isNotEmpty)
            .join(', '));
      }
    } catch (_) {}
  }

  // ─── Apply manual coords ─────────────────────────────────────────────────
  void _applyManualCoords() {
    final lat = double.tryParse(_latCtrl.text);
    final lng = double.tryParse(_lngCtrl.text);
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid latitude and longitude')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _locationLoading = true);
    _applyLatLng(LatLng(lat, lng)).then((_) {
      if (mounted) setState(() => _locationLoading = false);
    });
  }

  // ─── Pick image ──────────────────────────────────────────────────────────
  Future<void> _pickImage({bool fromCamera = false}) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 90,
      );
      if (picked == null) return;

      final rawBytes = await picked.readAsBytes();
      await _tryExtractExifLocation(rawBytes);

      XFile finalFile = picked;
      if (!kIsWeb) {
        // FIXED: Using correct parameters for image_cropper 5.0.0+
        final cropped = await ImageCropper().cropImage(
          sourcePath: picked.path,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Photo',
              toolbarColor: const Color(0xFF1A73E8),
              toolbarWidgetColor: Colors.white,
              lockAspectRatio: false,
            ),
            IOSUiSettings(title: 'Crop Photo'),
          ],
        );
        if (cropped != null) finalFile = XFile(cropped.path);
      }

      final bytes = await finalFile.readAsBytes();
      setState(() {
        _pickedFile = finalFile;
        _imageBytes = bytes;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image error: $e')),
        );
      }
    }
  }

  // ─── Extract EXIF GPS ─────────────────────────────────────────────────────
  Future<void> _tryExtractExifLocation(Uint8List bytes) async {
    try {
      final tags = await readExifFromBytes(bytes);
      if (tags.isEmpty) return;

      final latTag = tags['GPS GPSLatitude'];
      final latRefTag = tags['GPS GPSLatitudeRef'];
      final lngTag = tags['GPS GPSLongitude'];
      final lngRefTag = tags['GPS GPSLongitudeRef'];

      if (latTag == null || lngTag == null) return;

      double? lat = _parseExifCoord(latTag.toString());
      double? lng = _parseExifCoord(lngTag.toString());

      if (lat == null || lng == null) return;

      if (latRefTag?.toString() == 'S') lat = -lat;
      if (lngRefTag?.toString() == 'W') lng = -lng;

      if (mounted) {
        setState(() => _locationLoading = true);
        await _applyLatLng(LatLng(lat!, lng!), fromExif: true);
        if (mounted) setState(() => _locationLoading = false);
      }
    } catch (_) {}
  }

  double? _parseExifCoord(String raw) {
    try {
      final clean = raw.replaceAll('[', '').replaceAll(']', '');
      final parts = clean.split(', ');
      if (parts.length < 3) return null;

      double parse(String frac) {
        final f = frac.split('/');
        if (f.length == 2) return double.parse(f[0]) / double.parse(f[1]);
        return double.parse(frac);
      }

      final deg = parse(parts[0]);
      final min = parse(parts[1]);
      final sec = parse(parts[2]);
      return deg + (min / 60) + (sec / 3600);
    } catch (_) {
      return null;
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            if (!kIsWeb)
              ListTile(
                leading:
                    const Icon(Icons.camera_alt_outlined, color: Colors.blue),
                title: const Text('Take Photo'),
                subtitle: const Text('GPS from image will be auto-detected'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(fromCamera: true);
                },
              ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Colors.blue),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('GPS from image will be auto-detected'),
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

  // ─── Submit ───────────────────────────────────────────────────────────────
  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pickedFile == null || _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Please add a photo')));
      return;
    }

    final lat = double.tryParse(_latCtrl.text);
    final lng = double.tryParse(_lngCtrl.text);
    if (lat != null && lng != null) {
      _location = LatLng(lat, lng);
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final problemProvider =
        Provider.of<ProblemProvider>(context, listen: false);
    if (authProvider.currentUserId == null) return;

    setState(() => _isUploading = true);
    try {
      final problemId = DateTime.now().millisecondsSinceEpoch.toString();
      final imageUrl =
          await _storageService.uploadProblemImageXFile(_pickedFile!, problemId);

      if (imageUrl == null) throw Exception('Image upload failed');

      final problem = ProblemModel(
        problemId: problemId,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _selectedCategory,
        latitude: _location?.latitude ?? 0.0,
        longitude: _location?.longitude ?? 0.0,
        address: _location != null ? _address : 'Location not provided',
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Report submitted!'),
            backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Civic Issue')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 210,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _imageBytes != null
                          ? const Color(0xFF1A73E8)
                          : Colors.grey.shade300,
                      width: _imageBytes != null ? 2 : 1,
                    ),
                  ),
                  child: _imageBytes != null
                      ? Stack(children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.memory(_imageBytes!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover),
                          ),
                          Positioned(
                            bottom: 8, right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.crop, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text('Tap to change / crop', style: TextStyle(color: Colors.white, fontSize: 11)),
                              ]),
                            ),
                          ),
                        ])
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 52, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text('Tap to add photo', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
                            const SizedBox(height: 4),
                            Text('GPS will be auto-read from photo', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _locationFromExif ? Colors.green[50] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _locationFromExif ? Colors.green.shade200 : Colors.blue.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(
                        _locationFromExif ? Icons.image_search : Icons.location_on,
                        color: _locationFromExif ? Colors.green : Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _locationLoading
                            ? const Row(children: [
                                SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                                SizedBox(width: 8),
                                Text('Detecting location...', style: TextStyle(fontSize: 13)),
                              ])
                            : Text(
                                _address,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _location != null ? Colors.black87 : Colors.grey[600],
                                ),
                              ),
                      ),
                      TextButton.icon(
                        onPressed: _locationLoading ? null : _detectGPSLocation,
                        icon: const Icon(Icons.gps_fixed, size: 14),
                        label: const Text('GPS', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                      ),
                    ]),

                    if (_locationFromExif)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('📸 Location read from photo EXIF data',
                          style: TextStyle(fontSize: 11, color: Colors.green[700], fontStyle: FontStyle.italic)),
                      ),

                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),

                    const Text('Manual Coordinates (Optional)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _latCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          decoration: InputDecoration(
                            hintText: 'Latitude',
                            hintStyle: const TextStyle(fontSize: 12),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _lngCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          decoration: InputDecoration(
                            hintText: 'Longitude',
                            hintStyle: const TextStyle(fontSize: 12),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _applyManualCoords,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(44, 44),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Icon(Icons.check, size: 18),
                      ),
                    ]),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Issue Title',
                  hintText: 'e.g. Broken road near main bazaar',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the issue...',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a description' : null,
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  {'v': 'road', 'l': '🛣️ Road'},
                  {'v': 'garbage', 'l': '🗑️ Garbage'},
                  {'v': 'water', 'l': '💧 Water'},
                  {'v': 'electricity', 'l': '⚡ Electricity'},
                  {'v': 'drainage', 'l': '🌊 Drainage'},
                  {'v': 'other', 'l': '📌 Other'},
                ].map((c) => DropdownMenuItem<String>(value: c['v'], child: Text(c['l']!))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),

              const SizedBox(height: 28),

              if (_isUploading)
                const Center(
                  child: Column(children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text('Uploading report...', style: TextStyle(color: Colors.grey)),
                  ]),
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