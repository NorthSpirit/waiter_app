import 'package:flutter/material.dart';
import 'package:waiter_app/theme/app_color_theme.dart';
import 'package:waiter_app/theme/design_tokens.dart';
import 'package:waiter_app/theme/theme_manager.dart';

class MiscButtonWidget extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isNegative;

  const MiscButtonWidget({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager.instance,
      builder: (context, _) {
        final theme = ThemeManager.instance.currentTheme;

        return ElevatedButton(
          onPressed: (onPressed != null && !isLoading) ? onPressed : null,
          style: _style(theme),
          child: isLoading
              ? SizedBox(
                  height: DesignTokens.iconSm,
                  width: DesignTokens.iconSm,
                  child: CircularProgressIndicator(
                    strokeWidth: DesignTokens.borderThin,
                    color: isNegative ? theme.base : theme.base,
                  ),
                )
              : Text(label),
        );
      },
    );
  }

  ButtonStyle _style(AppColorTheme theme) {
    return ElevatedButton.styleFrom(
      backgroundColor: isNegative ? theme.alert : theme.brandDark,
      foregroundColor: theme.base,
      disabledBackgroundColor: theme.content.withValues(
        alpha: DesignTokens.opacityDisabled,
      ),
      disabledForegroundColor: theme.base.withValues(
        alpha: DesignTokens.opacityDisabled,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
      elevation: 0,
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingLg,
        vertical: DesignTokens.spacingMd,
      ),
      textStyle: TextStyle(
        fontSize: DesignTokens.fontBody,
        fontWeight: FontWeight.w600,
        letterSpacing: DesignTokens.letterSpacingWide,
      ),
    );
  }
}
