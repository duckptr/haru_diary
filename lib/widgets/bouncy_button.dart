import 'package:flutter/material.dart';

class BouncyButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;
  final Color color;
  final TextStyle? textStyle;
  final bool isLoading; // ✅ 로딩 상태 추가
  final bool enabled;

  const BouncyButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.color = const Color(0xFF0064FF),
    this.textStyle,
    this.isLoading = false, // ✅ 기본값 false
    this.enabled = true,
  });

  @override
  State<BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<BouncyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.8,
      upperBound: 1.0,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.enabled && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.enabled && !widget.isLoading) {
      _controller.forward();
      widget.onPressed();
    }
  }

  void _onTapCancel() {
    if (widget.enabled && !widget.isLoading) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Opacity(
          opacity: widget.enabled ? 1.0 : 0.6,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(24),
            ),
            child: widget.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    widget.text,
                    style: widget.textStyle ??
                        const TextStyle(color: Colors.white, fontSize: 16),
                  ),
          ),
        ),
      ),
    );
  }
}
