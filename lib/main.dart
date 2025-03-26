import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const DiceApp());
}

class DiceApp extends StatelessWidget {
  const DiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dice Roller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DicePage(),
    );
  }
}

class DicePage extends StatefulWidget {
  const DicePage({super.key});

  @override
  State<DicePage> createState() => _DicePageState();
}

class _DicePageState extends State<DicePage>
    with SingleTickerProviderStateMixin {
  int _currentDiceValue = 1;
  bool _isRolling = false;
  late AnimationController _controller;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // Быстрое вращение (300 мс)
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _isRolling = false;
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _rollDice() {
    if (_isRolling) return;

    setState(() {
      _isRolling = true;
    });

    _controller.reset();
    _controller.forward();

    // Показываем результат через 200 мс (раньше завершения анимации)
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        _currentDiceValue = _random.nextInt(6) + 1;
      });
    });
  }

  Widget _buildDiceFace(int value) {
    const double dotSize = 20;
    const Color dotColor = Colors.black;

    List<Widget> dots = [];

    switch (value) {
      case 1:
        dots = [Center(child: _buildDot(dotSize, dotColor))];
        break;
      case 2:
        dots = [
          Positioned(top: 20, left: 20, child: _buildDot(dotSize, dotColor)),
          Positioned(
              bottom: 20, right: 20, child: _buildDot(dotSize, dotColor)),
        ];
        break;
      case 3:
        dots = [
          Positioned(top: 20, left: 20, child: _buildDot(dotSize, dotColor)),
          Center(child: _buildDot(dotSize, dotColor)),
          Positioned(
              bottom: 20, right: 20, child: _buildDot(dotSize, dotColor)),
        ];
        break;
      case 4:
        dots = [
          Positioned(top: 20, left: 20, child: _buildDot(dotSize, dotColor)),
          Positioned(top: 20, right: 20, child: _buildDot(dotSize, dotColor)),
          Positioned(bottom: 20, left: 20, child: _buildDot(dotSize, dotColor)),
          Positioned(
              bottom: 20, right: 20, child: _buildDot(dotSize, dotColor)),
        ];
        break;
      case 5:
        dots = [
          Positioned(top: 20, left: 20, child: _buildDot(dotSize, dotColor)),
          Positioned(top: 20, right: 20, child: _buildDot(dotSize, dotColor)),
          Center(child: _buildDot(dotSize, dotColor)),
          Positioned(bottom: 20, left: 20, child: _buildDot(dotSize, dotColor)),
          Positioned(
              bottom: 20, right: 20, child: _buildDot(dotSize, dotColor)),
        ];
        break;
      case 6:
        dots = [
          Positioned(top: 20, left: 20, child: _buildDot(dotSize, dotColor)),
          Positioned(top: 20, right: 20, child: _buildDot(dotSize, dotColor)),
          Positioned(top: 70, left: 20, child: _buildDot(dotSize, dotColor)),
          Positioned(top: 70, right: 20, child: _buildDot(dotSize, dotColor)),
          Positioned(bottom: 20, left: 20, child: _buildDot(dotSize, dotColor)),
          Positioned(
              bottom: 20, right: 20, child: _buildDot(dotSize, dotColor)),
        ];
        break;
      default:
        dots = [Center(child: _buildDot(dotSize, dotColor))];
    }

    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(children: dots),
    );
  }

  Widget _buildDot(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Dice Roller'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _controller.value * 2 * pi,
                  child: child,
                );
              },
              child: _buildDiceFace(_currentDiceValue),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isRolling ? null : _rollDice,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: const TextStyle(fontSize: 20),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text(
                _isRolling ? 'Rolling...' : 'Roll Dice',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
