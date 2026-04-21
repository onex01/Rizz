// ==================== ИСПРАВЛЕННЫЙ chat_input_bar.dart ====================
// Добавлены RepaintBoundary вокруг всех BackdropFilter для «запекания» слоя
// на отдельном GPU-слое (композитор Flutter). Это сильно снижает лаги при
// анимации открытия клавиатуры, не меняя сам блюр и не убирая его.

import 'dart:ui';

import 'package:flutter/cupertino.dart';
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
        // Блок ответа (Reply) — запечённый слой
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
                      color: isLight ? Colors.black.withOpacity(0.07) : Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isLight ? Colors.black.withOpacity(0.12) : Colors.white.withOpacity(0.12),
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
                          icon: const Icon(CupertinoIcons.clear_circled_solid, color: Colors.grey, size: 22),
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

        // Основное поле (Liquid Glass) — запечённый слой
        RepaintBoundary(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                decoration: BoxDecoration(
                  color: isLight
                      ? Colors.white.withOpacity(0.78)
                      : const Color(0xFF1C1C1D).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isLight ? Colors.black.withOpacity(0.12) : Colors.white.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: widget.onAttachmentPressed,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isLight ? Colors.black.withOpacity(0.06) : Colors.white.withOpacity(0.1),
                        ),
                        child: Icon(
                          CupertinoIcons.paperclip,
                          color: isLight ? CupertinoColors.systemGrey : Colors.grey,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      key: widget.textFieldKey,
                      child: CupertinoTextField(
                        controller: widget.controller,
                        placeholder: 'Напишите, скучно...',
                        placeholderStyle: TextStyle(
                          color: isLight ? CupertinoColors.systemGrey : Colors.grey.shade400,
                          fontSize: 17,
                        ),
                        style: TextStyle(
                          color: isLight ? CupertinoColors.black : Colors.white,
                          fontSize: 17,
                        ),
                        decoration: const BoxDecoration(),
                        maxLines: 5,
                        minLines: 1,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        keyboardAppearance: isLight ? Brightness.light : Brightness.dark,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: widget.onChanged != null
                            ? (String _) => widget.onChanged!()
                            : null,
                        onSubmitted: widget.onSubmitted != null
                            ? (String _) => widget.onSubmitted!()
                            : null,
                      ),
                    ),
                    const SizedBox(width: 6),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: widget.controller,
                      builder: (context, value, child) {
                        final hasText = value.text.trim().isNotEmpty;
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                          child: hasText
                              ? CupertinoButton(
                                  key: const ValueKey('send'),
                                  padding: EdgeInsets.zero,
                                  onPressed: widget.onSend,
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(shape: BoxShape.circle, color: widget.accentColor),
                                    child: const Icon(CupertinoIcons.arrow_up_circle_fill, color: Colors.white, size: 24),
                                  ),
                                )
                              : CupertinoButton(
                                  key: const ValueKey('mic'),
                                  padding: EdgeInsets.zero,
                                  onPressed: () {},
                                  onLongPress: widget.onVoiceRecording,
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isLight ? Colors.black.withOpacity(0.06) : Colors.white.withOpacity(0.1),
                                    ),
                                    child: Icon(CupertinoIcons.mic, color: isLight ? CupertinoColors.systemGrey : Colors.grey, size: 24),
                                  ),
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