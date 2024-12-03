// helpers/firestore_helper.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> addDiaryEntry(Map<String, dynamic> entryData) async {
    try {
      await _firestore.collection('diary_entries').add(entryData);
    } catch (e) {
      print("Error adding diary entry to Firestore: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> getDiaryEntries() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('diary_entries')
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print("Error fetching diary entries from Firestore: $e");
      return [];
    }
  }
}
