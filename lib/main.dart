import 'package:flutter/material.dart';
import 'dart:io'; //images
import 'package:image_picker/image_picker.dart'; //images
import 'package:geolocator/geolocator.dart'; // 位置情報
import 'package:geocoding/geocoding.dart'; // 逆ジオコーディング
import 'dart:math'; // ランダム生成に使用
List<String> positiveComments = [
  "Great job! 😊",
  "You're amazing! 🌟",
  "Keep it up! 💪",
  "This is so inspiring! ✨",
  "Well done! 👏",
  "You did fantastic today! ❤️",
  "Keep shining! ☀️",
  "You're on the right track! 🚀",
  "Love this! ❤️",
  "Your thoughts are beautiful! 💖"
];

void main() {
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
  final File? image; // images
  final String? location; // 位置情報を追加
  final String? comment; // コメントを追加

  DiaryEntry({required this.title, required this.content, this.image, this.location,this.comment, // コメントをコンストラクタに追加
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

  // 新しい日記を追加するメソッド
void _addDiaryEntry(String title, String content, File? image, String? location) {
  setState(() {
    String randomComment = positiveComments[Random().nextInt(positiveComments.length)];
    _diaryEntries.add(DiaryEntry(
      title: title,
      content: content,
      image: image,
      location: location,
      comment: randomComment, // ランダムなコメントを追加
    ));
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Diary'),
      ),
      body: _diaryEntries.isEmpty
          ? const Center(
              child: Text('No diary entries yet.'),
            )
          : ListView.builder(
              itemCount: _diaryEntries.length,
              itemBuilder: (context, index) {
                final entry = _diaryEntries[index];
                return ListTile(
                  leading: entry.image != null
                      ? Image.file(
                          entry.image!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image),
                  title: Text(entry.title),
                  subtitle: Text(
                    entry.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DiaryDetailPage(entry: entry),
                      ),
                    );
                  },
                );
              },
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
  bool _isRequestingLocation = false;

  // 非同期で画像をピックするメソッド
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker(); // pickerをここで定義
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800, // 画像の幅を制限
        maxHeight: 800, // 画像の高さを制限
        imageQuality: 80, // 画像のクオリティを下げてファイルサイズを小さく
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path); // 画像を保持
        });
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  // 位置情報を取得するメソッド
  Future<void> _getCurrentLocation() async {
    if (_isRequestingLocation) {
      // すでにリクエスト中の場合は何もしない
      return;
    }

    setState(() {
      _isRequestingLocation = true;
    });

    try {
      bool serviceEnabled;
      LocationPermission permission;

      // 位置情報サービスが有効かどうかを確認
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // 位置情報サービスが無効の場合は終了
        print("Location services are disabled.");
        return;
      }

      // 必要な位置情報の許可をリクエスト
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print("Location permissions are denied.");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print("Location permissions are permanently denied.");
        return;
      }

      // 現在位置を取得
      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
      setState(() {
        _currentLocation = "${place.name}, ${place.locality}, ${place.country}";
      });
      }
    } catch (e) {
      print("Error getting location: $e");
    } finally {
      setState(() {
        _isRequestingLocation = false;
      });
    }
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
                  ) // 画像を表示
                : const Text('No image selected.'), // 画像が選択されていない場合のメッセージ
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickImage, // 画像選択ボタン
              icon: const Icon(Icons.photo),
              label: const Text('Add Photo'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isRequestingLocation ? null : _getCurrentLocation, // リクエスト中は無効
              icon: const Icon(Icons.location_on),
              label: const Text('Get Current Location'),
            ),
            if (_currentLocation != null) Text('Location: $_currentLocation'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
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
            if (entry.image != null)
              Image.file(entry.image!, fit: BoxFit.cover),
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
            if (entry.comment != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.red), // ❤️アイコン
                    const SizedBox(width: 8),
                    Text(
                      entry.comment!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
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