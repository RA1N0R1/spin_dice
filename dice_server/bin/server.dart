import 'dart:convert';
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
  final connectedUsers = <String>{};

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_enableCors)
      .addHandler(app);

  app.post('/roll', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final nickname = data['nickname'] as String?;

      if (nickname == null || nickname.isEmpty) {
        return Response.badRequest(body: 'Никнейм не указан');
      }

      if (!connectedUsers.contains(nickname)) {
        connectedUsers.add(nickname);
        print('[${DateTime.now()}] Новый пользователь: $nickname');
      }

      final rollValue = random.nextInt(6) + 1;
      final responseMessage = {
        'value': rollValue,
        'message': 'Пользователь $nickname сделал бросок, выпало: $rollValue',
      };

      print('[${DateTime.now()}] ${responseMessage['message']}');
      return Response.ok(
        jsonEncode(responseMessage),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: 'Ошибка: $e');
    }
  });

  final server = await serve(handler, serverIp, port);
  print('Сервер запущен на http://${server.address.host}:$port');
  print('Доступные endpoint: POST /roll');
}

Middleware get _enableCors {
  return (Handler handler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type',
        });
      }
      final response = await handler(request);
      return response.change(headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type',
      });
    };
  };
}
