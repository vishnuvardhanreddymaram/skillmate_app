import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import 'dart:convert';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController bioController;
  late TextEditingController skillsHaveController;
  late TextEditingController skillsWantController;
  
  String? _base64Image;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.user.name);
    bioController = TextEditingController(text: widget.user.bio);
    skillsHaveController = TextEditingController(text: widget.user.skillsHave);
    skillsWantController = TextEditingController(text: widget.user.skillsWant);
    _base64Image = widget.user.photoBase64;
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 20); // Compress heavily
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _base64Image = base64Encode(bytes);
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirestoreService().updateUserProfile(uid, {
        'name': nameController.text,
        'bio': bioController.text,
        'skillsHave': skillsHaveController.text,
        'skillsWant': skillsWantController.text,
        if (_base64Image != null) 'photoBase64': _base64Image,
      });
      if (mounted) {
        Navigator.pop(context);
      }
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xFFE0E7FF),
                    backgroundImage: _base64Image != null ? MemoryImage(base64Decode(_base64Image!)) : null,
                    child: _base64Image == null ? const Icon(Icons.person, size: 60, color: Color(0xFF6C63FF)) : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Color(0xFF6C63FF), shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: bioController, decoration: const InputDecoration(labelText: "Bio", border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: skillsHaveController, decoration: const InputDecoration(labelText: "Skills I Have", border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: skillsWantController, decoration: const InputDecoration(labelText: "Skills I Want", border: OutlineInputBorder())),
            const SizedBox(height: 32),
            _isLoading 
                ? const CircularProgressIndicator() 
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50)
                    ),
                    onPressed: _saveProfile,
                    child: const Text("Save Changes", style: TextStyle(fontSize: 18)),
                  )
          ],
        ),
      ),
    );
  }
}
