import 'package:flutter/material.dart';
import 'package:waiter_app/theme/design_tokens.dart';
import 'package:waiter_app/theme/theme_manager.dart';

class TouchIconWidget extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const TouchIconWidget({
    super.key,
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager.instance,
      builder: (context, _) {
        final theme = ThemeManager.instance.currentTheme;

        return SizedBox(
          width: DesignTokens.touchStandard,
          height: DesignTokens.touchStandard,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? onTap : null,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              child: Center(
                child: Icon(
                  icon,
                  size: DesignTokens.iconMd,
                  color: enabled
                      ? theme.content
                      : theme.content.withValues(
                          alpha: DesignTokens.opacityDisabled,
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
