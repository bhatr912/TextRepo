import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  bool _isLogin = false;
  bool _isLoading = false;
  String? _selectedProgram;
  List<String> _programs = [];
  late AnimationController _animationController;
  late Animation<double> _animation;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _fetchPrograms();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  void _toggleAuth() {
    setState(() {
      _isLogin = !_isLogin;
    });
    if (_isLogin) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  Future<void> _fetchPrograms() async {
    try {
      final QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('Programs').get();
      final List<String> programs = snapshot.docs.map((doc) => doc.id).toList(); // Assumes doc id is the program name
      setState(() {
        _programs = programs;
      });
    } catch (e) {
      print('Error fetching programs: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Error fetching programs'),
        ),
      );
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        print("User registered: ${userCredential.user?.email}");
        final email = _emailController.text.trim();
        final fullName = _fullNameController.text.trim();

// Check if 'Users' collection exists, if not create it
        final CollectionReference usersCollection = FirebaseFirestore.instance.collection('Users');
        final doc = await usersCollection.doc(email).get();
        if (!doc.exists) {
          await usersCollection.doc(email).set({
            'name': fullName,
            'editor': false,
            'admin': false,
            'program':_selectedProgram
          });
        }
        // Save selected program in shared preferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', email);
        await prefs.setString('selectedProgram', _selectedProgram!);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                backgroundColor: Colors.blueAccent,
                content: Text(
                    'This email is already in use. Please use a different email')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.message}')),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        print("User logged in: ${userCredential.user?.email}");

        // Save selected program in shared preferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        final email = _emailController.text.trim();
        await prefs.setString('email', email);
        await prefs.setString('selectedProgram', _selectedProgram!);


        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return _buildWideLayout(constraints);
          } else {
            return _buildNarrowLayout(constraints);
          }
        },
      ),
    );
  }

  Widget _buildWideLayout(BoxConstraints constraints) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            color: const Color(0xFF2880BC),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.security, size: 100, color: Colors.white),
                  const SizedBox(height: 20),
                  Text(
                    _isLogin ? 'Welcome Back' : 'Join Us',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isLogin
                        ? 'Sign in to continue'
                        : 'Create an account to get started',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child:
                        _isLogin ? _buildLoginForm() : _buildRegisterForm(),
                      ),
                      const SizedBox(height: 20),
                      _buildToggleButton(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BoxConstraints constraints) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: IntrinsicHeight(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 80),
                _buildLogo(),
                const SizedBox(height: 40),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: _isLogin ? _buildLoginForm() : _buildRegisterForm(),
                ),
                const SizedBox(height: 20),
                _buildToggleButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Hero(
      tag: 'authLogo',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        height: _isLogin ? 80 : 120,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF2880BC),
        ),
        child: Center(
          child: Icon(
            Icons.security,
            size: _isLogin ? 40 : 60,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Welcome Back',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2880BC)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 50),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              hintText: 'Email',
              prefixIcon: Icon(Icons.email, color: Color(0xFF2880BC)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              hintText: 'Password',
              prefixIcon: Icon(Icons.lock, color: Color(0xFF2880BC)),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters long';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: _selectedProgram,
          items: _programs
              .map((program) => DropdownMenuItem<String>(
            value: program,
            child: Text(program, overflow: TextOverflow.ellipsis),
          ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedProgram = value;
            });
          },
          isExpanded: true,
          decoration: const InputDecoration(
            hintText: 'Select Program',
            prefixIcon: Icon(Icons.school, color: Color(0xFF2880BC)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a program';
            }
            return null;
          },
        ),
        const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2880BC),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            )
                : const Text('Login', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Create Account',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2880BC)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 50),
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(
              hintText: 'Full Name',
              prefixIcon: Icon(Icons.person, color: Color(0xFF2880BC)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your full name';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              hintText: 'Email',
              prefixIcon: Icon(Icons.email, color: Color(0xFF2880BC)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              hintText: 'Password',
              prefixIcon: Icon(Icons.lock, color: Color(0xFF2880BC)),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters long';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: _selectedProgram,
          items: _programs
              .map((program) => DropdownMenuItem<String>(
            value: program,
            child: Text(program, overflow: TextOverflow.ellipsis),
          ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedProgram = value;
            });
          },
          isExpanded: true,
          decoration: const InputDecoration(
            hintText: 'Select Program',
            prefixIcon: Icon(Icons.school, color: Color(0xFF2880BC)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a program';
            }
            return null;
          },
        ),
        const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _isLoading ? null : _register,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2880BC),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            )
                : const Text('Register', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_isLogin ? 'Don\'t have an account?' : 'Already have an account?'),
        TextButton(
          onPressed: _toggleAuth,
          child: Text(
            _isLogin ? 'Sign Up' : 'Login',
            style: const TextStyle(color: Color(0xFF2880BC)),
          ),
        ),
      ],
    );
  }
}
