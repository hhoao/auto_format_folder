import 'package:flutter/material.dart';

class TabButton extends StatefulWidget {
  final VoidCallback onTap;
  final VoidCallback? onClose;
  final Widget child;

  const TabButton({required this.onTap, this.onClose, required this.child});

  @override
  State<TabButton> createState() => TabButtonState();
}

class TabButtonState extends State<TabButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: isHovered ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isHovered
                ? Colors.grey.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
