import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final User? _user = FirebaseAuth.instance.currentUser;
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  File? _selectedImage;
  String? _currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        setState(() {
          _nameController.text = userDoc.data()?['name'] ?? _user!.displayName ?? '';
          _currentPhotoUrl = userDoc.data()?['photoUrl'] ?? _user!.photoURL;
        });
      } else {
        setState(() {
          _nameController.text = _user!.displayName ?? '';
          _currentPhotoUrl = _user!.photoURL;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() {
        _nameController.text = _user!.displayName ?? '';
        _currentPhotoUrl = _user!.photoURL;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chyba při výběru obrázku: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showImageSourceDialog() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Colors.blue),
                title: const Text('Vybrat z galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Colors.green),
                title: const Text('Vyfotit'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_currentPhotoUrl != null || _selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Odstranit fotku', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                      _currentPhotoUrl = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _uploadProfileImage(File imageFile) async {
    if (_user == null) return null;

    try {
      final String fileName = 'profile_${_user!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(fileName);

      debugPrint('Uploading image to: ${storageRef.fullPath}');
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _deleteOldProfileImage(String imageUrl) async {
    try {
      if (imageUrl.contains('firebase')) {
        final Reference ref = FirebaseStorage.instance.refFromURL(imageUrl);
        await ref.delete();
        debugPrint('Old profile image deleted');
      }
    } catch (e) {
      debugPrint('Error deleting old image: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_user == null) return;

    setState(() => _isLoading = true);

    try {
      final newName = _nameController.text.trim();
      String? photoUrl = _currentPhotoUrl;

      // Pokud byl vybrán nový obrázek, nahraj ho
      if (_selectedImage != null) {
        debugPrint('Uploading new profile image...');
        
        // Smaž starý obrázek pokud existuje
        if (_currentPhotoUrl != null) {
          await _deleteOldProfileImage(_currentPhotoUrl!);
        }

        // Nahraj nový obrázek
        photoUrl = await _uploadProfileImage(_selectedImage!);
        
        if (photoUrl == null) {
          throw Exception('Nepodařilo se nahrát obrázek');
        }
      }

      debugPrint('Saving profile: name=$newName, photoUrl=$photoUrl');

      // Ulož do Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .set({
        'name': newName,
        'email': _user!.email ?? '',
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('Firestore updated successfully');

      // Ulož do Firebase Auth
      await _user!.updateDisplayName(newName);
      if (photoUrl != null) {
        await _user!.updatePhotoURL(photoUrl);
      }
      await _user!.reload();
      
      debugPrint('Firebase Auth updated successfully');

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Profil úspěšně aktualizován'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      Navigator.pop(context, true);
      
    } catch (e) {
      debugPrint('ERROR saving profile: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Chyba při ukládání: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upravit profil'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar s možností změny
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primaryContainer,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _selectedImage != null
                              ? Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                )
                              : _currentPhotoUrl != null
                                  ? Image.network(
                                      _currentPhotoUrl!,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                    loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return _buildDefaultAvatar();
                                      },
                                    )
                                  : _buildDefaultAvatar(),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),

              // Jméno
              Text(
                'Jméno',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Tvoje jméno',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Zadej své jméno';
                  }
                  if (value.trim().length < 2) {
                    return 'Jméno musí mít alespoň 2 znaky';
                  }
                  return null;
                },
                onChanged: (value) => setState(() {}),
              ),

              const SizedBox(height: 24),

              // Email (read-only)
              Text(
                'Email',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _user?.email ?? '',
                enabled: false,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),

              const SizedBox(height: 40),

              // Uložit tlačítko
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Uložit změny',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Center(
      child: Text(
        _nameController.text.isNotEmpty 
            ? _nameController.text[0].toUpperCase() 
            : 'U',
        style: TextStyle(
          fontSize: 56,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}