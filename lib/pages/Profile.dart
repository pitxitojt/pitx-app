import 'package:flutter/material.dart';
import 'package:pitx/main.dart';
import 'package:pitx/pages/Settings.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  User? _user;

  Future<void> _signOut() async {
    try {
      await AuthManager.logout();
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final fileName = supabase.auth.currentUser!.id;
    final hasAvatar = _user!.userMetadata?['avatar'] != null;

    final result = await showModalBottomSheet<String>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              if (hasAvatar)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text(
                    'Remove profile photo',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () => Navigator.pop(context, 'remove'),
                ),
              ListTile(
                leading: Icon(Icons.close),
                title: Text('Cancel'),
                onTap: () => Navigator.pop(context, 'cancel'),
              ),
            ],
          ),
        );
      },
    );

    if (result == 'gallery') {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        File file = File(image.path);
        if (hasAvatar) {
          await supabase.storage.from('avatar').remove([fileName]);
        }
        await supabase.storage.from('avatar').upload(fileName, file);
        final publicUrl = supabase.storage
            .from('avatar')
            .getPublicUrl(fileName);
        final u = await supabase.auth.updateUser(
          UserAttributes(data: {'avatar': publicUrl}),
        );
        print(u.user);
        setState(() => _user = u.user);
      }
    } else if (result == 'remove' && hasAvatar) {
      await supabase.storage.from('avatar').remove([fileName]);
      final u = await supabase.auth.updateUser(
        UserAttributes(data: {'avatar': null}),
      );
      setState(() => _user = u.user);
    }
    // Cancel does nothing
  }

  Future<void> _showLogoutConfirmation() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Confirm Logout',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await _signOut(); // Proceed with logout
              },
            ),
          ],
        );
      },
    );
  }

  final List<Map<String, dynamic>> menuItems = [
    {'label': 'About PITX', 'icon': Icons.info},
    {'label': 'Contact Us', 'icon': Icons.phone},
    {'label': 'Settings', 'icon': Icons.settings},
    {'label': 'Logout', 'icon': Icons.logout},
  ];

  @override
  void initState() {
    super.initState();
    getUser();
  }

  Future<void> getUser() async {
    final response = await supabase.auth.getUser();
    setState(() {
      _user = response.user;
    });
  }

  Future<void> _onMenuTap(String label) async {
    switch (label) {
      case 'Logout':
        await _showLogoutConfirmation();
        break;
      case 'Settings':
        // Navigate to Settings page
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const Settings()));
        break;
      case 'About PITX':
        launchUrl(
          Uri.parse('https://www.pitx.ph/about/about-pitx/'),
          mode: LaunchMode.externalApplication,
        );
        break;
      case 'Contact Us':
        launchUrl(
          Uri.parse('https://www.pitx.ph/contact-us/'),
          mode: LaunchMode.externalApplication,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
              Colors.white,
            ],
            stops: [0.0, 0.5, 0.7],
          ),
        ),
        child: _user == null
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Modern profile section as part of scrollable content
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.transparent),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Account",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: _user!.userMetadata?['avatar'] != null
                                  ? CircleAvatar(
                                      radius: 40,
                                      backgroundImage: NetworkImage(
                                        _user!.userMetadata?['avatar'] != null
                                            ? _user!.userMetadata!['avatar'] +
                                                  '?v=${DateTime.now().millisecondsSinceEpoch}'
                                            : '',
                                      ),
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            '${_user!.userMetadata!['first_name']} ${_user?.userMetadata!['last_name']}'
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '+${_user!.phone}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content section
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Modern menu items
                            ...menuItems.map((item) {
                              return Container(
                                margin: EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () async =>
                                        await _onMenuTap(item['label']),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              item['icon'],
                                              size: 16,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              item['label'],
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.all(3),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Icon(
                                              Icons.arrow_forward_ios,
                                              size: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),

                            SizedBox(height: 24),

                            // Modern info section
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.1),
                                    Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.2),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.info_outline,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'PITX Mobile App',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Your gateway to seamless travel experiences at the Philippines\' first-ever landport terminal.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                      height: 1.3,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Version 1.0.0',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          'Up to date',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Add extra bottom padding
                            SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
