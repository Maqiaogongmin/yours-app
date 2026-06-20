part of '../plan_page.dart';

class _SwipeActionsWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onEdit;
  final Future<bool> Function() onDelete;

  const _SwipeActionsWrapper({
    super.key,
    required this.child,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_SwipeActionsWrapper> createState() => _SwipeActionsWrapperState();
}

class _SwipeActionsWrapperState extends State<_SwipeActionsWrapper> {
  double _slideOffset = 0;
  bool _revealed = false;
  static const double _actionWidth = 160;
  double _dragStartOffset = 0;
  Offset? _pointerStart;
  bool _trackingHorizontalDrag = false;

  void _handlePointerDown(PointerDownEvent event) {
    _dragStartOffset = _slideOffset;
    _pointerStart = event.position;
    _trackingHorizontalDrag = false;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    final pointerStart = _pointerStart;
    if (pointerStart == null) {
      return;
    }

    final distance = event.position - pointerStart;
    if (!_trackingHorizontalDrag) {
      final isHorizontalDrag = distance.dx.abs() > 4 && distance.dx.abs() > distance.dy.abs();
      if (!isHorizontalDrag) {
        return;
      }
      _trackingHorizontalDrag = true;
    }

    setState(() {
      _slideOffset = (_dragStartOffset + distance.dx).clamp(-_actionWidth, 0);
    });
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (!_trackingHorizontalDrag) {
      _pointerStart = null;
      return;
    }

    final shouldReveal = _slideOffset < -_actionWidth * 0.5;

    setState(() {
      _revealed = shouldReveal;
      _slideOffset = shouldReveal ? -_actionWidth : 0;
    });
    _pointerStart = null;
    _trackingHorizontalDrag = false;
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _pointerStart = null;
    _trackingHorizontalDrag = false;
  }

  void _hideActions() {
    if (!_revealed && _slideOffset == 0) {
      return;
    }
    setState(() {
      _slideOffset = 0;
      _revealed = false;
    });
  }

  void _handleEditTap() {
    _hideActions();
    widget.onEdit();
  }

  Future<void> _handleDeleteTap() async {
    final deleted = await widget.onDelete();
    if (mounted && !deleted) {
      _hideActions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.child;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kCardRadius),
        child: SizedBox(
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Background action strip. A foreground copy below owns taps after reveal,
              // because transformed cards can still win hit testing on the exposed area.
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: SizedBox(
                  width: _actionWidth,
                  child: ExcludeSemantics(
                    child: IgnorePointer(
                      child: _ActionButtons(
                        onEdit: _handleEditTap,
                        onDelete: _handleDeleteTap,
                      ),
                    ),
                  ),
                ),
              ),
              // Card — tapping a revealed card closes it before start can fire again.
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _revealed ? _hideActions : null,
                child: Transform.translate(
                  offset: Offset(_slideOffset, 0),
                  child: AbsorbPointer(
                    absorbing: _revealed,
                    child: card,
                  ),
                ),
              ),
              if (_revealed)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: SizedBox(
                    width: _actionWidth,
                    child: _ActionButtons(onEdit: _handleEditTap, onDelete: _handleDeleteTap),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;

  const _ActionButtons({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onEdit,
            child: ColoredBox(
              color: kAccent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.edit_outlined, color: Colors.white, size: 24),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.commonEdit,
                    style: context
                        .yoursText(YoursTextRole.body)
                        .copyWith(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDelete,
            child: ColoredBox(
              color: kRed,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.commonDelete,
                    style: context
                        .yoursText(YoursTextRole.body)
                        .copyWith(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Plan Detail Page — select week/day before entering Gym Mode
// ═══════════════════════════════════════════════════════════════════════════════
