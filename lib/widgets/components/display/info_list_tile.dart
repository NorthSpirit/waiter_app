import 'package:flutter/material.dart';
import 'package:waiter_app/theme/design_tokens.dart';
import 'package:waiter_app/theme/theme_manager.dart';

enum TrailingArrowType { nothing, chevron }

class InfoListTile extends StatelessWidget {
  final Widget? leading;
  final IconData? icon;
  final String? leadingText;
  final String title;
  final String? subtitle;
  final String? secondaryText;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isLongSubtitle;
  final bool showLeadingText;
  final Widget? overflowMenu;
  final bool showOverflowMenu;
  final TrailingArrowType arrowType;

  const InfoListTile({
    super.key,
    this.leading,
    this.icon,
    this.leadingText,
    required this.title,
    this.subtitle,
    this.secondaryText,
    this.trailing,
    this.onTap,
    this.isLongSubtitle = false,
    this.showLeadingText = true,
    this.overflowMenu,
    this.showOverflowMenu = false,
    this.arrowType = TrailingArrowType.nothing,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager.instance,
      builder: (context, _) {
        final theme = ThemeManager.instance.currentTheme;

        final hasSubtitle = subtitle != null && subtitle!.isNotEmpty;
        final hasSecondary = secondaryText != null && secondaryText!.isNotEmpty;

        Widget? leadingWidget;
        if (leading != null) {
          leadingWidget = leading;
        } else if (icon != null) {
          leadingWidget = Icon(
            icon,
            size: DesignTokens.iconMd,
            color: theme.brandLight,
          );
        }

        return ListTile(
          onTap: onTap,
          enabled: onTap != null,
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingSm,
          ),
          leading: SizedBox(
            width: DesignTokens.iconXl + DesignTokens.spacingLg,
            child: leadingWidget != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      leadingWidget!,
                      if (showLeadingText && leadingText != null) ...[
                        SizedBox(height: DesignTokens.spacingXs),
                        Flexible(
                          child: Text(
                            leadingText!,
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                            softWrap: false,
                            style: TextStyle(
                              fontSize: DesignTokens.fontTiny,
                              fontWeight: FontWeight.bold,
                              color: theme.content.withValues(
                                alpha: DesignTokens.opacityMedium,
                              ),
                              letterSpacing: DesignTokens.letterSpacingWide,
                              height: DesignTokens.lineHeightTight,
                            ),
                          ),
                        ),
                      ],
                    ],
                  )
                : null,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.content,
                    fontWeight: FontWeight.w600,
                    fontSize: DesignTokens.fontBody,
                    letterSpacing: DesignTokens.letterSpacingNormal,
                    height: DesignTokens.lineHeightNormal,
                  ),
                ),
              ),
              if (hasSecondary) ...[
                SizedBox(width: DesignTokens.spacingSm),
                Text(
                  secondaryText!,
                  style: TextStyle(
                    color: theme.brandLight,
                    fontWeight: FontWeight.w700,
                    fontSize: DesignTokens.fontBody,
                    letterSpacing: DesignTokens.letterSpacingNormal,
                  ),
                ),
              ],
            ],
          ),
          subtitle: hasSubtitle
              ? Text(
                  subtitle!,
                  maxLines: isLongSubtitle ? 3 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: DesignTokens.fontCaption,
                    letterSpacing: DesignTokens.letterSpacingNormal,
                    color: theme.content.withValues(
                      alpha: DesignTokens.opacitySoft,
                    ),
                  ),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailing != null) trailing!,
              if (showOverflowMenu && overflowMenu != null) ...[
                SizedBox(width: DesignTokens.spacingXs),
                overflowMenu!,
              ],
              if (arrowType == TrailingArrowType.chevron) ...[
                SizedBox(width: DesignTokens.spacingSm),
                Icon(
                  Icons.arrow_forward_ios,
                  size: DesignTokens.iconSm,
                  color: theme.brandLight.withValues(
                    alpha: DesignTokens.opacityMedium,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
