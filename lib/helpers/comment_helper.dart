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

  static String getRandomComment() {
    return positiveComments[Random().nextInt(positiveComments.length)];
  }
}
