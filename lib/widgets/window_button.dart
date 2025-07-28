import 'package:flutter/material.dart';

class WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? hoverColor;
  final Color? activeColor;
  final Color? iconColor;
  final double containerSize;
  final double iconSize;

  const WindowButton({
    required this.icon,
    required this.onTap,
    this.hoverColor,
    this.activeColor,
    this.iconColor,
    this.containerSize = 40,
    this.iconSize = 16,
  });

  @override
  State<WindowButton> createState() => WindowButtonState();
}

class WindowButtonState extends State<WindowButton> {
  bool isHovered = false;
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: isHovered ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: (_) => setState(() => isPressed = true),
        onTapUp: (_) => setState(() => isPressed = false),
        onTapCancel: () => setState(() => isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.containerSize,
          height: widget.containerSize,
          decoration: BoxDecoration(
            color: isPressed
                ? (widget.activeColor ?? Colors.grey.withValues(alpha: 0.3))
                : isHovered
                ? (widget.hoverColor ?? Colors.grey.withValues(alpha: 0.2))
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.icon,
            size: widget.iconSize,
            color: widget.iconColor,
          ),
        ),
      ),
    );
  }
}