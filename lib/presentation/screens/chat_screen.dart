import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:banten_explorer/presentation/providers/chat_provider.dart';
import 'package:banten_explorer/presentation/widgets/chat_bubble.dart';
import 'package:banten_explorer/presentation/widgets/chat_input_field.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Banten Explorer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, provider, child) {
                  if (provider.messages.isEmpty && !provider.isLoading) {
                    return const Center(
                      child: Text(
                        'Silakan tanya info wisata Banten.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    );
                  }
                  return ListView.builder(
                    reverse: true, // Auto-scroll
                    padding: const EdgeInsets.only(top: 16, bottom: 16),
                    itemCount: provider.messages.length + (provider.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Tampilkan animasi loading Lottie
                      if (provider.isLoading && index == 0) {
                        return Align(
                          // KUNCI PERBAIKAN: Beri Key pada loading
                          key: const ValueKey('loading_lottie'), 
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                                bottomLeft: Radius.circular(0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Lottie.asset(
                                  'assets/loading-animation.json',
                                  width: 40,
                                  height: 40,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      final chatIndex = provider.isLoading ? index - 1 : index;
                      final currentChat = provider.messages[chatIndex];
                      
                      return ChatBubble(
                        // KUNCI PERBAIKAN: Beri Key spesifik berdasarkan ID pesan!
                        key: ValueKey(currentChat.id), 
                        chat: currentChat,
                      );
                    },
                  );
                },
              ),
            ),
            const ChatInputField(),
          ],
        ),
      ),
    );
  }
}