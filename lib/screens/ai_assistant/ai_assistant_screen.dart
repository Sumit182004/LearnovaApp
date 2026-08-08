import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _robotController;
  late Animation<Offset> _robotAnimation;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  List<Map<String, String>> messages = [];

  bool isTyping = false;
  bool isListening = false;

  int? speakingIndex;

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

    _initializeVoice();
  }

  Future<void> _initializeVoice() async {
    await _speech.initialize(
      onStatus: (status) {
        if (status == "done" || status == "notListening") {
          if (mounted) {
            setState(() {
              isListening = false;
            });
          }
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            isListening = false;
          });
        }
      },
    );

    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.0);

    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          speakingIndex = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _robotController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (isListening) {
      await _speech.stop();

      setState(() {
        isListening = false;
      });

      return;
    }

    final available = await _speech.initialize();

    if (!available) {
      return;
    }

    setState(() {
      isListening = true;
    });

    await _speech.listen(
      onResult: (result) async {
        if (!mounted) return;

        setState(() {
          _controller.text = result.recognizedWords;
          _controller.selection =
              TextSelection.fromPosition(
                TextPosition(
                  offset: _controller.text.length,
                ),
              );
        });

        if (result.finalResult &&
            _controller.text.trim().isNotEmpty) {
          setState(() {
            isListening = false;
          });

          await sendMessage();
        }
      },
      localeId: "en_US",
    );
  }

  Future<void> sendMessage() async {
    if (_controller.text.trim().isEmpty || isTyping) {
      return;
    }

    if (isListening) {
      await _speech.stop();

      setState(() {
        isListening = false;
      });
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
          "chat_history": messages.length > 10
              ? messages.sublist(messages.length - 10)
              : messages,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["reply"] == null ||
            data["reply"].toString().trim().isEmpty) {
          throw Exception("Empty reply from server");
        }

        setState(() {
          messages.add({
            "role": "assistant",
            "content": data["reply"].toString(),
          });
        });
      } else {
        setState(() {
          messages.add({
            "role": "assistant",
            "content":
            "Sorry, something went wrong. Please try again.",
          });
        });
      }
    } catch (e) {
      setState(() {
        messages.add({
          "role": "assistant",
          "content":
          "Unable to reach the server. Please check your internet connection and try again.",
        });
      });
    }

    setState(() {
      isTyping = false;
    });

    _scrollToBottom();
  }

  Future<void> regenerateResponse(int assistantIndex) async {
    if (isTyping) return;

    int userIndex = assistantIndex - 1;

    while (userIndex >= 0 &&
        messages[userIndex]["role"] != "user") {
      userIndex--;
    }

    if (userIndex < 0) return;

    final userMessage = messages[userIndex]["content"] ?? "";

    setState(() {
      messages.removeAt(assistantIndex);
      isTyping = true;
    });

    _scrollToBottom();

    try {
      final history = messages.length > 10
          ? messages.sublist(messages.length - 10)
          : messages;

      final response = await http.post(
        Uri.parse("$baseUrl/chat"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "message": userMessage,
          "standard": "class10",
          "language": "english",
          "chat_history": history,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["reply"] == null ||
            data["reply"].toString().trim().isEmpty) {
          throw Exception("Empty reply");
        }

        setState(() {
          messages.add({
            "role": "assistant",
            "content": data["reply"].toString(),
          });
        });
      } else {
        setState(() {
          messages.add({
            "role": "assistant",
            "content":
            "Sorry, I couldn't regenerate the response.",
          });
        });
      }
    } catch (e) {
      setState(() {
        messages.add({
          "role": "assistant",
          "content":
          "Unable to regenerate the response right now.",
        });
      });
    }

    setState(() {
      isTyping = false;
    });

    _scrollToBottom();
  }

  Future<void> speakMessage(
      String text,
      int index,
      ) async {
    if (speakingIndex == index) {
      await _tts.stop();

      setState(() {
        speakingIndex = null;
      });

      return;
    }

    await _tts.stop();

    setState(() {
      speakingIndex = index;
    });

    await _tts.speak(
      text
          .replaceAll("**", "")
          .replaceAll("###", "")
          .replaceAll("##", "")
          .replaceAll("#", ""),
    );
  }

  Future<void> copyMessage(String text) async {
    await Clipboard.setData(
      ClipboardData(text: text),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Copied"),
        duration: Duration(seconds: 1),
      ),
    );
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
      padding: const EdgeInsets.fromLTRB(
        18,
        20,
        18,
        10,
      ),
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
                        color:
                        Colors.cyanAccent.withOpacity(.35),
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
                padding:
                EdgeInsets.symmetric(horizontal: 35),
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

    final displayMessages =
    List<Map<String, String>>.from(messages);

    if (isTyping) {
      displayMessages.add({
        "role": "assistant",
        "content": "Typing...",
      });
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: displayMessages.length,
      itemBuilder: (_, index) {
        final message = displayMessages[index];

        final isUser =
            message["role"] == "user";

        if (message["content"] == "Typing...") {
          return const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(width: 12),
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.cyanAccent,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  "AI is typing...",
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          );
        }

        return Align(
          alignment: isUser
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(
              bottom: 12,
            ),
            padding: const EdgeInsets.all(14),
            constraints: const BoxConstraints(
              maxWidth: 320,
            ),
            decoration: BoxDecoration(
              color: isUser
                  ? const Color(0xff6C5CE7)
                  : const Color(0xff211A45),
              borderRadius:
              BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                MarkdownBody(
                  data: message["content"]!,
                  selectable: true,
                  styleSheet:
                  MarkdownStyleSheet(
                    p: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.6,
                    ),
                    strong: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    listBullet:
                    const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.end,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints:
                      const BoxConstraints(),
                      onPressed: () {
                        speakMessage(
                          message["content"]!,
                          index,
                        );
                      },
                      icon: Icon(
                        speakingIndex == index
                            ? Icons.stop_circle_outlined
                            : Icons.volume_up_outlined,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints:
                      const BoxConstraints(),
                      onPressed: () {
                        copyMessage(
                          message["content"]!,
                        );
                      },
                      icon: const Icon(
                        Icons.copy_outlined,
                        color: Colors.white70,
                        size: 19,
                      ),
                    ),
                    if (!isUser) ...[
                      const SizedBox(width: 12),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints:
                        const BoxConstraints(),
                        onPressed: isTyping
                            ? null
                            : () {
                          regenerateResponse(
                            index,
                          );
                        },
                        icon: const Icon(
                          Icons.refresh,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
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
              textInputAction:
              TextInputAction.send,
              onSubmitted: (_) => sendMessage(),
              style: const TextStyle(
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText:
                "Ask your doubt...",
                hintStyle:
                const TextStyle(
                  color: Colors.white38,
                ),
                filled: true,
                fillColor:
                const Color(0xff2A2355),
                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                const EdgeInsets.symmetric(
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
              color: isListening
                  ? const Color(0xff6C5CE7)
                  : const Color(0xff2A2355),
              borderRadius:
              BorderRadius.circular(24),
            ),
            child: IconButton(
              onPressed:
              isTyping ? null : _toggleListening,
              icon: Icon(
                isListening
                    ? Icons.mic
                    : Icons.mic_none,
                color: isListening
                    ? Colors.redAccent
                    : Colors.white,
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
              gradient:
              const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xff47E7FF),
                  Color(0xff9C4DFF),
                ],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xff47E7FF),
                  blurRadius: 12,
                ),
              ],
            ),
            child: IconButton(
              onPressed:
              isTyping ? null : sendMessage,
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