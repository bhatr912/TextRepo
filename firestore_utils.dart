import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

Future<Map<String, dynamic>?> getUserFields(String email) async {
  try {
    final docSnapshot = await FirebaseFirestore.instance.collection('Users').doc(email).get();
    if (docSnapshot.exists) {
      return docSnapshot.data();
    } else {
      if (kDebugMode) {
        print("User document does not exist for email: $email");
      }
      return null;
    }
  } catch (e) {
    if (kDebugMode) {
      print("Error fetching user fields: $e");
    }
    return null;
  }
}
