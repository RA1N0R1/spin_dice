import 'dart:io';
import 'dart:math';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

void main() async {
  final app = Router();
  final random = Random();
  final serverIp = InternetAddress.anyIPv4;
  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_enableCors)
      .addHandler(app);

  app.get('/roll', (Request request) {
    final rollValue = random.nextInt(6) + 1;
    print(
        '[${DateTime.now()}] Пользователь сделал бросок, выпало: $rollValue (GET)');
    return Response.ok(
      'Результат броска: $rollValue',
      headers: {'Content-Type': 'text/plain'},
    );
  });

  app.post('/roll', (Request request) async {
    final rollValue = random.nextInt(6) + 1;
    print(
        '[${DateTime.now()}] Пользователь сделал бросок, выпало: $rollValue (POST)');
    return Response.ok(
      rollValue.toString(),
      headers: {'Content-Type': 'application/json'},
    );
  });

  final server = await serve(handler, serverIp, port);

  print('╔══════════════════════════════════════════╗');
  print('║   Сервер запущен на http://${server.address.host}:$port  ║');
  print('╠══════════════════════════════════════════╣');
  print('║ GET  /roll    - Тестовый бросок          ║');
  print('║ POST /roll    - Основной endpoint        ║');
  print('╚══════════════════════════════════════════╝');
}

Middleware get _enableCors {
  return (Handler handler) {
    return (Request request) async {
      final response = await handler(request);
      return response.change(headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type',
      });
    };
  };
}
