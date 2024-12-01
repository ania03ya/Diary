import 'package:flutter/material.dart';

void main() {
  runApp(const DiaryApp());
}

class DiaryApp extends StatelessWidget {
  const DiaryApp({Key? key}) : super(key: key); // constを追加

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diary App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(), // constを追加
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key); // constを追加

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Diary'), // constを追加
      ),
      body: const Center(
        child: Text('Welcome to the Diary App!'), // constを追加
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewEntryPage(), // 投稿画面へ遷移
            ),
          );
        },
        child: const Icon(Icons.add), // constを追加
      ),
    );
  }
}

class NewEntryPage extends StatelessWidget {
  const NewEntryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Diary Entry'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(), // 境界線を追加
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(), // 境界線を追加
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // 保存処理を追加
                  Navigator.pop(context); // 保存後に前の画面に戻る
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
