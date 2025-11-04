import 'package:flutter/material.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final inputCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const BackButton(),
        title: const Text('Search Event'),
      ),
      body: Stack(
        children: [
          // blurred background placeholder
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1508997449629-303059a039c0?q=80&w=1200&auto=format&fit=crop',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(.35),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          // rounded “card” like your screenshot
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 110, 16, 120),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.95),
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Search Event', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'What would you like me to ask?',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(onPressed: () {}, icon: const Icon(Icons.tune_outlined)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // … add filters/messages if needed
                  Container(height: 220, color: Colors.transparent), // spacer for the blurred image area
                ]),
              ),
            ],
          ),
          // message composer (like your last screenshot)
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    IconButton(onPressed: () {}, icon: const Icon(Icons.emoji_emotions_outlined)),
                    Expanded(
                      child: TextField(
                        controller: inputCtrl,
                        decoration: InputDecoration(
                          hintText: 'Write a message…',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: () {}, child: const Text('send')),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.mic_none_rounded)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
