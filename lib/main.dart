import 'package:flutter/material.dart';
import 'dart:io'; // images
import 'package:image_picker/image_picker.dart'; // images
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:floating_bubbles/floating_bubbles.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'helpers/image_helper.dart'; // 画像ヘルパーのインポート
import 'helpers/location_helper.dart'; // 位置情報ヘルパー
import 'helpers/firestore_helper.dart'; // Firestoreヘルパー
import 'helpers/comment_helper.dart'; // コメントヘルパー
import 'components/star_thumb_shape.dart';
import 'firebase_options.dart';
import 'dart:math'; // ランダム生成に使用

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter の初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);

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
        scaffoldBackgroundColor: const Color(0xFFB9BFAF),
        sliderTheme: const SliderThemeData(
          thumbShape: StarThumbShape(),
        ),
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
  final List<String>? comments; // 複数のコメントを追加
  final DateTime createdAt;
  final int likeCount; // いいねの数を追加

  DiaryEntry({
    required this.title,
    required this.content,
    this.image,
    this.imageUrl,
    this.location,
    this.comments,
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
  double _currentSliderValue = 20;

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
            comments: data['comments'],
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
      'comments': [
        randomComment,
        CommentHelper.getRandomReply(), // 返信コメントも追加
        CommentHelper.getRandomReply(), // 複数のコメントを追加
        CommentHelper.getRandomCommentsWithReplies(2), // 返信コメント2つを含むコメントリスト
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
          comments: entryData['comment'],
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
        backgroundColor: const Color(0xFFB9BFAF),
        title: GradientText(
          'BlissBoard',
          style: const TextStyle(fontSize: 30, fontFamily: 'IrishGrover'),
          gradientType: GradientType.linear,
          gradientDirection: GradientDirection.ttb,
          colors: const [
            Color(0xffFED418),
            Color(0xffFCAE00),
          ],
          stops: const [
            0.27,
            1,
          ],
        ),
        centerTitle: false,
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.menu),
            iconSize: 41,
            color: const Color(0xff585836),
          )
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: FloatingBubbles(
              noOfBubbles: 25,
              colorsOfBubbles: [
                Colors.green.withAlpha(30),
                Colors.red,
              ],
              sizeFactor: 0.16,
              duration: 120, // 120 seconds.
              opacity: 70,
              paintingStyle: PaintingStyle.fill,
              strokeWidth: 8,
              shape: BubbleShape
                  .circle, // circle is the default. No need to explicitly mention if its a circle.
              speed: BubbleSpeed.normal, // normal is the default
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundImage:
                          const AssetImage('assets/icons/avatar.png'),
                      // imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                      backgroundColor: Colors
                          .grey.shade200, // A default color for the avatar
                      child: null,
                      // child: imageUrl.isEmpty ? Text(userInitials) : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 29),
                      child: Column(
                        children: [
                          GradientText(
                            'USER NAME',
                            style: const TextStyle(
                                fontSize: 30, fontFamily: 'IrishGrover'),
                            gradientType: GradientType.linear,
                            gradientDirection: GradientDirection.ttb,
                            colors: const [
                              Color(0xff948D6C),
                              Color(0xff444242),
                            ],
                            stops: const [
                              0,
                              0.65,
                            ],
                          ),
                          Slider(
                            value: _currentSliderValue,
                            max: 100,
                            label: _currentSliderValue.round().toString(),
                            activeColor: const Color(0xff585836),
                            onChanged: (double value) {
                              setState(() {
                                _currentSliderValue = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
                    : GridView.builder(
                        padding: const EdgeInsets.all(10),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // カラム数
                          crossAxisSpacing: 10, // カラム間の間隔
                          mainAxisSpacing: 10, // 行間の間隔
                          childAspectRatio: 3 / 4, // カードの縦横比
                        ),
                        itemCount: filteredEntries.length,
                        itemBuilder: (context, index) {
                          final entry = filteredEntries[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DiaryDetailPage(entry: entry),
                                ),
                              );
                            },
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (entry.imageUrl != null)
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(15),
                                      ),
                                      child: Image.network(
                                        entry.imageUrl!,
                                        height: 120,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  else
                                    const Icon(
                                      Icons.image,
                                      size: 120,
                                      color: Colors.grey,
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      entry.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: Text(
                                      entry.content,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
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
            _buildCommentsSection(context, entry),
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

  Widget _buildCommentsSection(BuildContext context, DiaryEntry entry) {
    // 擬似コメントデータ
    List<Map<String, String>> subComments = [
      {"name": "UserA", "comment": "この場所最高ですね！どこですか？"},
      {"name": "UserB", "comment": "前に行ったことがあります！おすすめです！"},
      {"name": "UserC", "comment": "素敵な写真ですね。"}
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: subComments.length,
          itemBuilder: (context, index) {
            final subComment = subComments[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 16,
                    child: Icon(Icons.person, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subComment["name"]!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          subComment["comment"]!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
