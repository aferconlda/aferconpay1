import 'package:flutter/material.dart';

class BlinkingDot extends StatefulWidget {
  final Color color;
  final double size;

  const BlinkingDot({
    super.key,
    this.color = Colors.green,
    this.size = 8.0,
  });

  @override
  // A classe de estado agora é pública para corrigir o aviso da biblioteca.
  BlinkingDotState createState() => BlinkingDotState();
}

// A classe foi renomeada de _BlinkingDotState para BlinkingDotState.
class BlinkingDotState extends State<BlinkingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
