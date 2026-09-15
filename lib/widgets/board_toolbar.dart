import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../ui/colors.dart';

/// The row under the board: hint (with hints-left badge) and the grid-lines
/// toggle (locked until earned). There is no zoom — every board fits the
/// screen.
class BoardToolbar extends StatelessWidget {
  const BoardToolbar({
    super.key,
    required this.hintsLeft,
    required this.hintActive,
    required this.onHint,
    required this.gridUnlocked,
    required this.gridUnlockLevel,
    required this.gridOn,
    required this.onToggleGrid,
  });

  final int hintsLeft;

  /// True while a hint is showing (the button rests until the next tap).
  final bool hintActive;
  final VoidCallback? onHint;
  final bool gridUnlocked;
  final int gridUnlockLevel;
  final bool gridOn;
  final VoidCallback? onToggleGrid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hintLabel = hintsLeft > 0 ? l10n.toolHintLeft(hintsLeft) : l10n.toolHintNone;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ToolButton(
          tooltip: '${l10n.toolHint} · $hintLabel',
          icon: Icons.lightbulb_rounded,
          badge: '$hintsLeft',
          active: hintActive,
          onPressed: hintsLeft > 0 && !hintActive ? onHint : null,
        ),
        const SizedBox(width: 12),
        _ToolButton(
          tooltip: gridUnlocked ? l10n.toolGrid : l10n.toolGridLocked(gridUnlockLevel),
          icon: gridUnlocked ? Icons.grid_4x4_rounded : Icons.lock_rounded,
          active: gridUnlocked && gridOn,
          onPressed: gridUnlocked ? onToggleGrid : null,
        ),
      ],
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.tooltip,
    required this.icon,
    this.badge,
    this.active = false,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final String? badge;
  final bool active;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onPressed != null;
    return Semantics(
      label: tooltip,
      button: true,
      enabled: enabled,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: active ? p.primary : p.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: active ? p.primary : p.outlineSoft),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            child: SizedBox(
              width: 58,
              height: 54,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    icon,
                    size: 28,
                    color: active
                        ? Colors.white
                        : enabled
                            ? p.textInk
                            : p.textFaint,
                  ),
                  if (badge != null)
                    Positioned(
                      top: 6,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: enabled ? p.accentSun : p.outlineSoft,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          badge!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            // The badge is amber in both palettes, so its ink
                            // is the dark one: textInk goes near-white in the
                            // dark theme and the count disappeared.
                            color: enabled ? p.onAccent : p.textMuted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
