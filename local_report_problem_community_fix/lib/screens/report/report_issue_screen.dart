import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  File? _image;
  LatLng? _currentLocation;
  String _address = 'Detecting location...';
  bool _isUploading = false;

  final LocationService _locationService = LocationService();
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    final pos = await _locationService.getCurrentLocation();
    if (pos != null) {
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(pos.latitude, pos.longitude);
        });
        final placemark = await _locationService.getAddressFromLatLng(_currentLocation!);
        if (placemark != null && mounted) {
          setState(() {
            _address = "${placemark.street}, ${placemark.locality}, ${placemark.country}";
          });
        }
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final problemProvider = Provider.of<ProblemProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Report Civic Issue')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    image: _image != null ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover) : null,
                  ),
                  child: _image == null ? const Icon(Icons.add_a_photo, size: 50, color: Colors.grey) : null,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_address, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Issue Title'),
                validator: (val) => val!.isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (val) => val!.isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: ['road', 'garbage', 'water', 'electricity', 'drainage', 'other'].map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase()))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 32),
              if (_isUploading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate() && _image != null && _currentLocation != null) {
                      setState(() => _isUploading = true);
                      try {
                        final problemId = DateTime.now().millisecondsSinceEpoch.toString();
                        final imageUrl = await _storageService.uploadProblemImage(_image!, problemId);
                        
                        if (imageUrl != null) {
                          final problem = ProblemModel(
                            problemId: problemId,
                            title: _titleController.text,
                            description: _descController.text,
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
                          if (mounted) Navigator.pop(context);
                        }
                      } catch (e) {
                         if (mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                         }
                      } finally {
                        if (mounted) setState(() => _isUploading = false);
                      }
                    } else if (_image == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please take a photo')));
                    }
                  },
                  child: const Text('Submit Report'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
