import 'package:flutter/material.dart';

class BariaTextInput extends StatefulWidget {
  const BariaTextInput({
    required this.onSendMessage,
    this.isLoading = false,
    super.key,
  });

  final Function(String) onSendMessage;
  final bool isLoading;

  @override
  State<BariaTextInput> createState() => _BariaTextInputState();
}

class _BariaTextInputState extends State<BariaTextInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    widget.onSendMessage(message);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            enabled: !widget.isLoading,
            decoration: InputDecoration(
              hintText: 'Digite sua pergunta...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            maxLines: null,
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: widget.isLoading ? null : _sendMessage,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isLoading ? Colors.grey : Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.send, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
