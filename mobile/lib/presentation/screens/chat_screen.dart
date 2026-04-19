import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:banten_explorer/presentation/providers/chat_provider.dart';
import 'package:banten_explorer/presentation/providers/theme_provider.dart';
import 'package:banten_explorer/presentation/widgets/chat_bubble.dart';
import 'package:banten_explorer/presentation/widgets/chat_input_field.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottom = false;

  static const Map<String, String> _supportedLanguages = {
    'id_ID': '🇮🇩', 
    'en_US': '🇺🇸', 
    'ja_JP': '🇯🇵', 
    'zh_CN': '🇨🇳', 
    'ar_SA': '🇸🇦', 
    'fr_FR': '🇫🇷', 
    'de_DE': '🇩🇪', 
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 300 && !_showScrollToBottom) {
        setState(() => _showScrollToBottom = true);
      } else if (_scrollController.offset <= 300 && _showScrollToBottom) {
        setState(() => _showScrollToBottom = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getLanguageName(String localeCode) {
    switch (localeCode) {
      case 'id_ID': return 'Indonesia';
      case 'en_US': return 'English';
      case 'ja_JP': return '日本語 (Jepang)';
      case 'zh_CN': return '中文 (Mandarin)';
      case 'ar_SA': return 'العربية (Arab)';
      case 'fr_FR': return 'Français';
      case 'de_DE': return 'Deutsch';
      default: return 'Unknown';
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: Text(
          'Banten Explorer',
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 20,
            color: isDark ? Colors.white : Colors.blue.shade700,
          ),
        ),
        backgroundColor: isDark 
            ? Colors.black.withOpacity(0.65) 
            : Colors.white.withOpacity(0.75),
        elevation: 0,
        centerTitle: false,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(color: Colors.transparent),
          ),
        ),
        actions: [
          // TOGGLE DARK MODE
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? Colors.amber.shade300 : Colors.blue.shade700,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
          
          // DROPDOWN BAHASA
          Consumer<ChatProvider>(
            builder: (context, provider, child) {
              final currentFlag = _supportedLanguages[provider.selectedLanguage] ?? '🇮🇩';
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: PopupMenuButton<String>(
                  initialValue: provider.selectedLanguage,
                  onSelected: (String newValue) {
                    provider.setSpeechLanguage(newValue);
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  elevation: 8,
                  itemBuilder: (BuildContext context) {
                    return _supportedLanguages.entries.map((entry) {
                      return PopupMenuItem<String>(
                        value: entry.key,
                        child: Row(
                          children: [
                            Text(
                              entry.value, 
                              style: const TextStyle(fontSize: 22),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _getLanguageName(entry.key),
                              style: TextStyle(
                                fontWeight: provider.selectedLanguage == entry.key 
                                    ? FontWeight.bold 
                                    : FontWeight.normal,
                                color: provider.selectedLanguage == entry.key 
                                    ? (isDark ? Colors.blue.shade300 : Colors.blue.shade700)
                                    : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList();
                  },
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currentFlag,
                            style: const TextStyle(fontSize: 22), 
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down_rounded, 
                            size: 20, 
                            color: isDark ? Colors.white : Colors.blue.shade700
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Consumer<ChatProvider>(
                  builder: (context, provider, child) {
                    if (provider.messages.isEmpty && !provider.isLoading) {
                      return Center(
                        child: Text(
                          'Silakan tanya info wisata Banten.',
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade500 : Colors.grey, 
                            fontSize: 16
                          ),
                        ),
                      );
                    }
                    
                    return Theme(
                      data: Theme.of(context).copyWith(
                        scrollbarTheme: ScrollbarThemeData(
                          thumbColor: MaterialStateProperty.all(
                            isDark ? Colors.white.withOpacity(0.2) : Colors.blue.shade700.withOpacity(0.3)
                          ),
                          radius: const Radius.circular(10),
                          thickness: MaterialStateProperty.all(6),
                          crossAxisMargin: 4,
                        ),
                      ),
                      child: Scrollbar(
                        controller: _scrollController,
                        interactive: true,
                        child: ListView.builder(
                          controller: _scrollController,
                          reverse: true, 
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top + kToolbarHeight + 16, 
                            bottom: 16
                          ),
                          itemCount: provider.messages.length + (provider.isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (provider.isLoading && index == 0) {
                              return Align(
                                key: const ValueKey('loading_lottie'), 
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                                      // IMPLEMENTASI COLOR FILTER UNTUK LOTTIE DI DARK MODE
                                      isDark 
                                          ? ColorFiltered(
                                              colorFilter: const ColorFilter.mode(
                                                Colors.white,
                                                BlendMode.srcIn,
                                              ),
                                              child: Lottie.asset(
                                                'assets/loading-animation.json',
                                                width: 40,
                                                height: 40,
                                              ),
                                            )
                                          : Lottie.asset(
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
                              key: ValueKey(currentChat.id), 
                              chat: currentChat,
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              const ChatInputField(),
            ],
          ),
          
          Positioned(
            bottom: 100, 
            right: 20,
            child: AnimatedScale(
              scale: _showScrollToBottom ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: isDark ? Colors.blue.shade800 : Colors.blue.shade50,
                elevation: 4,
                onPressed: _scrollToBottom,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded, 
                  color: isDark ? Colors.white : Colors.blue.shade700,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}