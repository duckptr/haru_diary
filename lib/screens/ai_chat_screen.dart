import 'package:flutter/material.dart';
import 'package:haru_diary/widgets/cloud_card.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({Key? key}) : super(key: key);

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<Map<String, String>> _messages = [];

  // UI 규격
  static const double _inputBarHeight = 56;
  static const double _maxBubbleWidthFactor = 0.78;

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "content": text});
    });
    _controller.clear();
    _scrollToBottom();

    // 데모용 AI 응답
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

  void _goBackToHome() {
    // 스택을 비우고 홈을 루트로 이동
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  Future<bool> _handleSystemBack() async {
    _goBackToHome();
    return false; // 기본 pop 막기
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
            onPressed: _goBackToHome,
          ),
        ),
        body: Column(
          children: [
            // 메시지 리스트
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg["role"] == "user";
                  final bubbleColor =
                      isUser ? cs.primary : cs.surfaceVariant;
                  final textColor = isUser ? cs.onPrimary : cs.onSurface;

                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width *
                            _maxBubbleWidthFactor,
                      ),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 14),
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
                                  color:
                                      cs.outlineVariant.withOpacity(0.6),
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

            // 하단 입력바
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: CloudCard(
                  radius: 20,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: SizedBox(
                    height: _inputBarHeight,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            onSubmitted: (_) => _sendMessage(),
                            maxLines: 1,
                            textAlignVertical: TextAlignVertical.center,
                            decoration: const InputDecoration(
                              hintText: "메시지를 입력하세요...",
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: '전송',
                          icon: const Icon(Icons.send),
                          color: cs.primary,
                          onPressed: _sendMessage,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 40, minHeight: 40),
                          iconSize: 22,
                        ),
                      ],
                    ),
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
