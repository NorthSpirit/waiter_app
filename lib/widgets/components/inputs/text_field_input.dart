import 'package:flutter/material.dart';
import 'package:waiter_app/theme/design_tokens.dart';
import 'package:waiter_app/theme/theme_manager.dart';

class TextFieldInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final int maxLines;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final String? hintText;
  final bool isPassword;

  const TextFieldInput({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.maxLines = 1,
    this.readOnly = false,
    this.onChanged,
    this.hintText,
    this.isPassword = false,
  });

  @override
  State<TextFieldInput> createState() => _TextFieldInputState();
}

class _TextFieldInputState extends State<TextFieldInput> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager.instance,
      builder: (context, _) {
        final theme = ThemeManager.instance.currentTheme;

        return Padding(
          padding: EdgeInsets.only(bottom: DesignTokens.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  color: theme.content,
                  fontSize: DesignTokens.fontLabel,
                  fontWeight: FontWeight.w600,
                  letterSpacing: DesignTokens.letterSpacingWide,
                ),
              ),
              SizedBox(height: DesignTokens.spacingXs),
              TextField(
                controller: widget.controller,
                maxLines: widget.isPassword ? 1 : widget.maxLines,
                readOnly: widget.readOnly,
                onChanged: widget.onChanged,
                obscureText: widget.isPassword ? _obscureText : false,
                style: TextStyle(
                  color: theme.content,
                  fontSize: DesignTokens.fontBody,
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    color: theme.content.withValues(
                      alpha: DesignTokens.opacitySoft,
                    ),
                    fontSize: DesignTokens.fontBody,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: DesignTokens.spacingLg,
                    horizontal: DesignTokens.spacingMd,
                  ),
                  prefixIcon: widget.icon != null
                      ? Icon(
                          widget.icon,
                          size: DesignTokens.iconSm,
                          color: theme.brandDark,
                        )
                      : null,
                  suffixIcon: widget.isPassword
                      ? IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: DesignTokens.iconSm,
                            color: theme.brandDark,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    borderSide: BorderSide(color: theme.brandLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    borderSide: BorderSide(
                      color: theme.brandDark,
                      width: DesignTokens.borderMedium,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    borderSide: BorderSide(
                      color: theme.brandDark.withValues(
                        alpha: DesignTokens.opacityMedium,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
