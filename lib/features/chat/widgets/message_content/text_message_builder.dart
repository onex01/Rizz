import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class TextMessageBuilder {
  static Widget build({
    required BuildContext context,
    required Map<String, dynamic> msgData,
    required bool isMe,
    required bool isLight,
    required Color accentColor,
    required double fontSize,
    required String time,
    required double screenWidth,
    required VoidCallback onCopy,
  }) {
    final text = msgData['text'] ?? '';
    final replyToId = msgData['replyToMessageId'] as String?;
    final repliedText = msgData['repliedMessageText'] as String?;
    final isRead = msgData['isRead'] == true;
    final isEdited = msgData['isEdited'] == true;

    final bubbleColor = isMe ? accentColor : (isLight ? Colors.grey[200]! : Colors.grey[800]!);
    final textColor = isMe ? Colors.white : (isLight ? Colors.black87 : Colors.white);

    final hasMarkdown = text.contains('```') || text.contains('**') || text.contains('*') || text.contains('`');

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: screenWidth * 0.78),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyToId != null && repliedText != null)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isMe ? Colors.white.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.reply, size: 14, color: Colors.white70),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        repliedText,
                        style: TextStyle(color: Colors.white70, fontSize: fontSize - 3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            if (hasMarkdown)
              MarkdownBody(
                data: text,
                selectable: true,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                  p: TextStyle(color: textColor, fontSize: fontSize),
                  code: TextStyle(
                    color: textColor,
                    backgroundColor: textColor.withValues(alpha: 0.15),
                    fontFamily: 'monospace',
                    fontSize: fontSize - 1,
                  ),
                  blockquoteDecoration: BoxDecoration(
                    border: Border(left: BorderSide(color: accentColor, width: 3)),
                  ),
                ),
              )
            else
              Linkify(
                text: text,
                style: TextStyle(color: textColor, fontSize: fontSize),
                linkStyle: TextStyle(
                  color: isMe ? Colors.white : Colors.blue,
                  decoration: TextDecoration.underline,
                ),
                onOpen: (link) async {
                  final uri = Uri.tryParse(link.url);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            if (isEdited)
              Text(
                'изменено',
                style: TextStyle(color: isMe ? Colors.white60 : Colors.grey.shade500, fontSize: fontSize - 6),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(time, style: TextStyle(color: isMe ? Colors.white70 : Colors.grey.shade500, fontSize: fontSize - 5)),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  if (isRead) const Icon(Icons.done_all, size: 14, color: Colors.white70) else const Icon(Icons.done, size: 14, color: Colors.white70),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}