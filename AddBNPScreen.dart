import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';
class AddBNPScreen extends StatefulWidget {
  final String selectedCourse;
  const AddBNPScreen({super.key, required this.selectedCourse});
  @override
  _DocumentUploadScreenState createState() => _DocumentUploadScreenState();
}
class _DocumentUploadScreenState extends State<AddBNPScreen> {
  List<PlatformFile> files = [];
  late String tabSelected;
  bool showProgress = false;
  Future<void> pickMultipleFiles(String tabSelected) async {
    this.tabSelected = tabSelected;
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpeg', 'jpg'],
    );
    if (result != null) {
      setState(() {
        files = result.files;
        showProgress = true;
      });
      uploadFilesToFirestore(files, context);
    }
  }
  Future<void> uploadFilesToFirestore(
      List<PlatformFile> files, BuildContext context) async {
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
      SharedPreferences? prefs = await SharedPreferences.getInstance();
      String? program = prefs.getString("selectedProgram");

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

        UploadTask uploadTask = FirebaseStorage.instance
            .ref('Programs/$program/Courses/${widget.selectedCourse}/$tabSelected')
            .child(fileName)
            .putData(
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
        String storageLocationURL =
            'gs://${taskSnapshot.ref.bucket}/${taskSnapshot.ref.fullPath}';

        // End time for time measurement
        DateTime endTime = DateTime.now();
        print(downloadURL);
        print(storageLocationURL);

        // Calculate time taken for upload
        Duration uploadDuration = endTime.difference(startTime);
        if (kDebugMode) {
          print('Upload completed in ${uploadDuration.inSeconds} seconds');
        }

        // Create a Firestore document to store file metadata
        Map<String, dynamic> fileData = {
          'Name': fileNameWithoutExtension, // Use the name without extension
          'Url': downloadURL,
          'StorageLocation': storageLocationURL,
        };

        // Check if the 'tabSelected' collection exists under the specified path
        bool collectionExists = await FirebaseFirestore.instance
            .collection('Programs')
            .doc(program)
            .collection('Courses')
            .doc(widget.selectedCourse)
            .collection(tabSelected)
            .get()
            .then((snapshot) => snapshot.docs.isNotEmpty);

        if (!collectionExists) {
          // If the collection doesn't exist, create it
          await FirebaseFirestore.instance
              .collection('Programs')
              .doc(program)
              .collection('Courses')
              .doc(widget.selectedCourse)
              .collection(tabSelected)
              .doc(fileName) // Use the same fileName as the document ID
              .set(fileData);
        } else {
          // If the collection exists, add the file data
          await FirebaseFirestore.instance
              .collection('Programs')
              .doc(program)
              .collection('Courses')
              .doc(widget.selectedCourse)
              .collection(tabSelected)
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
    if (fileName.endsWith('.pdf')) {
      return 'application/pdf';
    } else if (fileName.endsWith('.png')) {
      return 'image/png';
    } else if (fileName.endsWith('.jpeg') || fileName.endsWith('.jpg')) {
      return 'image/jpeg';
    } else if (fileName.endsWith('.pptx')) {
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    }
    // Default to octet-stream if content type is unknown
    return 'application/octet-stream';
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(right: 4.0, left: 4, bottom: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    const Text(
                      'Upload Study Material of',
                      style: TextStyle(
                          fontSize: 24,
                          color: Color(0xFF1A74BD),
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.selectedCourse,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A74BD)),
                    ),
                  ],
                ),
              ],
            ),
            Image.asset(
              'assets/images/upload.png', // Replace with your image path
              width: 300,
              height: 300,
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.all(4.0),
              child: Text(
                'Note: Please make sure that the document you are uploading has a name that accurately reflects its content.',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.red,
                    fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: ElevatedButton(
                    onPressed: () {
                      pickMultipleFiles("Books");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A74BD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add,
                          color: Colors.white,
                        ), // Add your icon here
                        SizedBox(height: 5), // Spacer between icon and text
                        Text(
                          'Upload Books',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 100,
                  height: 100,
                  child: ElevatedButton(
                    onPressed: () {
                      pickMultipleFiles("Notes");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A74BD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add,
                          color: Colors.white,
                        ), // Add your icon here
                        SizedBox(height: 5), // Spacer between icon and text
                        Text(
                          'Upload Notes',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 100,
                  height: 100,
                  child: ElevatedButton(
                    onPressed: () {
                      pickMultipleFiles("Papers");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A74BD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add,
                          color: Colors.white,
                        ), // Add your icon here
                        SizedBox(height: 5), // Spacer between icon and text
                        Text(
                          'Upload Papers',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

