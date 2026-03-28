import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageList extends StatefulWidget {
  final String chatId;
  final String currentUserId;
   final ScrollController scrollController;
  final Function(String, String) onReplySwipe;

  // Новые коллбеки для iOS-меню
  final Function(String, String) onReply;
  final Function(String) onCopy;
  final Function(String, String) onEdit;
  final Function(String) onDeleteMe;
  final Function(String) onDeleteAll;
  final Function() onForward;

  const MessageList({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.scrollController,
     required this.onReplySwipe,
    required this.onReply,
    required this.onCopy,
    required this.onEdit,
    required this.onDeleteMe,
    required this.onDeleteAll,
    required this.onForward,
  });

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Widget> _buildMessageMenuActions(bool isMe, String messageId, String text) {
    return [
      CupertinoContextMenuAction(
        child: const Text('Ответить'),
        trailingIcon: Icons.reply,
        onPressed: () {
          Navigator.pop(context);
          widget.onReply(messageId, text);
        },
      ),
      CupertinoContextMenuAction(
        child: const Text('Копировать'),
        trailingIcon: Icons.copy,
        onPressed: () {
          Navigator.pop(context);
          widget.onCopy(text);
        },
      ),
      if (isMe)
        CupertinoContextMenuAction(
          child: const Text('Изменить'),
          trailingIcon: Icons.edit,
          onPressed: () {
            Navigator.pop(context);
            widget.onEdit(messageId, text);
          },
        ),
      CupertinoContextMenuAction(
        child: const Text('Удалить у меня'),
        trailingIcon: Icons.delete_outline,
        onPressed: () {
          Navigator.pop(context);
          widget.onDeleteMe(messageId);
        },
      ),
      if (isMe)
        CupertinoContextMenuAction(
          isDestructiveAction: true,
          child: const Text('Удалить у всех'),
          trailingIcon: Icons.delete_forever,
          onPressed: () {
            Navigator.pop(context);
            widget.onDeleteAll(messageId);
          },
        ),
      CupertinoContextMenuAction(
        child: const Text('Переслать'),
        trailingIcon: Icons.forward,
        onPressed: () {
          Navigator.pop(context);
          widget.onForward();
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Нет сообщений. Напишите первое!'));
        }

         final messages = snapshot.data!.docs;
 
        return ListView.builder(
          controller: widget.scrollController,
          reverse: true,
          padding: const EdgeInsets.all(12),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msgData = messages[index].data() as Map<String, dynamic>;
            final isMe = msgData['senderId'] == widget.currentUserId;
            final timestamp = msgData['timestamp'] as Timestamp?;
            final time = timestamp != null ? DateFormat('HH:mm').format(timestamp.toDate()) : '';

            final replyToId = msgData['replyToMessageId'] as String?;
            final repliedText = msgData['repliedMessageText'] as String?;
            final isDeleted = msgData['isDeleted'] == true;
            final messageText = msgData['text'] ?? '';
            final isRead = msgData['read'] == true;

            if (isDeleted) {
              return Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Сообщение удалено',
                    style: TextStyle(
                      color: isLight ? Colors.grey[500] : Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              );
            }

            // Адаптивные цвета под светлую/тёмную тему
            final bubbleColor = isMe
                ? (isLight ? const Color(0xFF007AFF) : Colors.blue) // iOS-синий в светлой теме
                : (isLight ? CupertinoColors.systemGrey5 : Colors.grey[800]!);

            final textColor = isMe
                ? Colors.white
                : (isLight ? CupertinoColors.label : Colors.white);

            final timeColor = isLight
                ? CupertinoColors.secondaryLabel
                : Colors.white.withOpacity(0.7);

            final replyContainerColor = isLight
                ? Colors.black.withOpacity(0.06)
                : Colors.black.withOpacity(0.25);

            return Dismissible(
              key: ValueKey(messages[index].id),
              direction: DismissDirection.startToEnd,
              confirmDismiss: (direction) async {
                widget.onReplySwipe(messages[index].id, messageText);
                return false;
              },
              background: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.only(left: 20),
                alignment: Alignment.centerLeft,
                color: Colors.blue,
                child: const Row(
                  children: [
                    Icon(Icons.reply, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Ответить', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              child: Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: CupertinoContextMenu.builder(
                  actions: _buildMessageMenuActions(isMe, messages[index].id, messageText),
                  builder: (BuildContext context, Animation<double> animation) {
                    final scale = 1.0 + (animation.value * 0.025);
                    final lift = -5.0 * animation.value;

                    return Transform.translate(
                      offset: Offset(0, lift),
                      child: Transform.scale(
                        scale: scale,
                        child: Material(
                          elevation: 10 * animation.value,
                          shadowColor: Colors.black.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(18),
                          color: Colors.transparent,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              constraints: BoxConstraints(maxWidth: screenWidth * 0.78),
                              margin: const EdgeInsets.symmetric(vertical: 4),
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
                                        color: replyContainerColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.reply, size: 16, color: Colors.white70),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              repliedText,
                                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Text(
                                    messageText,
                                    style: TextStyle(color: textColor, fontSize: 16),
                                  ),
                                  if (msgData['isEdited'] == true)
                                    Text(
                                      'изменено',
                                      style: TextStyle(
                                        color: isMe
                                            ? Colors.white60
                                            : (isLight ? CupertinoColors.secondaryLabel : Colors.white60),
                                        fontSize: 10,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        time,
                                        style: TextStyle(color: timeColor, fontSize: 11),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 4),
                                        if (isRead)
                                          const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.done, size: 14, color: Colors.white),
                                              Icon(Icons.done, size: 14, color: Colors.white),
                                            ],
                                          )
                                        else
                                          Icon(
                                            Icons.done,
                                            size: 14,
                                            color: isLight ? CupertinoColors.secondaryLabel : Colors.grey[400],
                                          ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}