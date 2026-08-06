import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() =>
      _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _robotController;
  late Animation<Offset> _robotAnimation;
  final TextEditingController _controller =
  TextEditingController();

  final ScrollController _scrollController =
  ScrollController();

  List<Map<String, String>> messages = [];

  bool isTyping = false;

  static const String baseUrl =
      "https://learnovaapp-lfgn.onrender.com";
  @override
  void initState() {
    super.initState();

    _robotController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _robotAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -0.05),
    ).animate(
      CurvedAnimation(
        parent: _robotController,
        curve: Curves.easeInOut,
      ),
    );
  }
  @override
  void dispose() {
    _robotController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> sendMessage() async {
    if (_controller.text.trim().isEmpty) {
      return;
    }
    final userMessage = _controller.text.trim();
    setState(() {
      messages.add({
        "role": "user",
        "content": userMessage,
      });
      isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/chat"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "message": userMessage,
          "standard": "class10",
          "language": "english",
          "chat_history": messages,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          messages.add({
            "role": "assistant",
            "content": data["reply"],
          });
        });
      } else {
        setState(() {
          messages.add({
            "role": "assistant",
            "content":
            "Sorry, something went wrong.",
          });
        });
      }
    } catch (e) {
      setState(() {
        messages.add({
          "role": "assistant",
          "content":
          "Unable to connect to the server.",
        });
      });
    }
    setState(() {
      isTyping = false;
    });
    _scrollToBottom();

  }

  void _scrollToBottom() {

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
      backgroundColor: const Color(0xff14102B),

      body: SafeArea(
        child: Column(

          children: [

            _buildHeader(),

            Expanded(
              child: _buildChatArea(),
            ),

            _buildInputBar(),

          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
      child: Row(
        children: [

          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 8),

          const Text(
            "AI Assistant",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildChatArea() {

    if (messages.isEmpty) {

      return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            SlideTransition(
              position: _robotAnimation,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(.35),
                      blurRadius: 45,
                      spreadRadius: -12,
                    ),
                  ],
                ),
                child: Image.asset(
                  "assets/ai_mascot.png",
                  height: 260,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Hello 👋",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 30,
              ),
            ),

            const SizedBox(height: 10),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 35),
              child: Text(
                "Ask me anything from your syllabus.\nI'll explain it step by step.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (_, index) {
        final message = messages[index];
        final isUser =
            message["role"] == "user";
        return Align(
          alignment: isUser
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            margin:
            const EdgeInsets.only(bottom: 12),
            padding:
            const EdgeInsets.all(14),
            constraints:
            const BoxConstraints(
              maxWidth: 300,
            ),
            decoration: BoxDecoration(
              color: isUser
                  ? const Color(0xff6C5CE7)
                  : const Color(0xff211A45),
              borderRadius:
              BorderRadius.circular(18),
            ),
            child: Text(
              message["content"]!,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff14102B),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(.08),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => sendMessage(),
              style: const TextStyle(
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: "Ask your doubt...",
                hintStyle: const TextStyle(
                  color: Colors.white38,
                ),
                filled: true,
                fillColor: const Color(0xff2A2355),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xff2A2355),
              borderRadius: BorderRadius.circular(24),
            ),
            child: IconButton(
              onPressed: () {
                // TODO: Voice input
              },
              icon: const Icon(
                Icons.mic,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xff47E7FF),
                  Color(0xff9C4DFF),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xff47E7FF),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: IconButton(
              onPressed: sendMessage,
              icon: const Icon(
                Icons.send,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}