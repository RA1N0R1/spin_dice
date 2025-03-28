import 'dart:io';
import 'dart:math';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

void main() async {
  final app = Router();
  final random = Random();

  // Endpoint для броска кубика
  app.post('/roll', (Request request) async {
    final rollValue = random.nextInt(6) + 1;
    print('Пользователь сделал бросок, выпало: $rollValue');

    return Response.ok(
      rollValue.toString(),
      headers: {'Content-Type': 'application/json'},
    );
  });

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(app, '0.0.0.0', port);

  print('Сервер запущен на порту ${server.port}');
  print('Доступные эндпоинты:');
  print('POST /roll - сделать бросок кубика');
}
