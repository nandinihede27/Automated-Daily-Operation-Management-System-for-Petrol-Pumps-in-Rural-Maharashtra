import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  final String userId;
  const ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  final nameController = TextEditingController();
  final emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  void fetchProfile() async {
    try {
      DocumentSnapshot snap =
          await _firestore.collection('users').doc(widget.userId).get();
      setState(() {
        userData = snap.data() as Map<String, dynamic>?;
        nameController.text = userData?['name'] ?? '';
        emailController.text = userData?['email'] ?? '';
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching profile: $e')),
      );
    }
  }

  void updateProfile() async {
    try {
      await _firestore.collection('users').doc(widget.userId).update({
        'name': nameController.text,
        'email': emailController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('Profile'), backgroundColor: Colors.orange),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name')),
                  const SizedBox(height: 10),
                  TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email')),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: updateProfile,
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.orange),
                    child: const Text('Update Profile'),
                  ),
                ],
              ),
            ),
    );
  }
}
