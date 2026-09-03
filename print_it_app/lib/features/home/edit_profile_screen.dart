import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../shared/widgets/ambient_background.dart';
import '../../shared/widgets/glass_container.dart';
import '../auth/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isLoading = false;
  File? _selectedImage;
  String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    if (user != null) {
      _nameController.text = user['full_name'] ?? user['name'] ?? '';
      _phoneController.text = user['phone'] ?? '';
      _emailController.text = user['email'] ?? '';
      _currentAvatarUrl = user['avatar_url'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.single.path != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: result.files.single.path!,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: const Color(0xFF7000FF),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: true,
          ),
          IOSUiSettings(
            title: 'Crop Profile Picture',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _selectedImage = File(croppedFile.path);
        });
      }
    }
  }

  Future<String?> _uploadImage(File file) async {
    try {
      final apiClient = ref.read(apiProvider);
      final fileName = file.path.split('/').last;
      
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await apiClient.post('/upload', data: formData);
      if (response.statusCode == 201) {
        return response.data['file']['s3_key']; // Using the Firebase Storage setup which returns s3_key
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
    }
    return null;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String? avatarUrl = _currentAvatarUrl;

    if (_selectedImage != null) {
      final uploadedUrl = await _uploadImage(_selectedImage!);
      if (uploadedUrl != null) {
        avatarUrl = uploadedUrl;
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image')),
          );
        }
        return;
      }
    }

    final success = await ref.read(authProvider.notifier).updateProfile(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      avatarUrl: avatarUrl,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(authProvider).error ?? 'Failed to update profile')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Edit Profile', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const AmbientBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: const Color(0xFF7000FF).withValues(alpha: 0.2),
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : (_currentAvatarUrl != null ? NetworkImage(_currentAvatarUrl!) : null) as ImageProvider?,
                            child: (_selectedImage == null && _currentAvatarUrl == null)
                                ? Icon(Icons.person, size: 60, color: Theme.of(context).colorScheme.onSurface)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF3BAFF2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    GlassContainer(
                      padding: const EdgeInsets.all(24),
                      borderRadius: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Full Name', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                              filled: true,
                              fillColor: Colors.black.withValues(alpha: 0.2),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              hintText: 'Enter your full name',
                              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                          ),
                          const SizedBox(height: 24),
                          Text('Mobile Number', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _phoneController,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.phone_outlined, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                              filled: true,
                              fillColor: Colors.black.withValues(alpha: 0.2),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              hintText: 'Enter your mobile number',
                              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text('Email Address', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.email_outlined, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                              filled: true,
                              fillColor: Colors.black.withValues(alpha: 0.2),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              hintText: 'Enter your email address',
                              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Email is required';
                              if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7000FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
