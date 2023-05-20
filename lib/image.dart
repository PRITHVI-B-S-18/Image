import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:imagepicker/login.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? _displayName;
  String? _displayEmail;
  File? _selectedImage;
  final _formKey=GlobalKey<FormState>();
  String?  _imageUrl;

  Future<void> _selectImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  Future<void> _saveUserInfo() async {
    // Validate form fields
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    // Save user info to Firebase Firestore or do other necessary tasks

    // Upload the image to Firebase Storage
    if (_selectedImage != null) {
      final storage = FirebaseStorage.instance;
      final reference = storage.ref().child('profile_images/${name ?? ''}.jpg');
      await reference.putFile(_selectedImage!);

      // Get the download URL of the uploaded image
      final imageUrl = await reference.getDownloadURL();

      // You can save the image URL to Firestore or use it as needed
      print('Image URL: $imageUrl');
      setState(() {
        _imageUrl = imageUrl;
      });
    }

    setState(() {
      _displayName = name;
      _displayEmail = email;
    });
    // Save user info to Firebase Realtime Database
    final database = FirebaseDatabase.instance;
    final userRef = database.ref().child('users').push();

    final userData = {
      'name': name,
      'email': email,
      'imageUrl': _imageUrl ?? '',
    };

    await userRef.set(userData);

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Screen'),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _selectImage,
                  child: Text('Select Image'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveUserInfo,
                  child: Text('Save'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  child: Text('Logout'),
                  onPressed: () {
                    FirebaseAuth.instance.signOut().then((value) {
                      print("Signed Out");
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    });
                  },
                ),
                SizedBox(height: 20),
                Text('Name: $_displayName'),
                Text('Email: $_displayEmail'),
                SizedBox(height: 20),
                if (_imageUrl != null)
                  Image.network(_imageUrl!,width:200,height:200),
              ],
            ),
          ),
        ),
      ),
    );
  }
}