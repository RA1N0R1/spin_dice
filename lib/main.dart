import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final savedNickname = prefs.getString('nickname');

  runApp(MaterialApp(
    title: 'Spin Dice',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      primarySwatch: Colors.blue,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          textStyle: const TextStyle(fontSize: 20),
        ),
      ),
    ),
    home: savedNickname == null
        ? const NicknameScreen()
        : DicePage(nickname: savedNickname),
  ));
}

class NicknameScreen extends StatefulWidget {
  const NicknameScreen({super.key});

  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  final TextEditingController _nicknameController = TextEditingController();

  Widget _buildDiceFace() {
    const double dotSize = 12;
    const Color dotColor = Colors.black;

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(top: 20, left: 20, child: _buildDot(dotSize, dotColor)),
          Center(child: _buildDot(dotSize, dotColor)),
          Positioned(
              bottom: 20, right: 20, child: _buildDot(dotSize, dotColor)),
        ],
      ),
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

  void _proceedToDicePage() async {
    if (_nicknameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите никнейм!')),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nickname', _nicknameController.text);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DicePage(nickname: _nicknameController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Spin Dice - Вход'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDiceFace(),
              const SizedBox(height: 40),
              TextField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  labelText: 'Ваш никнейм',
                  labelStyle: const TextStyle(color: Colors.green),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _proceedToDicePage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text(
                  'Играть',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DicePage extends StatefulWidget {
  final String nickname;
  const DicePage({super.key, required this.nickname});

  @override
  State<DicePage> createState() => _DicePageState();
}

class _DicePageState extends State<DicePage>
    with SingleTickerProviderStateMixin {
  int _currentDiceValue = 1;
  bool _isRolling = false;
  late AnimationController _controller;
  late final String _serverUrl =
      dotenv.env['SERVER_URL'] ?? 'http://localhost:8080';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _isRolling = false);
        }
      });
  }

  Future<void> _rollDice() async {
    if (_isRolling) return;

    setState(() => _isRolling = true);
    _controller.reset();
    _controller.forward();

    try {
      final response = await http.post(
        Uri.parse('$_serverUrl/roll'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nickname': widget.nickname}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _currentDiceValue = responseData['value'];
        });
      } else {
        _fallbackRoll();
      }
    } catch (e) {
      print('Ошибка соединения с сервером: $e');
      _fallbackRoll();
    }
  }

  void _fallbackRoll() {
    setState(() {
      _currentDiceValue = Random().nextInt(6) + 1;
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
          )
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
        title: const Text('Spin Dice'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, size: 30),
            color: Colors.red,
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('nickname');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const NicknameScreen()),
              );
            },
          ),
        ],
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
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(
                _isRolling ? 'Кубик крутится...' : 'Бросить кубик',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Текущее значение: $_currentDiceValue',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              'Игрок: ${widget.nickname}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
