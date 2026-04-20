import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:banten_explorer/presentation/providers/chat_provider.dart';
import 'package:banten_explorer/presentation/providers/theme_provider.dart';
import 'package:banten_explorer/presentation/screens/speech_to_speech_screen.dart';

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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    if (chatProvider.recognizedText.isNotEmpty && chatProvider.isListening) {
      _controller.text = chatProvider.recognizedText;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }

    final bool hasText = _controller.text.trim().isNotEmpty;
    final bool isListening = chatProvider.isListening;

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // INPUT TEXT
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                cursorColor: isDark
                    ? Colors.blue.shade300
                    : Colors.blue.shade700,
                textAlignVertical: TextAlignVertical.center,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: isListening
                      ? 'Mendengarkan...'
                      : 'Ketik pertanyaan...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.blue.shade500
                          : Colors.blue.shade300,
                      width: 1.2,
                    ),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF2C2C2C)
                      : Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            Padding(
              padding: const EdgeInsets.only(bottom: 2.0),
              child: IconButton(
                icon: Icon(
                  Icons.graphic_eq,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  size: 24,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  if (chatProvider.isListening)
                    chatProvider.toggleListening(_controller);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SpeechToSpeechScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(width: 8),

            // TOMBOL MIC / SEND
            Padding(
              padding: const EdgeInsets.only(bottom: 2.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: isListening
                      ? Colors.red.shade500
                      : (isDark
                            ? (hasText
                                  ? Colors.blue.shade500
                                  : const Color(0xFF2C2C2C))
                            : Colors.blue.shade600),
                  shape: BoxShape.circle,
                  boxShadow: (isListening || (hasText || !isDark))
                      ? [
                          BoxShadow(
                            color: (isListening ? Colors.red : Colors.blue)
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      isListening
                          ? Icons.stop_rounded
                          : (hasText
                                ? Icons.send_rounded
                                : Icons.mic_none_rounded),
                      key: ValueKey<bool>(isListening || hasText),
                      color: isListening
                          ? Colors.white
                          : (isDark && !hasText
                                ? Colors.grey.shade400
                                : Colors.white),
                      size: 24,
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
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
      ),
    );
  }
}
