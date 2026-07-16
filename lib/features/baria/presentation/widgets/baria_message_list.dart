import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/models/models.dart';

class BariaMessageList extends StatefulWidget {
  const BariaMessageList({required this.messages, super.key});

  final List<BariaMessage> messages;

  @override
  State<BariaMessageList> createState() => _BariaMessageListState();
}

class _BariaMessageListState extends State<BariaMessageList> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void didUpdateWidget(BariaMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppDurations.normal,
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ListView.builder(
        controller: _scrollController,
        shrinkWrap: true,
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: widget.messages.length,
        itemBuilder: (context, index) {
          final message = widget.messages[index];
          return _MessageBubble(message: message);
        },
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final BariaMessage message;

  @override
  Widget build(BuildContext context) {
    final isFromUser = message.isFromUser;
    return Align(
      alignment: isFromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isFromUser ? AppColors.primaryLight : AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HBText(
              message.content,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (message.action?.destination != null) ...[
              const HBGap.sm(),
              HBButton(
                label: message.action!.label,
                onPressed: () => context.push(message.action!.destination!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
