import 'package:flutter/material.dart';
import 'dart:async';
import 'AboutAppScreen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    // Animation for logo scaling
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
    _navigateToNextScreen();
  }

  // Wait for 3 seconds to show splash screen
  _navigateToNextScreen() async {
    await Future.delayed(Duration(seconds: 3));  // Simulating loading screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AboutAppScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _animation.value,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.airplanemode_active,
                    color: Colors.white,
                    size: 120 * _animation.value,  // Animated scaling
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Travel App',
                    style: TextStyle(
                      fontSize: 32 * _animation.value,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
