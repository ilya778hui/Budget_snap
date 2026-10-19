import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/ai_service.dart';
import '../services/chat_history_service.dart';
import '../screens/subscription_screen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();
  final _chatService = ChatHistoryService();
  final _scrollController = ScrollController();

  List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  bool _isLoadingHistory = true;

  double _balance = 0;
  double _totalIncome = 0;
  double _totalExpense = 0;

  int _aiUsageCount = 0;
  final int _usageLimit = 5;   // можно изменить на 7

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadFinancialData();
    _loadAiUsageCount();
  }

  Future<void> _loadAiUsageCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final db = FirebaseDatabase.instance.ref();
    final snapshot = await db.child('users/${user.uid}/aiUsageCount').get();

    if (snapshot.exists) {
      setState(() {
        _aiUsageCount = (snapshot.value as num?)?.toInt() ?? 0;
      });
    }
  }

  Future<void> _incrementAiUsage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final db = FirebaseDatabase.instance.ref();
    _aiUsageCount++;

    await db.child('users/${user.uid}/aiUsageCount').set(_aiUsageCount);

    if (_aiUsageCount >= _usageLimit && _aiUsageCount % 3 == 0) {
      _showSubscriptionDialog();
    }
  }

  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔥 Улучшите AI-ментора'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Вы уже использовали бесплатный лимит запросов.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'С подпиской ответы будут:\n'
              '• Полностью безлимитными\n'
              '• Более точными и персональными\n'
              '• С анализом вашего бюджета',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Спасибо, нет'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Позже'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
              );
            },
            child: const Text('Купить подписку'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadFinancialData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final db = FirebaseDatabase.instance.ref();
    final snapshot = await db.child('users/${user.uid}').get();

    if (snapshot.exists && snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        _balance = (data['balance'] as num?)?.toDouble() ?? 0;
        _totalIncome = (data['totalIncome'] as num?)?.toDouble() ?? 0;
        _totalExpense = (data['totalExpense'] as num?)?.toDouble() ?? 0;
      });
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    final history = await _chatService.getRecentHistory(limit: 50);
    setState(() {
      _messages = history;
      _isLoadingHistory = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _scrollToBottom();

    await _chatService.saveMessage(role: 'user', content: text);

    try {
      await _incrementAiUsage();   // ← увеличиваем счётчик

      String enrichedMessage;
      if (_balance == 0 && _totalIncome == 0 && _totalExpense == 0) {
        enrichedMessage = '''
Контекст кошелька пользователя:
- Кошелёк пустой, транзакций нет

Вопрос пользователя: $text
''';
      } else {
        enrichedMessage = '''
Контекст кошелька пользователя:
- Баланс: ${_balance.toStringAsFixed(0)} ₸
- Доходы за всё время: ${_totalIncome.toStringAsFixed(0)} ₸
- Расходы за всё время: ${_totalExpense.toStringAsFixed(0)} ₸
- Соотношение расходов к доходам: ${_totalIncome > 0 ? (_totalExpense / _totalIncome * 100).toStringAsFixed(0) : 0}%

Вопрос пользователя: $text
''';
      }

      final reply = await AiService.askFinancialQuestion(
        userMessage: enrichedMessage,
        conversationHistory: _messages.sublist(0, _messages.length - 1),
      );

      await _chatService.saveMessage(role: 'assistant', content: reply);

      setState(() {
        _messages.add({'role': 'assistant', 'content': reply});
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💬 Финансовый помощник'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Очистить историю',
            onPressed: () async {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Очистить историю?'),
                  content: const Text('Все сообщения будут удалены.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Отмена'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _chatService.clearHistory();
                        setState(() => _messages = []);
                      },
                      child: const Text('Удалить', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.star_outline, color: Colors.amber),
            tooltip: 'Купить подписку',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border(bottom: BorderSide(color: Colors.green.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMiniStat('💰 Баланс', '${_balance.toStringAsFixed(0)} ₸',
                    _balance > 0 ? Colors.green : Colors.grey),
                _buildMiniStat('📈 Доход', '${_totalIncome.toStringAsFixed(0)} ₸',
                    Colors.green),
                _buildMiniStat('📉 Расход', '${_totalExpense.toStringAsFixed(0)} ₸',
                    Colors.red),
              ],
            ),
          ),
          Expanded(
            child: _isLoadingHistory
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Задай вопрос финансовому помощнику',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Думаю...',
                                        style: TextStyle(color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                            );
                          }
                          final msg = _messages[index];
                          final isUser = msg['role'] == 'user';
                          return Align(
                            alignment: isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isUser ? Colors.green : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                msg['content']!,
                                style: TextStyle(
                                  color: isUser ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Спроси что-нибудь о финансах...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.green,
                  child: IconButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}