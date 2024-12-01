import 'package:flutter/material.dart';

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

  DiaryEntry({required this.title, required this.content});
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
  void _addDiaryEntry(String title, String content) {
    setState(() {
      _diaryEntries.add(DiaryEntry(title: title, content: content));
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
                  title: Text(entry.title),
                  subtitle: Text(
                    entry.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    // 日記詳細画面に遷移
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
class NewEntryPage extends StatelessWidget {
  final Function(String, String) onSave;

  const NewEntryPage({Key? key, required this.onSave}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();

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
                border: OutlineInputBorder(), // 境界線を追加
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(), // 境界線を追加
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    contentController.text.isNotEmpty) {
                  onSave(titleController.text, contentController.text);
                  Navigator.pop(context); // 保存後に戻る
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
