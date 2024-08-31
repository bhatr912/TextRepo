import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:math' as math;

import 'AdsScreen.dart';

class AskAIScreen extends StatefulWidget {
  final String storageLocation;

  const AskAIScreen({super.key, required this.storageLocation});

  @override
  _AskAIScreenState createState() => _AskAIScreenState();
}

class _AskAIScreenState extends State<AskAIScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController promptController = TextEditingController();
  final List<Map<String, String>> chatMessages = [];
  bool isLoading = false;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  int queryCount = 0;
  bool isSearchDisabled = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _sendPrompt() async {
    if (isSearchDisabled) {
      showWatchAdDialog();
      return;
    }

    final prompt = promptController.text.trim();
    if (widget.storageLocation.isEmpty || prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.blue,
          content: const Text('Please enter prompt.'),
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
      chatMessages.add({'role': 'user', 'content': prompt});
      queryCount++;
    });

    try {
      final storageRef = FirebaseStorage.instance.refFromURL(
          widget.storageLocation);
      final metadata = await storageRef.getMetadata();
      final mimeType = metadata.contentType ?? 'application/octet-stream';

      final model = FirebaseVertexAI.instance.generativeModel(
          model: 'gemini-1.5-flash',
          systemInstruction: mimeType.startsWith('image/')
              ? Content.system(
              'You are an expert at analyzing images. Extract text from the image and answer any questions based on the content. Reference external data or information as needed to provide detailed and accurate answers.')
              : Content.system(
              'You are an expert at analyzing and understanding PDF documents. Extract text from the PDF, summarize the content, and answer any questions based on the document. Reference external data or information as needed to provide detailed and accurate answers.')
      );

      final promptPart = TextPart(prompt);
      final filePart = FileData(mimeType, widget.storageLocation);

      final apiResponse = await model.generateContent([
        Content.multi([promptPart, filePart])
      ]);
      final responseText = apiResponse.text ?? 'No response received';

      setState(() {
        chatMessages.add({'role': 'ai', 'content': responseText});
        isLoading = false;
        if (queryCount >= 10) {//free tokens
          isSearchDisabled = true;
        }
      });
      promptController.clear();
      scrollToBottom();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void showWatchAdDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'You are out of free messages ',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.token,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              const Text(
                'Watch an ad to get access again.',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton.icon(
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Watch Ad'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                showAdScreen();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void showAdScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdScreen(
          onAdComplete: () {
            setState(() {
              isSearchDisabled = false;
              queryCount = 0;
            });
          },
        ),
      ),
    );
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
            ),
          ),
        ),
        title: const Text('Ask AI',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF2880BC),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                if (chatMessages.isEmpty)
                  const Center(
                    child: WelcomeMessage(),
                  )
                else
                  ListView.builder(
                    controller: _scrollController,
                    itemCount: chatMessages.length,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    itemBuilder: (context, index) {
                      final message = chatMessages[index];
                      final isUser = message['role'] == 'user';
                      return MessageBubble(
                        message: message['content']!,
                        isUser: isUser,
                      );
                    },
                  ),
                if (isLoading)
                  Center(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: AIThinkingAnimation(
                          animationController: _animationController),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: promptController,
                    decoration: InputDecoration(
                      hintText: 'Ask ai...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: _sendPrompt,
                  backgroundColor:
                  isSearchDisabled ? Colors.grey : Colors.white,
                  child: Icon(
                    Icons.send,
                    color: isSearchDisabled
                        ? Colors.white
                        : const Color(0xFF2880BC),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WelcomeMessage extends StatelessWidget {
  const WelcomeMessage({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Color(0xFF2880BC),
          ),
          const SizedBox(height: 20),
          const Text(
            'Welcome to Ask AI!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2880BC),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Start by prompting the question',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue.shade300 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class AIThinkingAnimation extends StatelessWidget {
  final AnimationController animationController;

  const AIThinkingAnimation({super.key, required this.animationController});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AIAnimationPainter(animationController),
      child: const Center(
        child: Text(
          'AI Thinking...',
          style: TextStyle(
            color: Color(0xFF2880BC),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _AIAnimationPainter extends CustomPainter {
  final AnimationController _animation;

  _AIAnimationPainter(this._animation) : super(repaint: _animation);

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final maxRadius = size.width / 8;
    final paint = Paint()
      ..color = const Color(0xFF2880BC).withOpacity(0.6)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final progress = (_animation.value - i / 5) % 1.0;
      final centerX = size.width * (0.2 + progress * 0.6);
      final radius = maxRadius * math.sin(progress * math.pi);
      canvas.drawCircle(Offset(centerX, centerY), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}