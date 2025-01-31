import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'helpers/auth_helper.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final PageController pageController =
      PageController(viewportFraction: 1, keepPage: true);
  int _currentIndex = 0;

  Future<void> _login() async {
    try {
      await AuthHelper.signInWithPassword(
        emailController.text,
        passwordController.text,
      );
    } catch (e) {
      // Handle login error
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool firstSlide = _currentIndex == 0;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: PageView(
              controller: pageController,
              onPageChanged: (int index) => _onPageChanged(index),
              children: [
                Container(color: Colors.grey),
                Container(color: Colors.white),
              ],
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('ステキな日も、そうじゃなかった日も',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: firstSlide ? Colors.white : Colors.deepPurple, fontSize: 19)),
                  const SizedBox(height: 56),
                  SmoothPageIndicator(
                    controller: pageController,
                    count: 2,
                    effect: ExpandingDotsEffect(
                        dotWidth: 6,
                        dotHeight: 6,
                        dotColor: firstSlide ? Colors.white : Colors.grey,
                        activeDotColor: Colors.blueGrey),
                  ),
                  // TextField(
                  //   controller: emailController,
                  //   decoration: const InputDecoration(labelText: 'Email'),
                  // ),
                  // TextField(
                  //   controller: passwordController,
                  //   decoration: const InputDecoration(labelText: 'Password'),
                  //   obscureText: true,
                  // ),
                  const SizedBox(height: 36),
                  OutlinedButton(
                    onPressed: _login,
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(firstSlide ? Colors.white : Colors.deepPurple),
                      side: WidgetStateProperty.all(BorderSide(color: firstSlide ? Colors.grey : Colors.white)),
                    ),
                    child: Text('Log In', style: TextStyle(color: firstSlide ? Colors.black : Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
