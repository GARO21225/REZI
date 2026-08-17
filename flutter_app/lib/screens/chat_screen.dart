import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/extra_models.dart';
import '../services/api_service.dart';
import '../theme/rezi_theme.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String autreUtilisateur;
  const ChatScreen({super.key, required this.conversationId, required this.autreUtilisateur});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _api = ApiService();
  final _storage = const FlutterSecureStorage();
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  List<ChatMessage> _messages = [];
  WebSocketChannel? _channel;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final msgs = await _api.fetchMessages(widget.conversationId);
      setState(() { _messages = msgs; _loading = false; });
      final token = await _storage.read(key: 'jwt_token');
      // NB: l'URL du WS suppose que l'id utilisateur est extrait du JWT côté backend,
      // adapter selon votre implémentation (voir index.html ligne ~9400).
      if (token != null) {
        final uri = _api.messagesWebSocketUrl(widget.conversationId, token);
        _channel = WebSocketChannel.connect(uri);
        _channel!.stream.listen((event) {
          final data = jsonDecode(event);
          setState(() => _messages.add(ChatMessage.fromJson(data)));
        }, onError: (_) {});
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _channel?.sink.add(jsonEncode({'contenu': text, 'conversation_id': widget.conversationId}));
    _controller.clear();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.autreUtilisateur)),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(ReziTokens.radiusMd),
                          ),
                          child: Text(m.contenu),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Votre message...'),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _send, icon: const Icon(Icons.send_rounded)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
