import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:banten_explorer/presentation/providers/chat_provider.dart';

class ChatInputField extends StatefulWidget {
  const ChatInputField({Key? key}) : super(key: key);

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    if (chatProvider.recognizedText.isNotEmpty && chatProvider.isListening) {
      _controller.text = chatProvider.recognizedText;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }

    final bool hasText = _controller.text.trim().isNotEmpty;
    final bool isListening = chatProvider.isListening;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 5,
              keyboardType: TextInputType.multiline,
              cursorColor: Colors.blue.shade700,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: isListening ? 'Mendengarkan...' : 'Ketik pertanyaan...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.blue.shade300, width: 1.5), // BORDER BIRU SAAT FOKUS
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: CircleAvatar(
              backgroundColor: isListening
                  ? Colors.red
                  : (hasText ? Colors.blue.shade600 : Colors.blue.shade100),
              radius: 24,
              child: IconButton(
                icon: Icon(
                  isListening
                      ? Icons.stop
                      : (hasText ? Icons.send : Icons.mic_none),
                  color: (isListening || hasText) ? Colors.white : Colors.blue.shade700,
                ),
                onPressed: () {
                  if (isListening) {
                    chatProvider.toggleListening(_controller);
                  } else if (hasText) {
                    chatProvider.sendMessage(_controller.text);
                    _controller.clear();
                  } else {
                    chatProvider.toggleListening(_controller);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}