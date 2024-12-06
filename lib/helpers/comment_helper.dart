// helpers/comment_helper.dart
import 'dart:math';

class CommentHelper {
  static List<String> positiveComments = [
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

  static final List<String> replyComments = [
    "This is so cool! I'd love to visit there someday! 😍",
    "Where is this place? It looks amazing! 🌍",
    "Wow, this made my day better! Thanks for sharing! 😊",
    "Absolutely love this! You have such a good eye for beauty! 🎨",
    "I went there last week, and it was wonderful! Totally agree with you! 💯",
    "This is such a positive vibe! Keep posting more! ✨",
    "Haha, this is great! Looks like so much fun! 😂",
    "This post is a gem! 💎",
    "I'm definitely adding this to my bucket list! 📌",
    "Thanks for sharing! Really inspiring! 🥰"
  ];

  // ランダムなポジティブコメントを取得
  static String getRandomComment() {
    return positiveComments[Random().nextInt(positiveComments.length)];
  }

  // ランダムな返信コメントを取得
  static String getRandomReply() {
    return replyComments[Random().nextInt(replyComments.length)];
  }

  // ランダムに複数のコメントを生成（メインコメント＋返信）
  static List<String> getRandomCommentsWithReplies(int numberOfReplies) {
    List<String> comments = [];
    // メインのポジティブコメント
    comments.add(getRandomComment());

    // ランダムに指定された数の返信を追加
    for (int i = 0; i < numberOfReplies; i++) {
      comments.add(getRandomReply());
    }

    return comments;
  }
}