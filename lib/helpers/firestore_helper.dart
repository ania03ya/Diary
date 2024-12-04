import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreHelper {
  // Firestore のインスタンスを static にする
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Firestore に日記エントリーを追加するメソッド
  static Future<void> addDiaryEntry(Map<String, dynamic> entryData) async {
    try {
      await firestore.collection('diary_entries').add(entryData);
    } catch (e) {
      print("Error adding diary entry to Firestore: $e");
    }
  }

  // Firestore から日記エントリーを取得するメソッド
  static Future<List<Map<String, dynamic>>> getDiaryEntries() async {
    try {
      // Firestoreからデータを取得
      QuerySnapshot snapshot = await firestore
          .collection('diary_entries')
          .orderBy('created_at', descending: true)
          .get();

      // ドキュメントからデータをリストとして変換
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print("Error fetching diary entries from Firestore: $e");
      return [];
    }
  }
}
