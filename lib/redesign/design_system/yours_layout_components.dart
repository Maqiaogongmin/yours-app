part of 'yours_components.dart';

class YoursPageHeader extends StatelessWidget {
  const YoursPageHeader({super.key, required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.yoursText(YoursTextRole.pageTitle)),
                if (subtitle != null) ...[
                  const SizedBox(height: 5),
                  Text(subtitle!, style: context.yoursText(YoursTextRole.bodyMuted)),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class YoursSurfaceCard extends StatelessWidget {
  const YoursSurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.role = YoursSurfaceRole.card,
    this.padding,
    this.margin,
    this.shadow = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final YoursSurfaceRole role;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(context.yoursRadius(YoursRadiusRole.card));
    final content = Container(
      width: double.infinity,
      margin: margin,
      padding: padding ?? context.yoursPadding(YoursSpacingRole.cardPadding),
      decoration: BoxDecoration(
        color: context.yoursSurface(role),
        borderRadius: borderRadius,
        border: Border.all(color: context.yoursSurfaceBorder(role)),
        boxShadow: shadow ? context.yoursCardShadow : null,
      ),
      child: child,
    );
    if (onTap == null) {
      return content;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: borderRadius, onTap: onTap, child: content),
    );
  }
}

class YoursBrandMark extends StatelessWidget {
  const YoursBrandMark({super.key, this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(context.yoursBrandMarkRadius(size)),
      child: Image.asset(
        'assets/images/yours-icon-512.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}

class YoursPageScaffold extends StatelessWidget {
  const YoursPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.padding,
  });

  final String title;
  final Widget child;
  final VoidCallback? onClose;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    return Scaffold(
      backgroundColor: context.yoursSurface(YoursSurfaceRole.page),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: onClose ?? () => Navigator.maybePop(context),
                    icon: Icon(Icons.close_rounded, color: palette.fg),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.yoursText(YoursTextRole.cardTitle),
                    ),
                  ),
                  if (primaryActionLabel == null)
                    const SizedBox(width: 48)
                  else
                    TextButton(
                      onPressed: onPrimaryAction,
                      child: Text(
                        primaryActionLabel!,
                        style: context.yoursText(YoursTextRole.button, tone: YoursTone.accent),
                      ),
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: palette.border),
            Expanded(
              child: ListView(
                padding: padding ?? context.yoursPadding(YoursSpacingRole.pageInset),
                children: [child],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class YoursSheetShell extends StatelessWidget {
  const YoursSheetShell({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.yoursPalette;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final maxHeight = MediaQuery.sizeOf(context).height - viewInsets.bottom - 24;
    final sheetMaxHeight = maxHeight < 240 ? 240.0 : maxHeight;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: Container(
          margin: const EdgeInsets.all(12),
          constraints: BoxConstraints(maxHeight: sheetMaxHeight),
          padding: const EdgeInsets.only(left: 18, right: 18, top: 14, bottom: 18),
          decoration: BoxDecoration(
            color: context.yoursSurface(YoursSurfaceRole.elevated),
            borderRadius: BorderRadius.circular(context.yoursRadius(YoursRadiusRole.sheet)),
            border: Border.all(color: palette.border),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.yoursText(YoursTextRole.pageTitle).copyWith(fontSize: 22),
                      ),
                    ),
                    ?trailing,
                  ],
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [child],
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

class YoursSectionHeader extends StatelessWidget {
  const YoursSectionHeader(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: context.yoursText(YoursTextRole.label),
      ),
    );
  }
}
