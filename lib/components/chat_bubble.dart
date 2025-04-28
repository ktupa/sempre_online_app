import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final DateTime time;
  final bool isMe;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.time,
    required this.isMe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bgColor =
        isMe ? cs.primary.withOpacity(0.15) : cs.surface.withOpacity(0.9);

    final textColor = isMe ? cs.onPrimary : cs.onSurface.withOpacity(0.9);

    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    final radius =
        isMe
            ? const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            )
            : const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            );

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: bgColor, borderRadius: radius),
          child: Text(
            message,
            style: TextStyle(color: textColor, fontSize: 14),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12, right: 12, bottom: 4),
          child: Text(
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 10,
              color: cs.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      ],
    );
  }
}
