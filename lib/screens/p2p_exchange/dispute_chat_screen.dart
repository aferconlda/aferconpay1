import 'dart:io';

import 'package:afercon_pay/models/dispute_message_model.dart';
import 'package:afercon_pay/services/auth_service.dart';
import 'package:afercon_pay/services/p2p_exchange_service.dart';
import 'package:afercon_pay/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class DisputeChatScreen extends StatefulWidget {
  final String transactionId;

  const DisputeChatScreen({super.key, required this.transactionId});

  @override
  State<DisputeChatScreen> createState() => _DisputeChatScreenState();
}

class _DisputeChatScreenState extends State<DisputeChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final P2PExchangeService _exchangeService = P2PExchangeService();
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  String? _currentUserId;
  File? _proofImageFile;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final user = _authService.getCurrentUser();
    if (mounted) {
      setState(() => _currentUserId = user?.uid);
    }
  }

  Future<void> _selectProofImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _proofImageFile = File(image.path));
      // Automatically trigger send after picking an image
      _sendMessage(); 
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _proofImageFile == null) return;

    if (_currentUserId == null) return; // Cannot send without a user

    setState(() => _isUploading = true);

    try {
      String? imageUrl;
      if (_proofImageFile != null) {
        imageUrl = await _storageService.uploadDisputeProof(_proofImageFile!, widget.transactionId);
      }

      await _exchangeService.sendDisputeMessage(
        widget.transactionId,
        text,
        _currentUserId!,
        imageUrl: imageUrl,
      );

      _messageController.clear();
      setState(() => _proofImageFile = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao enviar: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Disputa de Transação')),
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(),
          ),
          if (_proofImageFile != null) _buildImagePreview(),
          const Divider(height: 1),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<List<DisputeMessage>>(
      stream: _exchangeService.getDisputeMessagesStream(widget.transactionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || _currentUserId == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Ainda não há mensagens nesta disputa.'));
        }

        final messages = snapshot.data!;
        return ListView.builder(
          reverse: true, // To show latest messages at the bottom
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMe = message.senderId == _currentUserId;
            return _MessageBubble(message: message, isMe: isMe);
          },
        );
      },
    );
  }

  Widget _buildImagePreview() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Image.file(_proofImageFile!, height: 100, width: 100, fit: BoxFit.cover),
          IconButton(
            icon: const CircleAvatar(backgroundColor: Colors.black54, child: Icon(Icons.close, color: Colors.white, size: 18)),
            onPressed: () => setState(() => _proofImageFile = null),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.upload_file), onPressed: _selectProofImage),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration.collapsed(hintText: 'Digite a sua mensagem...'),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          IconButton(
            icon: _isUploading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
            onPressed: (_isUploading || (_messageController.text.isEmpty && _proofImageFile == null)) ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final DisputeMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Card(
        color: isMe ? Theme.of(context).primaryColorLight : Colors.white,
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.imageUrl != null)
                Image.network(message.imageUrl!, height: 150),
              if (message.text.isNotEmpty)
                Text(message.text),
              const SizedBox(height: 4),
              Text(
                '${message.timestamp.toDate().hour}:${message.timestamp.toDate().minute}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
