import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:banten_explorer/domain/entities/chat_entity.dart';
import 'package:banten_explorer/presentation/widgets/map_preview_widget.dart';

class ChatBubble extends StatefulWidget {
  final ChatEntity chat;

  const ChatBubble({Key? key, required this.chat}) : super(key: key);

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> with AutomaticKeepAliveClientMixin {
  String _displayedText = "";
  bool _showMedia = false;
  Timer? _timer;

  // Mencatat waktu sesi dimulai
  static final DateTime _sessionStartTime = DateTime.now();
  // Menyimpan ID pesan yang sudah dianimasikan
  static final Set<String> _animatedMessageIds = {};

  @override
  bool get wantKeepAlive => true; 

  @override
  void initState() {
    super.initState();
    
    // BUFFER PERBAIKAN: Beri toleransi 15 detik untuk mengatasi delay Firebase
    bool isNewMessage = widget.chat.timestamp.isAfter(_sessionStartTime.subtract(const Duration(seconds: 15)));
    bool hasBeenAnimated = _animatedMessageIds.contains(widget.chat.id);

    if (!widget.chat.isUser && isNewMessage && !hasBeenAnimated) {
      _animatedMessageIds.add(widget.chat.id);
      _startTypingAnimation();
    } else {
      _displayedText = widget.chat.text;
      _showMedia = true;
    }
  }

  void _startTypingAnimation() {
    int currentIndex = 0;
    final String fullText = widget.chat.text;

    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (currentIndex < fullText.length) {
        setState(() {
          currentIndex = (currentIndex + 2).clamp(0, fullText.length);
          _displayedText = fullText.substring(0, currentIndex);
        });
      } else {
        _timer?.cancel();
        setState(() {
          _showMedia = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showImagePreview(BuildContext context, List<String> imageUrls, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) {
        PageController pageController = PageController(initialPage: initialIndex);
        return Dialog(
          backgroundColor: Colors.black.withOpacity(0.9),
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              PageView.builder(
                controller: pageController,
                itemCount: imageUrls.length,
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      imageUrls[index],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Text('Gagal memuat gambar', style: TextStyle(color: Colors.white)),
                        );
                      },
                    ),
                  );
                },
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); 
    
    final isUser = widget.chat.isUser;
    final hasImages = widget.chat.imageUrls != null && widget.chat.imageUrls!.isNotEmpty;
    final hasMap = !isUser && widget.chat.showMap && widget.chat.mapKeyword != null;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue.shade600 : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _displayedText,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            
            if (!isUser && (hasImages || hasMap))
              AnimatedOpacity(
                opacity: _showMedia ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 1000), 
                curve: Curves.easeIn,
                child: _showMedia
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasImages)
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: CarouselSlider(
                                options: CarouselOptions(
                                  height: 180,
                                  enableInfiniteScroll: widget.chat.imageUrls!.length > 1,
                                  enlargeCenterPage: true,
                                  viewportFraction: 0.9,
                                ),
                                items: widget.chat.imageUrls!.asMap().entries.map((entry) {
                                  int idx = entry.key;
                                  String url = entry.value;
                                  return GestureDetector(
                                    onTap: () => _showImagePreview(context, widget.chat.imageUrls!, idx),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        url,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          color: Colors.grey.shade300,
                                          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          if (hasMap)
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: MapPreviewWidget(keyword: widget.chat.mapKeyword!),
                            ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }
}