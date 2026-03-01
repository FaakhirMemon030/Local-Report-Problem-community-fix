import 'dart:typed_data';
import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // image_cropper hata diya gaya hai
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

  String _selectedCategory = 'road';

  // Image
  XFile? _pickedFile;
  Uint8List? _imageBytes;

  // Location
  LatLng? _location;
  String _address = 'Tap to detect GPS location';
  String _city = '';
  String _district = '';
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
      _locationFromExif = fromExif;
      _locationLoading = true;
    });

    try {
      final info = await _locationService.getAddressFromLatLng(latLng);
      if (mounted) {
        setState(() {
          _address = info.fullAddress;
          _city = info.city;
          _district = info.district;
        });
      }
    } catch (e) {
      print("LPRCF: Address detection error: $e");
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }



  // ─── Pick image (NO CROPPING) ──────────────────────────────────────────────
  Future<void> _pickImage({bool fromCamera = false}) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 90,
      );
      if (picked == null) return;

      // Extract EXIF GPS from original bytes
      final rawBytes = await picked.readAsBytes();
      await _tryExtractExifLocation(rawBytes);

      setState(() {
        _pickedFile = picked; // Direct assignment without cropping
        _imageBytes = rawBytes;
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


  // ─── Submit ───────────────────────────────────────────────────────────────
  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedFile == null || _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Please add a photo')));
      return;
    }



    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final problemProvider = Provider.of<ProblemProvider>(context, listen: false);
    if (authProvider.currentUserId == null) return;

    setState(() => _isUploading = true);
    try {
      final problemId = DateTime.now().millisecondsSinceEpoch.toString();
      final imageUrl = await _storageService.uploadProblemImageXFile(_pickedFile!, problemId);
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
        city: _city.isNotEmpty ? _city : (authProvider.userModel?.city ?? ''),
        district: _district,
      );

      await problemProvider.reportProblem(problem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Report submitted!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('REPORT ISSUE'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        ),
      ),
      body: Stack(
        children: [
          // Background subtle glows
          Positioned(
            bottom: 100,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withOpacity(0.05),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    // Photo Picker
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        height: 220,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _imageBytes != null ? const Color(0xFF3B82F6).withOpacity(0.5) : Colors.white.withOpacity(0.05),
                            width: 2,
                          ),
                          image: _imageBytes != null
                              ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: _imageBytes == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.add_a_photo_rounded, size: 40, color: Color(0xFF60A5FA)),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'ADD ISSUE PHOTO',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Take a clear picture of the problem',
                                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                                  ),
                                ],
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                                  ),
                                ),
                                alignment: Alignment.bottomRight,
                                padding: const EdgeInsets.all(16),
                                child: const Icon(Icons.edit_rounded, color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Location Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (_locationFromExif ? const Color(0xFF10B981) : const Color(0xFF3B82F6)).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _locationFromExif ? Icons.photo_library_rounded : Icons.location_on_rounded,
                              color: _locationFromExif ? const Color(0xFF34D399) : const Color(0xFF60A5FA),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _locationFromExif ? 'LOCATION FROM PHOTO' : 'CURRENT LOCATION',
                                  style: TextStyle(
                                    color: (_locationFromExif ? const Color(0xFF34D399) : const Color(0xFF60A5FA)).withOpacity(0.8),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _address,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _locationLoading ? null : _detectGPSLocation, 
                            icon: _locationLoading 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF60A5FA)))
                                : const Icon(Icons.refresh_rounded, color: Color(0xFF60A5FA)),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Form Fields
                    _buildFormLabel('ISSUE TITLE'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleCtrl,
                      style: const TextStyle(color: Colors.white),
                      validator: (v) => (v == null || v.isEmpty) ? 'Title required' : null,
                      decoration: _inputDecoration('Enter a catchy title', Icons.title_rounded),
                    ),
                    const SizedBox(height: 20),

                    _buildFormLabel('DESCRIPTION'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      validator: (v) => (v == null || v.isEmpty) ? 'Description required' : null,
                      decoration: _inputDecoration('Describe the problem in detail...', Icons.description_rounded),
                    ),
                    const SizedBox(height: 20),

                    _buildFormLabel('CATEGORY'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      items: ['road', 'garbage', 'water', 'electricity', 'other'].map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.toUpperCase(), style: const TextStyle(fontSize: 14, letterSpacing: 1)),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v!),
                      decoration: _inputDecoration('', Icons.category_rounded),
                    ),
                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isUploading ? null : _submitReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isUploading 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('SUBMIT REPORT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.white.withOpacity(0.5),
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.2), size: 20),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text('Add Photo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 24),
            if (!kIsWeb)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF60A5FA)),
                ),
                title: const Text('Take Photo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                onTap: () { Navigator.pop(context); _pickImage(fromCamera: true); },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.photo_library_rounded, color: Color(0xFF34D399)),
              ),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              onTap: () { Navigator.pop(context); _pickImage(fromCamera: false); },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ],
        ),
      ),
    );
  }
}
