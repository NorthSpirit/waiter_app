import 'package:flutter/material.dart';
import 'package:waiter_app/theme/design_tokens.dart';
import 'package:waiter_app/theme/theme_manager.dart';

class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? leftActions;
  final List<Widget>? rightActions;
  final Widget? bottom;

  const StandardAppBar({
    super.key,
    this.title,
    this.leftActions,
    this.rightActions,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight((bottom != null ? 56 : 0) + kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager.instance,
      builder: (context, _) {
        final theme = ThemeManager.instance.currentTheme;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: kToolbarHeight,
              padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingSm),
              decoration: BoxDecoration(color: theme.base),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side — takes flexible space, same mechanism as
                  // the right side, so an Expanded button (e.g. STATUS)
                  // can stretch to fill it.
                  if (leftActions != null && leftActions!.isNotEmpty)
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: leftActions!,
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  // Center - Title (or placeholder)
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.content,
                          fontSize: DesignTokens.fontH1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                  // Right side - takes remaining space
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (rightActions != null && rightActions!.isNotEmpty)
                          ...rightActions!,
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (bottom != null) bottom!,
          ],
        );
      },
    );
  }
}