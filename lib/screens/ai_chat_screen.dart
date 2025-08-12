import 'package:flutter/material.dart';
import 'package:haru_diary/widgets/cloud_card.dart';
import 'package:haru_diary/theme/app_theme.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({Key? key}) : super(key: key);

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<Map<String, String>> _messages = [];

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "content": text});
    });
    _controller.clear();
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _messages.add({
          "role": "ai",
          "content": "AI 응답 예시: '$text'에 대한 답변입니다."
        });
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<bool> _handleSystemBack() async {
    if (Navigator.of(context).canPop()) {
      return true; // 기존 스택으로 정상 뒤로가기
    }
    Navigator.pushReplacementNamed(context, '/home'); // 스택 없으면 홈으로
    return false; // 여기서 소모
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return WillPopScope(
      onWillPop: _handleSystemBack,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("AI 채팅"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.pushReplacementNamed(context, '/home');
              }
            },
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg["role"] == "user";
                  final bubbleColor = isUser ? AppTheme.primaryBlue : cs.surfaceVariant;
                  final textColor = isUser ? Colors.white : cs.onSurface;

                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78,
                      ),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: bubbleColor,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isUser ? 18 : 6),
                            bottomRight: Radius.circular(isUser ? 6 : 18),
                          ),
                          border: isUser
                              ? null
                              : Border.all(
                                  color: cs.outlineVariant.withValues(alpha: 0.6),
                                ),
                        ),
                        child: Text(
                          msg["content"] ?? "",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: textColor,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: CloudCard(
                  radius: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: const InputDecoration.collapsed(
                            hintText: "메시지를 입력하세요...",
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: '전송',
                        icon: const Icon(Icons.send),
                        color: AppTheme.primaryBlue,
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
