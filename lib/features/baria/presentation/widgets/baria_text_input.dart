import 'package:flutter/material.dart';

import '../../../../core/formatters/app_input_formatters.dart';
import '../../../../design_system/design_system.dart';

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
    if (widget.isLoading) return;
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    widget.onSendMessage(message);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: HBTextField(
            controller: _controller,
            label: 'Mensagem para a BarIA',
            hint: 'Digite sua pergunta...',
            enabled: !widget.isLoading,
            minLines: 1,
            maxLines: 4,
            inputFormatters: AppInputFormatters.text(maxLength: 500),
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.newline,
          ),
        ),
        const HBGap.horizontal(AppSpacing.sm),
        Semantics(
          button: true,
          label: widget.isLoading ? 'Enviando mensagem' : 'Enviar mensagem',
          child: SizedBox(
            width: AppSizes.buttonMinTapTarget,
            height: AppSizes.buttonMinTapTarget,
            child: IconButton.filled(
              tooltip: 'Enviar mensagem',
              onPressed: widget.isLoading ? null : _sendMessage,
              icon: widget.isLoading
                  ? const SizedBox.square(
                      dimension: AppSizes.iconSm,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ),
        ),
      ],
    );
  }
}
