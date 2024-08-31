/*
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedProgram;

  @override
  void initState() {
    super.initState();
    _loadSelectedProgram();
  }

  Future<void> _loadSelectedProgram() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedProgram = prefs.getString('selectedProgram') ?? 'Home';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedProgram ?? 'Home'),
      ),
      body: const Center(
        child: Text('Welcome to the Home Screen!'),
      ),
    );
  }
}

 */