import 'dart:ui';
import 'package:flutter/material.dart';

class ChatInputBar extends StatefulWidget {
  final String? replyingToText;
  final VoidCallback onCancelReply;
  final VoidCallback onAttachmentPressed;
  final VoidCallback onSend;
  final VoidCallback onVoiceRecording;
  final TextEditingController controller;
  final Color accentColor;

  final GlobalKey? textFieldKey;
  final VoidCallback? onChanged;
  final VoidCallback? onSubmitted;

  const ChatInputBar({
    super.key,
    this.replyingToText,
    required this.onCancelReply,
    required this.onAttachmentPressed,
    required this.onSend,
    required this.onVoiceRecording,
    required this.controller,
    required this.accentColor,
    this.textFieldKey,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Блок "Ответ" (при наличии)
        if (widget.replyingToText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RepaintBoundary(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isLight ? Colors.black.withValues(alpha: 0.07) : Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isLight ? Colors.black.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.12),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(width: 3, height: 36, color: widget.accentColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Ответ', style: TextStyle(color: widget.accentColor, fontSize: 13, fontWeight: FontWeight.w600)),
                              Text(
                                widget.replyingToText!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: isLight ? Colors.black87 : Colors.white70, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.grey, size: 22),
                          onPressed: widget.onCancelReply,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Основное поле ввода (стекло)
        RepaintBoundary(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                decoration: BoxDecoration(
                  color: isLight
                      ? Colors.white.withValues(alpha: 0.78)
                      : const Color(0xFF1C1C1D).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isLight ? Colors.black.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Кнопка вложения
                    IconButton(
                      icon: Icon(Icons.attach_file, color: isLight ? Colors.grey.shade600 : Colors.grey.shade400),
                      onPressed: widget.onAttachmentPressed,
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                    ),
                    const SizedBox(width: 6),
                    // Текстовое поле
                    Expanded(
                      key: widget.textFieldKey,
                      child: TextField(
                        controller: widget.controller,
                        decoration: InputDecoration(
                          hintText: 'Напишите, скучно...',
                          hintStyle: TextStyle(color: isLight ? Colors.grey.shade500 : Colors.grey.shade400, fontSize: 17),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        ),
                        style: TextStyle(color: isLight ? Colors.black : Colors.white, fontSize: 17),
                        maxLines: 5,
                        minLines: 1,
                        keyboardAppearance: isLight ? Brightness.light : Brightness.dark,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: widget.onChanged != null ? (_) => widget.onChanged!() : null,
                        onSubmitted: widget.onSubmitted != null ? (_) => widget.onSubmitted!() : null,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Кнопка отправки / микрофон
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: widget.controller,
                      builder: (context, value, child) {
                        final hasText = value.text.trim().isNotEmpty;
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                          child: hasText
                              ? IconButton(
                                  key: const ValueKey('send'),
                                  icon: Icon(Icons.send_rounded, color: widget.accentColor, size: 24),
                                  onPressed: widget.onSend,
                                  splashRadius: 20,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                                )
                              : IconButton(
                                  key: const ValueKey('mic'),
                                  icon: Icon(Icons.mic, color: isLight ? Colors.grey.shade600 : Colors.grey.shade400, size: 24),
                                  onPressed: null,
                                  onLongPress: widget.onVoiceRecording,
                                  splashRadius: 20,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                                ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}