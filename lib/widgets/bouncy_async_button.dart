import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class BouncyAsyncButton extends StatefulWidget {
  final String text;
  final Future<void> Function() onPressed;
  final VoidCallback onFinished;
  final Color color;
  final TextStyle? textStyle;

  const BouncyAsyncButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.onFinished,
    this.color = const Color(0xFF0B872C),
    this.textStyle,
  });

  @override
  State<BouncyAsyncButton> createState() => _BouncyAsyncButtonState();
}

class _BouncyAsyncButtonState extends State<BouncyAsyncButton>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  bool _loading = false;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.8,
      upperBound: 1.0,
    )..forward();
  }

  void _onTapDown(TapDownDetails details) => _pressController.reverse();
  void _onTapUp(TapUpDetails details) async {
    _pressController.forward();
    setState(() => _loading = true);
    await widget.onPressed();
    setState(() {
      _loading = false;
      _success = true;
    });
  }

  void _onTapCancel() => _pressController.forward();

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _pressController,
        curve: Curves.elasticOut,
      ),
      child: GestureDetector(
        onTapDown: _loading || _success ? null : _onTapDown,
        onTapUp: _loading || _success ? null : _onTapUp,
        onTapCancel: _loading || _success ? null : _onTapCancel,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(24),
          ),
          child: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : _success
                  ? Lottie.asset(
                      'assets/animations/done.json',
                      width: 60,
                      height: 60,
                      repeat: false,
                      onLoaded: (comp) async {
                        await Future.delayed(comp.duration);
                        if (mounted) widget.onFinished();
                      },
                    )
                  : Text(
                      widget.text,
                      style: widget.textStyle ??
                          const TextStyle(color: Colors.white, fontSize: 16),
                    ),
        ),
      ),
    );
  }
}
