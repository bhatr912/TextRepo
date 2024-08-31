import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'BNPTemplateScreen.dart';
class BNPScreen extends ConsumerStatefulWidget {
  final String type;
  final String courseName;

  const BNPScreen({super.key, required this.type, required this.courseName});

  @override
  _BNPScreenState createState() => _BNPScreenState();
}

class _BNPScreenState extends ConsumerState<BNPScreen> {
  String? _selectedProgram;

  @override
  void initState() {
    super.initState();
    _loadSelectedProgram();
  }

  Future<void> _loadSelectedProgram() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedProgram = prefs.getString('selectedProgram');
    });
  }

  Future<List<Map<String, dynamic>>> _fetchBooks() async {
    if (_selectedProgram == null) {
      return [];
    }

    final CollectionReference booksCollection = FirebaseFirestore.instance
        .collection('Programs')
        .doc(_selectedProgram)
        .collection('Courses')
        .doc(widget.courseName)
        .collection(widget.type);

    final QuerySnapshot booksSnapshot = await booksCollection.get();

    return booksSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
    return FutureBuilder(
      future: _fetchBooks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No data available'));
        }

        var books = snapshot.data!;
        if (searchQuery.isNotEmpty) {
          books = books.where((book) {
            final name = book['Name'].toString().toLowerCase();
            return name.contains(searchQuery);
          }).toList();
          books.sort((a, b) {
            final nameA = a['Name'].toString().toLowerCase();
            final nameB = b['Name'].toString().toLowerCase();
            return nameA.compareTo(nameB);
          });

          if (books.isEmpty) {
            return const Center(child: Text('No match found'));
          }
        }

        const double itemWidth = 180.0;
        const double itemHeight = 330.0;
        final int crossAxisCount = (MediaQuery.of(context).size.width / itemWidth).floor();

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: itemWidth / itemHeight,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          padding: const EdgeInsets.all(4),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return BNPTemplateScreen(
              name: book['Name'],
              url: book['Url'],
              storageLocation: book['StorageLocation'],
            );
          },
        );
      },
    );
  }
}
