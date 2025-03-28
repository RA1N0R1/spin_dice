import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

final _history = <int>[];
final _stats = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};

void main() async {
  final app = Router();

  app.post('/roll', (Request request) async {
    final randomValue = Random().nextInt(6) + 1;

    // Обновляем историю и статистику
    _history.add(randomValue);
    if (_history.length > 10) _history.removeAt(0);
    _stats[randomValue] = _stats[randomValue]! + 1;

    return Response.ok(
      json.encode({
        'value': randomValue,
        'stats': _stats,
        'history': _history.reversed.toList(),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  });

  final server = await serve(app, '0.0.0.0', 8080);
  print('Server running on http://${server.address.host}:${server.port}');
}
