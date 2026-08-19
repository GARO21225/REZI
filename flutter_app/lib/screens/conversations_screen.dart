import 'package:flutter/material.dart';
import '../models/extra_models.dart';
import '../services/api_service.dart';
import '../theme/rezi_theme.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final _api = ApiService();
  late Future<List<Conversation>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchConversations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: FutureBuilder<List<Conversation>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Aucune conversation.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final c = items[i];
              return ListTile(
                leading: ReziAvatar(initials: c.autreUtilisateur.isNotEmpty ? c.autreUtilisateur[0] : '?'),
                title: Text(c.autreUtilisateur),
                subtitle: c.dernierMessage != null
                    ? Text(c.dernierMessage!, maxLines: 1, overflow: TextOverflow.ellipsis)
                    : null,
                trailing: c.nonLus > 0
                    ? CircleAvatar(
                        radius: 10,
                        backgroundColor: ReziTokens.accent,
                        child: Text('${c.nonLus}', style: const TextStyle(fontSize: 10, color: Colors.white)),
                      )
                    : null,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(conversationId: c.id, autreUtilisateur: c.autreUtilisateur),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
