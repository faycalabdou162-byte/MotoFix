import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/motofix_ui.dart';
import '../../models/feature_models.dart';
import '../../services/chat_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.requestId, this.title = 'Chat'});

  final String requestId;
  final String title;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  bool sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || sending) return;

    setState(() => sending = true);
    try {
      await _chatService.sendText(requestId: widget.requestId, text: text);
      _messageController.clear();
    } catch (error) {
      _showMessage('Envoi impossible: $error');
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> _sendLocation() async {
    if (sending) return;
    setState(() => sending = true);
    try {
      await _chatService.sendCurrentLocation(widget.requestId);
    } catch (error) {
      _showMessage('Position impossible: $error');
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> _sendReference({required bool voice}) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(voice ? 'Lien audio' : 'Lien photo'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: voice
                  ? 'https://.../message-vocal.m4a'
                  : 'https://.../photo-panne.jpg',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Envoyer'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (result == null || result.isEmpty) return;

    setState(() => sending = true);
    try {
      if (voice) {
        await _chatService.sendVoiceReference(
          requestId: widget.requestId,
          voiceUrl: result,
        );
      } else {
        await _chatService.sendPhotoReference(
          requestId: widget.requestId,
          photoUrl: result,
        );
      }
    } catch (error) {
      _showMessage('Envoi impossible: $error');
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return MotoFixUi.page(
      appBar: MotoFixUi.appBar(widget.title),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<ChatMessageModel>>(
                stream: _chatService.watchMessages(widget.requestId),
                builder: (context, snapshot) {
                  final messages = snapshot.data ?? const <ChatMessageModel>[];

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: MotoFixUi.orange),
                    );
                  }

                  if (messages.isEmpty) {
                    return const _EmptyChat();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return _MessageBubble(message: messages[index]);
                    },
                  );
                },
              ),
            ),
            _Composer(
              controller: _messageController,
              sending: sending,
              onSend: _sendText,
              onLocation: _sendLocation,
              onPhoto: () => _sendReference(voice: false),
              onVoice: () => _sendReference(voice: true),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    final isDriver = message.senderRole == 'driver';
    final isAdmin = message.senderRole == 'admin';
    final align = isDriver || isAdmin ? Alignment.centerLeft : Alignment.centerRight;
    final color = isDriver || isAdmin ? MotoFixUi.panel : MotoFixUi.orange;
    final textColor = isDriver || isAdmin ? Colors.white : Colors.white;
    final date = message.createdAt == null
        ? ''
        : DateFormat('HH:mm').format(message.createdAt!);

    return Align(
      alignment: align,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 310),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDriver || isAdmin ? Colors.white12 : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.senderName,
              style: TextStyle(
                color: textColor.withValues(alpha: .82),
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 5),
            _MessageContent(message: message, textColor: textColor),
            if (date.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                date,
                style: TextStyle(
                  color: textColor.withValues(alpha: .72),
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MessageContent extends StatelessWidget {
  const _MessageContent({required this.message, required this.textColor});

  final ChatMessageModel message;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    if (message.type == ChatMessageType.location && message.location != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_outlined, color: textColor, size: 18),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              '${message.location!.latitude.toStringAsFixed(5)}, '
              '${message.location!.longitude.toStringAsFixed(5)}',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      );
    }

    if (message.type == ChatMessageType.photo) {
      return _ReferenceLine(
        icon: Icons.photo_outlined,
        label: message.text,
        url: message.photoUrl,
        color: textColor,
      );
    }

    if (message.type == ChatMessageType.voice) {
      return _ReferenceLine(
        icon: Icons.mic_none,
        label: message.text,
        url: message.voiceUrl,
        color: textColor,
      );
    }

    return Text(message.text, style: TextStyle(color: textColor));
  }
}

class _ReferenceLine extends StatelessWidget {
  const _ReferenceLine({
    required this.icon,
    required this.label,
    required this.url,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String url;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            url.isEmpty ? label : '$label\n$url',
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.onLocation,
    required this.onPhoto,
    required this.onVoice,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onLocation;
  final VoidCallback onPhoto;
  final VoidCallback onVoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF071322),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Position',
            onPressed: sending ? null : onLocation,
            icon: const Icon(Icons.my_location_outlined, color: MotoFixUi.orange),
          ),
          IconButton(
            tooltip: 'Photo',
            onPressed: sending ? null : onPhoto,
            icon: const Icon(Icons.photo_outlined, color: MotoFixUi.textSoft),
          ),
          IconButton(
            tooltip: 'Vocal',
            onPressed: sending ? null : onVoice,
            icon: const Icon(Icons.mic_none, color: MotoFixUi.textSoft),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Message',
                hintStyle: const TextStyle(color: MotoFixUi.textSoft),
                filled: true,
                fillColor: MotoFixUi.panel,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          IconButton(
            tooltip: 'Envoyer',
            onPressed: sending ? null : onSend,
            icon: sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: MotoFixUi.orange,
                    ),
                  )
                : const Icon(Icons.send_outlined, color: MotoFixUi.orange),
          ),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Aucun message. Envoyez un message, une position ou une photo de panne.',
          textAlign: TextAlign.center,
          style: TextStyle(color: MotoFixUi.textSoft),
        ),
      ),
    );
  }
}
