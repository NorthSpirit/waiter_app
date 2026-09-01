import 'package:flutter/material.dart';
import 'package:waiter_app/theme/design_tokens.dart';
import 'package:waiter_app/theme/theme_manager.dart';

class MenuItemTile extends StatelessWidget {
  final String name;
  final String price;
  final int quantity;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const MenuItemTile({
    super.key,
    required this.name,
    required this.price,
    this.quantity = 0,
    required this.onTap,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeManager.instance,
      builder: (context, _) {
        final theme = ThemeManager.instance.currentTheme;

        final isInOrder = quantity > 0;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingMd,
              vertical: DesignTokens.spacingMd,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.brandLight.withValues(
                    alpha: DesignTokens.opacitySoft,
                  ),
                  width: DesignTokens.borderHairline,
                ),
              ),
            ),
            child: Row(
              children: [
                // Quantity badge if > 0 - tap to decrease by 1
                if (isInOrder) ...[
                  GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingSm,
                        vertical: DesignTokens.spacingXs,
                      ),
                      decoration: BoxDecoration(
                        color: theme.alert,
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusSm,
                        ),
                      ),
                      child: Text(
                        '$quantity',
                        style: TextStyle(
                          color: theme.base,
                          fontSize: DesignTokens.fontTiny,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: DesignTokens.spacingSm),
                ],
                // Name
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      color: isInOrder ? theme.brandLight : theme.content,
                      fontSize: DesignTokens.fontBody,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // Price button - tap to add
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingMd,
                      vertical: DesignTokens.spacingXs,
                    ),
                    decoration: BoxDecoration(
                      color: isInOrder ? theme.brandDark : theme.brandLight,
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusSm,
                      ),
                    ),
                    child: Text(
                      price,
                      style: TextStyle(
                        color: theme.base,
                        fontSize: DesignTokens.fontLabel,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
