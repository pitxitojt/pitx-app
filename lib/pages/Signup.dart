import 'package:flutter/material.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  bool _isPasswordVisible = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool get _isFormValid =>
      _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> socials = [
      {
        'label': "Google",
        'icon': 'http://pngimg.com/uploads/google/google_PNG19635.png',
        'size': 28.0,
      },
      {
        'label': "Facebook",
        'icon':
            'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b8/2021_Facebook_icon.svg/768px-2021_Facebook_icon.svg.png',
        'size': 24.0,
      },
      {
        'label': "Apple",
        'icon':
            'https://img.favpng.com/19/19/7/logo-apple-icon-information-png-favpng-LgLa8kMeALfAyE0iKbRnAJtnE.jpg',
        'size': 24.0,
      },
    ];

    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: EdgeInsetsGeometry.fromLTRB(24, 8, 24, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                Text(
                  'Sign up for a new account',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                Text(
                  'Start your journey with PITX.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 54),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Row(
                  children: [
                    Text(
                      'Email Address',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '*',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _emailController,
                    onChanged: (value) => setState(() {}),
                    style: TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      labelStyle: TextStyle(fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '*',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _passwordController,
                    onChanged: (value) => setState(() {}),
                    obscureText: !_isPasswordVisible,
                    style: TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      labelStyle: TextStyle(fontSize: 12),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          size: 18,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Opacity(
                  opacity: _isFormValid ? 1.0 : 0.5,
                  child: SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: TextButton(
                      onPressed: _isFormValid
                          ? () {
                              // Handle login action
                              print("Login button pressed");
                            }
                          : null,
                      style: TextButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: Text(
                        "Sign up",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: <Widget>[
                Expanded(
                  child: new Container(
                    margin: const EdgeInsets.only(left: 10.0, right: 20.0),
                    child: Divider(
                      color: Theme.of(context).colorScheme.primary,
                      height: 36,
                    ),
                  ),
                ),
                Text(
                  "OR",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: new Container(
                    margin: const EdgeInsets.only(left: 20.0, right: 10.0),
                    child: Divider(
                      color: Theme.of(context).colorScheme.primary,
                      height: 36,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 4,
              children: socials.map((social) {
                return IconButton(
                  onPressed: () {},
                  icon: Image.network(
                    social['icon'],
                    width: social['size'],
                    height: social['size'],
                  ),
                  tooltip: social['label'],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
