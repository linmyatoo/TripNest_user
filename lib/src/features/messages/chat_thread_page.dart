import 'package:flutter/material.dart';

class ChatThreadPage extends StatelessWidget {
  const ChatThreadPage({super.key, required this.peerName});
  final String peerName;

  @override
  Widget build(BuildContext context) {
    final msgCtrl = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(peerName, style: const TextStyle(fontWeight: FontWeight.w700)),
          const Text('Online',
              style: TextStyle(fontSize: 12, color: Colors.black54)),
        ]),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz))
        ],
      ),
      body: Column(
        children: [
          // event snippet
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=400&auto=format&fit=crop',
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 54,
                        height: 54,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported,
                            color: Colors.grey, size: 24),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 54,
                        height: 54,
                        color: Colors.grey[200],
                        child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    },
                  ),
                ),
                title: const Text('Celebration Concert',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('245 Oceanview Blvd, Miami\n⭐ 4.5 (540)'),
                isThreeLine: true,
              ),
            ),
          ),
          // chat bubbles
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: const [
                _Bubble.mine(
                    'Hi Panda, Let’s meet at the event.\nSee you mateeeee!',
                    '8:12 Am'),
                _Bubble.theirs('Sure Harry!!! See you sooonnnnnnn!', '8:12 Am'),
                _Bubble.theirs('Thank You! 😊', '8:12 Am'),
              ],
            ),
          ),
          // composer
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.attach_file_outlined)),
                  Expanded(
                    child: TextField(
                      controller: msgCtrl,
                      decoration: InputDecoration(
                        hintText: 'Write a reply',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24)),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                      onPressed: () {}, child: const Icon(Icons.send)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble.mine(this.text, this.time) : mine = true;
  const _Bubble.theirs(this.text, this.time) : mine = false;

  final String text;
  final String time;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final color = mine ? const Color(0xFF2563EB) : const Color(0xFFF2F4F7);
    final textColor = mine ? Colors.white : Colors.black87;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft:
                mine ? const Radius.circular(14) : const Radius.circular(0),
            bottomRight:
                mine ? const Radius.circular(0) : const Radius.circular(14),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(text, style: TextStyle(color: textColor)),
          const SizedBox(height: 4),
          Text(time,
              style: TextStyle(color: textColor.withOpacity(.8), fontSize: 11)),
        ]),
      ),
    );
  }
}
