import 'package:flutter/material.dart';

import '../../design_system.dart';

class HBAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HBAppBar({
    required this.title,
    super.key,
    this.subtitle,
    this.actions,
    this.leading,
    this.centerTitle = false,
    this.automaticallyImplyLeading = true,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => Size.fromHeight(subtitle == null ? 64 : 76);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      actions: actions,
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: AppSizes.iconMd,
      ),
      title: Semantics(
        header: true,
        child: Column(
          crossAxisAlignment: centerTitle
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            HBText(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (subtitle != null) ...[
              const HBGap.xs(),
              HBText(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
