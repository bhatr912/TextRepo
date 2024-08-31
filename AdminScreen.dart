import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';

import '../main.dart';

class AdminScreen extends StatefulWidget {
  final String courseName;

  const AdminScreen({super.key, required this.courseName});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;
  List<PlatformFile> files = [];
  bool showProgress = false;
  final List<Widget> _widgetOptions = <Widget>[
    const UserManagement(),
    AdManagement(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        body: Center(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(
            Icons.add,
            color: Color(0xFF1A74BD),
          ),
          onPressed: () {
            if (_selectedIndex == 1) {
              _showAddAdDialog(context);
            }
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.people),
                color: _selectedIndex == 0 ? const Color(0xFF1A74BD) : Colors.blueGrey,
                onPressed: () => _onItemTapped(0),
              ),
              const SizedBox(width: 48),
              IconButton(
                icon: const Icon(Icons.ad_units),
                color: _selectedIndex == 1 ? const Color(0xFF1A74BD) : Colors.blueGrey,
                onPressed: () => _onItemTapped(1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddAdDialog(BuildContext context) {
    String adUrl = '';
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Ad'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Select Image'),
                  ),
                  onPressed: () async {
                    pickMultipleFiles();
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Ad visit URL',
                      prefixIcon: Icon(Icons.ad_units)),
                  onChanged: (value) => adUrl = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an Ad visit URL';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Add'),
              onPressed: () async {
                if (formKey.currentState!.validate() && files.isNotEmpty) {
                  await uploadFilesToFireStore(files, adUrl, context);
                  Navigator.of(context).pop();
                } else if (files.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select an image')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> pickMultipleFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['png', 'jpeg', 'jpg'],
    );
    if (result != null) {
      setState(() {
        files = result.files;
      });
    }
  }

  Future<void> uploadFilesToFireStore(
      List<PlatformFile> files, String adUrl, BuildContext context) async {
    ProgressDialog pd = ProgressDialog(context: context);
    pd.show(
      max: files.length * 100,
      msg: 'Uploading...',
      progressBgColor: Colors.black26,
      msgColor: Colors.white,
      backgroundColor: const Color(0xFF1A74BD),
      progressValueColor: Colors.white,
    );

    try {
      for (PlatformFile file in files) {
        // Start time for time measurement
        DateTime startTime = DateTime.now();
        // Extract file name without extension
        String fileNameWithoutExtension = file.name.split('.').first;
        // Extract file extension
        String fileExtension = file.name.split('.').last;
        // Upload the file to Firebase Storage
        String fileName =
            '${DateTime.now().millisecondsSinceEpoch}_$fileNameWithoutExtension.$fileExtension';

        UploadTask uploadTask =
            FirebaseStorage.instance.ref('Ads').child(fileName).putData(
                  file.bytes!,
                  SettableMetadata(contentType: getFileContentType(file.name)),
                );

        // Monitoring the upload progress
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          int percentage =
              ((snapshot.bytesTransferred / snapshot.totalBytes) * 100).toInt();
          pd.update(
            msg: 'Uploading... ${percentage.toStringAsFixed(2)}%',
          );
        });

        // Get the download URL and the storage location URL of the uploaded file after completion
        TaskSnapshot taskSnapshot = await uploadTask;
        String downloadURL = await taskSnapshot.ref.getDownloadURL();
        // End time for time measurement
        DateTime endTime = DateTime.now();
        print(downloadURL);

        // Calculate time taken for upload
        Duration uploadDuration = endTime.difference(startTime);
        if (kDebugMode) {
          print('Upload completed in ${uploadDuration.inSeconds} seconds');
        }

        // Create a Firestore document to store file metadata
        Map<String, dynamic> fileData = {
          'adUrl': adUrl,
          'imageUrl': downloadURL,
        };

        // Check if the 'Ads' collection exists under the specified path
        bool collectionExists = await FirebaseFirestore.instance
            .collection('Ads')
            .get()
            .then((snapshot) => snapshot.docs.isNotEmpty);

        if (!collectionExists) {
          // If the collection doesn't exist, create it
          await FirebaseFirestore.instance
              .doc(fileName) // Use the same fileName as the document ID
              .set(fileData);
        } else {
          // If the collection exists, add the file data
          await FirebaseFirestore.instance
              .collection('Ads')
              .doc(fileName) // Use the same fileName as the document ID
              .set(fileData);
        }
      }

      pd.close();
      // Show a SnackBar to indicate upload completion
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF2880BC),
          content: Text('Files uploaded successfully!'),
        ),
      );
    } catch (error) {
      pd.close();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error uploading file to Firestore: $error'),
        ),
      );
      rethrow; // Re-throw the error to propagate it
    }
  }

  String getFileContentType(String fileName) {
    if (fileName.endsWith('.png')) {
      return 'image/png';
    } else if (fileName.endsWith('.jpeg') || fileName.endsWith('.jpg')) {
      return 'image/jpeg';
    }
    // Default to octet-stream if content type is unknown
    return 'application/octet-stream';
  }
}

class UserManagement extends ConsumerStatefulWidget {
  const UserManagement({super.key});
  @override
  _UserManagementState createState() => _UserManagementState();
}

class _UserManagementState extends ConsumerState<UserManagement> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('Users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<QueryDocumentSnapshot> userDocs = snapshot.data!.docs;
        final List<QueryDocumentSnapshot> filteredDocs = userDocs
            .where((doc) => (doc.data() as Map<String, dynamic>)['name']
                .toString()
                .toLowerCase()
                .contains(searchQuery))
            .toList();

        if (filteredDocs.isEmpty) {
          return const Center(child: Text('No match available'));
        }

        return ListView.builder(
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            Map<String, dynamic> data =
                filteredDocs[index].data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                  child: ListTile(
                leading: CircleAvatar(child: Text(data['name']?[0] ?? 'U')),
                title: Text(data['name'] ?? 'No name',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Program: ${data['program'] ?? 'N/A'}'),
                trailing: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildRoleSwitch(data, 'editor', filteredDocs[index].id),
                      const SizedBox(width: 8),
                      _buildRoleSwitch(data, 'admin', filteredDocs[index].id),
                    ],
                  ),
                ),
              )),
            );
          },
        );
      },
    );
  }

  Widget _buildRoleSwitch(
      Map<String, dynamic> data, String role, String docId) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(role.capitalize(), style: const TextStyle(fontSize: 12)),
        Switch(
          value: data[role] ?? false,
          onChanged: (value) => _updateUserField(docId, role, value),
          activeColor: Colors.green,
        ),
      ],
    );
  }

  void _updateUserField(String docId, String field, bool value) {
    _firestore.collection('Users').doc(docId).update({field: value});
  }
}

class AdManagement extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AdManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('Ads').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            Map<String, dynamic> data =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.ad_units, color: Colors.blue),
                title: Text(data['adUrl'] ?? 'No Ad URL',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(data['imageUrl'] ?? 'No Image URL'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteAd(snapshot.data!.docs[index].id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _deleteAd(String docId) {
    _firestore.collection('Ads').doc(docId).delete();
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
