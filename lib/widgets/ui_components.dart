import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/config.dart';
import '../theme/app_theme.dart';

enum BadgeTone { success, warning, danger, info, neutral }

BadgeTone getStatusTone(String? status) {
  switch (status?.toLowerCase()) {
    case 'active':
    case 'paid':
    case 'confirmed':
    case 'joined':
    case 'rewarded':
    case 'granted':
      return BadgeTone.success;
    case 'partial':
    case 'pending':
      return BadgeTone.warning;
    case 'frozen':
      return BadgeTone.info;
    case 'expired':
    case 'unpaid':
    case 'cancelled':
    case 'denied':
      return BadgeTone.danger;
    default:
      return BadgeTone.neutral;
  }
}

class AppBadge extends StatelessWidget {
  final String text;
  final BadgeTone tone;
  final IconData? icon;

  const AppBadge({
    super.key,
    required this.text,
    this.tone = BadgeTone.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (tone) {
      case BadgeTone.success:
        bg = AppColors.successSoft;
        fg = AppColors.success;
        break;
      case BadgeTone.warning:
        bg = AppColors.warningSoft;
        fg = AppColors.warning;
        break;
      case BadgeTone.danger:
        bg = AppColors.dangerSoft;
        fg = AppColors.danger;
        break;
      case BadgeTone.info:
        bg = AppColors.infoSoft;
        fg = AppColors.info;
        break;
      case BadgeTone.neutral:
        bg = AppColors.surfaceAlt;
        fg = AppColors.textMuted;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    final border = Border.all(
      color: borderColor ?? AppColors.border,
      width: borderWidth ?? 1.0,
    );

    final cardChild = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: border,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2A4A).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return cardChild;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap!();
        },
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: cardChild,
      ),
    );
  }
}

enum ButtonVariant { primary, secondary, ghost, danger, light }

class AppButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPress;
  final ButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool disabled;
  final bool small;

  const AppButton({
    super.key,
    required this.title,
    this.onPress,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.disabled = false,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border = Colors.transparent;

    switch (variant) {
      case ButtonVariant.primary:
        bg = AppColors.primary;
        fg = Colors.white;
        break;
      case ButtonVariant.secondary:
        bg = AppColors.primarySoft;
        fg = AppColors.primary;
        break;
      case ButtonVariant.ghost:
        bg = Colors.transparent;
        fg = AppColors.primary;
        border = AppColors.border;
        break;
      case ButtonVariant.danger:
        bg = AppColors.dangerSoft;
        fg = AppColors.danger;
        break;
      case ButtonVariant.light:
        bg = Colors.white;
        fg = AppColors.primary;
        break;
    }

    final isOff = disabled || loading;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isOff
            ? null
            : () {
                HapticFeedback.lightImpact();
                onPress?.call();
              },
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: isOff ? 0.5 : 1.0,
          child: Container(
            height: small ? 40 : 50,
            padding: EdgeInsets.symmetric(horizontal: small ? 14 : 20),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: border, width: border == Colors.transparent ? 0 : 1),
            ),
            alignment: Alignment.center,
            child: loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(fg),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: small ? 16 : 18, color: fg),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: small ? 13 : 15,
                          fontWeight: FontWeight.w600,
                          color: fg,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class AppProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final Color track;
  final double height;

  const AppProgressBar({
    super.key,
    required this.value,
    this.color = AppColors.primary,
    this.track = AppColors.surfaceAlt,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(height),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: clamped,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(height),
          ),
        ),
      ),
    );
  }
}

class AppAvatar extends StatelessWidget {
  final String name;
  final String? uri;
  final double size;

  /// Premium style for hero placements: a brand-gradient ring around the photo,
  /// and initials on a gradient fill instead of the pale default.
  final bool ring;

  const AppAvatar({
    super.key,
    required this.name,
    this.uri,
    this.size = 48,
    this.ring = false,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = AppConfig.mediaUrl(uri);
    final hasPhoto = photoUrl != null;

    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ring ? null : AppColors.primarySoft,
        gradient: ring
            ? const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: hasPhoto
          ? Image.network(
              photoUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => _defaultAvatar(),
            )
          : _defaultAvatar(),
    );

    if (!ring) return avatar;

    // Outer gradient ring + a thin background-coloured gap, so the photo "floats".
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.accent, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.bg,
        ),
        child: avatar,
      ),
    );
  }

  /// Default avatar shown until the member uploads a photo.
  Widget _defaultAvatar() {
    return Icon(
      Icons.person_rounded,
      size: size * 0.62,
      color: ring ? Colors.white : AppColors.primary,
    );
  }
}

class IconBubble extends StatelessWidget {
  final IconData name;
  final Color color;
  final Color bg;
  final double size;

  const IconBubble({
    super.key,
    required this.name,
    this.color = AppColors.primary,
    this.bg = AppColors.primarySoft,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      alignment: Alignment.center,
      child: Icon(name, size: size * 0.5, color: color),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18),
            ),
          ],
        ),
        if (action != null)
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onAction?.call();
            },
            child: Text(
              action!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}

class AppHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final Widget? right;

  const AppHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              onBack();
            },
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ?right,
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color tint;
  final Color bg;

  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.tint = AppColors.primary,
    this.bg = AppColors.primarySoft,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            IconBubble(name: icon, color: tint, bg: bg, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? action;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconBubble(name: icon, size: 64),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null && onAction != null) ...[
              const SizedBox(height: 16),
              AppButton(
                title: action!,
                onPress: onAction,
                variant: ButtonVariant.secondary,
                small: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorStateView extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;

  const ErrorStateView({
    super.key,
    this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      icon: Icons.cloud_off_outlined,
      title: "Couldn't load this",
      message: message ?? 'Check your connection and try again.',
      action: 'Try again',
      onAction: onRetry,
    );
  }
}

class LoadingBlock extends StatelessWidget {
  const LoadingBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}

class AppDivider extends StatelessWidget {
  final double leftIndent;
  const AppDivider({super.key, this.leftIndent = 52});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: leftIndent),
      child: const Divider(height: 1, thickness: 1, color: AppColors.border),
    );
  }
}

class SegmentedPicker<T> extends StatelessWidget {
  final List<({T value, String label, IconData? icon})> options;
  final T selected;
  final ValueChanged<T> onSelected;

  const SegmentedPicker({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = opt.value == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onSelected(opt.value);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 38,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (opt.icon != null) ...[
                      Icon(
                        opt.icon,
                        size: 17,
                        color: isSelected ? AppColors.primary : AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      opt.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? AppColors.primary : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Centered screen header: title, a short brand accent bar, and a one-line
/// description of what the screen contains.
class ScreenTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const ScreenTitle({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 6),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }
}
