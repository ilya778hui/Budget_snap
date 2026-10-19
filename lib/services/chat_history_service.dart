import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatHistoryService {
  final _db = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser!.uid;

  // Сохранить сообщение
  Future<void> saveMessage({
    required String role, // 'user' или 'assistant'
    required String content,
  }) async {
    await _db.child('ai_chat').child(_userId).push().set({
      'role': role,
      'content': content,
      'timestamp': ServerValue.timestamp,
    });
  }

  // Получить последние 10 сообщений (для контекста)
  Future<List<Map<String, String>>> getRecentHistory({int limit = 10}) async {
    final snapshot = await _db
        .child('ai_chat')
        .child(_userId)
        .orderByChild('timestamp')
        .limitToLast(limit)
        .get();

    if (!snapshot.exists) return [];

    final messages = <Map<String, String>>[];

    final data = snapshot.value as Map<dynamic, dynamic>;
    final sorted = data.entries.toList()
      ..sort((a, b) {
        final aTime = (a.value as Map)['timestamp'] ?? 0;
        final bTime = (b.value as Map)['timestamp'] ?? 0;
        return (aTime as int).compareTo(bTime as int);
      });

    for (final entry in sorted) {
      final msg = entry.value as Map<dynamic, dynamic>;
      messages.add({
        'role': msg['role'] as String,
        'content': msg['content'] as String,
      });
    }

    return messages;
  }

  // Очистить историю чата
  Future<void> clearHistory() async {
    await _db.child('ai_chat').child(_userId).remove();
  }
}