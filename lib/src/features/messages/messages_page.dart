import 'package:flutter/material.dart';
import 'chat_thread_page.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search or start new chat',
              prefixIcon: const Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              filled: true,
            ),
          ),
          const SizedBox(height: 16),
          _chatCell(
            context,
            name: 'Panda',
            last: 'Thank you!',
            time: '7:12 Am',
            unread: 2,
            avatar:
                'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=300&auto=format&fit=crop',
          ),
          const SizedBox(height: 12),
          _chatCell(
            context,
            name: "Panda's Gf",
            last: 'wooohooo',
            time: '9:28 Am',
            avatar:
                'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?q=80&w=300&auto=format&fit=crop',
          ),
        ],
      ),
    );
  }

  Widget _chatCell(
    BuildContext context, {
    required String name,
    required String last,
    required String time,
    required String avatar,
    int unread = 0,
  }) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChatThreadPage(peerName: name),
      )),
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            CircleAvatar(backgroundImage: NetworkImage(avatar), radius: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 20),
                    Text(last, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(time,
                  style: const TextStyle(color: Colors.black54, fontSize: 12)),
              const SizedBox(height: 6),
              if (unread > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('$unread',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 12)),
                ),
            ]),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}
