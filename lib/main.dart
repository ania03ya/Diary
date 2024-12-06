import 'package:flutter/material.dart';
import 'dart:io'; // images
import 'package:image_picker/image_picker.dart'; // images
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'helpers/image_helper.dart'; // 画像ヘルパーのインポート
import 'helpers/location_helper.dart'; // 位置情報ヘルパー
import 'helpers/firestore_helper.dart'; // Firestoreヘルパー
import 'helpers/comment_helper.dart'; // コメントヘルパー
import 'firebase_options.dart';
import 'dart:math'; // ランダム生成に使用

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter の初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const DiaryApp());
}

// アプリ全体の構成
class DiaryApp extends StatelessWidget {
  const DiaryApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diary App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

// 日記のデータモデル
class DiaryEntry {
  final String title;
  final String content;
  final File? image; // ローカル画像ファイル
  final String? imageUrl; // Firebase Storage の画像 URL
  final String? location; // 位置情報を追加
  final String? comment; // コメントを追加
  final List<String>? comments; // 複数のコメントを追加
  final DateTime createdAt;
  final int likeCount; // いいねの数を追加

  DiaryEntry({
    required this.title,
    required this.content,
    this.image,
    this.imageUrl,
    this.location,
    this.comment,
    required this.createdAt,
    required this.likeCount, // コンストラクタに追加
  });
}

// ホームページ
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<DiaryEntry> _diaryEntries = [];
  String _searchQuery = '';

  // Firestoreから日記エントリーを読み込むメソッド
  @override
  void initState() {
    super.initState();
    _loadDiaryEntries();
  }

  void _loadDiaryEntries() async {
    List<Map<String, dynamic>> entries =
        await FirestoreHelper.getDiaryEntries();
    setState(() {
      _diaryEntries.clear();
      for (var data in entries) {
        _diaryEntries.add(
          DiaryEntry(
            title: data['title'] ?? '',
            content: data['content'] ?? '',
            image: null, // ローカルには画像ファイルは保持しない
            imageUrl: data['image_url'], // Firestoreからの画像URLを設定
            location: data['location'],
            comment: data['comment'],
            createdAt:
                DateTime.fromMillisecondsSinceEpoch(data['created_at'] ?? 0),
            likeCount: data['like_count'] ?? 0,
          ),
        );
      }
    });
  }

  // 新しい日記を追加するメソッド
  void _addDiaryEntry(
      String title, String content, File? image, String? location) async {
    String randomComment = CommentHelper.getRandomComment();
    int randomLikeCount = Random().nextInt(100); // 0から99のランダムないいね数を生成
    DateTime now = DateTime.now(); // 現在時刻を取得

    // 画像をFirebase Storageにアップロード
    String? imageUrl;
    if (image != null) {
      imageUrl = await ImageHelper.uploadImage(image);
    }

    // Firestoreに保存するデータを構成
    Map<String, dynamic> entryData = {
      'title': title,
      'content': content,
      'location': location,
      'comment': [
        randomComment,
        CommentHelper.getRandomReply(), // 返信コメントも追加
        CommentHelper.getRandomReply() // 複数のコメントを追加
      ], // コメントのリストをFirestoreに保存
      'like_count': randomLikeCount, // Like 数を追加
      'created_at': now.millisecondsSinceEpoch, // 'now' を使用して作成日時を追加
      'image_url': imageUrl, // アップロードした画像のURLを保存
    };

    // Firestoreにデータを追加
    FirestoreHelper.addDiaryEntry(entryData);

    setState(() {
      _diaryEntries.add(
        DiaryEntry(
          title: entryData['title'] ?? '',
          content: entryData['content'] ?? '',
          image: image, // ローカルでの表示用
          location: entryData['location'],
          comment: entryData['comment'],
          createdAt: now, // 'now' を使用して作成日時を追加
          likeCount: entryData['like_count'] ?? 0, // Firestoreからのlike_countを追加
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    List<DiaryEntry> filteredEntries = _diaryEntries
        .where((entry) =>
            entry.title.contains(_searchQuery) ||
            entry.content.contains(_searchQuery))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Diary'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
              ),
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
              },
            ),
          ),
          Expanded(
            child: filteredEntries.isEmpty
                ? const Center(
                    child: Text('No diary entries found.'),
                  )
                : ListView.builder(
                    itemCount: filteredEntries.length,
                    itemBuilder: (context, index) {
                      final entry = filteredEntries[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          elevation: 5,
                          child: Column(
                            children: [
                              if (entry.imageUrl != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(15.0)),
                                  child: Image.network(
                                    entry.imageUrl!,
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ListTile(
                                contentPadding: const EdgeInsets.all(16.0),
                                title: Text(
                                  entry.title,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.content,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (entry.location != null)
                                      Text(
                                        '📍 ${entry.location}',
                                        style:
                                            TextStyle(color: Colors.blueAccent),
                                      ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '❤️ ${entry.likeCount}',
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.red),
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DiaryDetailPage(entry: entry),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewEntryPage(onSave: _addDiaryEntry),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// 新規日記投稿画面
class NewEntryPage extends StatefulWidget {
  final Function(String, String, File?, String?) onSave;

  const NewEntryPage({Key? key, required this.onSave}) : super(key: key);

  @override
  _NewEntryPageState createState() => _NewEntryPageState();
}

class _NewEntryPageState extends State<NewEntryPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  File? _selectedImage;
  String? _currentLocation;

  // 非同期で画像をピックするメソッド
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  // Firebase Storageに画像をアップロードするメソッド
  Future<String?> _uploadImage(File image) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef =
          FirebaseStorage.instance.ref().child('diary_images').child(fileName);
      UploadTask uploadTask = storageRef.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  // 位置情報を取得するメソッド
  Future<void> _getCurrentLocation() async {
    String? location = await LocationHelper.getCurrentLocation();
    setState(() {
      _currentLocation = location;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Diary Entry'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            _selectedImage != null
                ? Image.file(
                    _selectedImage!,
                    height: 150,
                    fit: BoxFit.cover,
                  )
                : const Text('No image selected.'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo),
              label: const Text('Add Photo'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.location_on),
              label: const Text('Get Current Location'),
            ),
            if (_currentLocation != null) Text('Location: $_currentLocation'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    contentController.text.isNotEmpty) {
                  widget.onSave(
                    titleController.text,
                    contentController.text,
                    _selectedImage,
                    _currentLocation,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class ImageHelper {
  static Future<String?> uploadImage(File image) async {
    try {
      // Firebase Storage の参照を取得
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('diary_images/${DateTime.now().millisecondsSinceEpoch}.jpg');

      // 画像をアップロード
      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot snapshot = await uploadTask;

      // アップロードが完了したら画像の URL を取得
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
}

// 日記詳細画面でコメントを表示
class DiaryDetailPage extends StatelessWidget {
  final DiaryEntry entry;

  const DiaryDetailPage({Key? key, required this.entry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(entry.title),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry.imageUrl != null)
            Image.network(
              entry.imageUrl!,
              fit: BoxFit.cover,
            ),
          const SizedBox(height: 16),
          Text(
            entry.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(
            entry.content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (entry.location != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text('Location: ${entry.location}'),
            ),
          const SizedBox(height: 16),
          if (entry.comments != null && entry.comments!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entry.comments!.map((comment) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.comment, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        comment,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Back'),
          ),
        ],
      ),
    ),
  );
 }
}