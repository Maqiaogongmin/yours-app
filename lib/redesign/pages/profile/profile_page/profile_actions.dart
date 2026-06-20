part of '../profile_page.dart';

class _ProfilePageActions {
  _ProfilePageActions(this.state);

  final _ProfilePageState state;

  void setState(VoidCallback fn) => state._updateActionState(fn);

  Rect? _sharePositionOrigin() {
    final renderObject = state.context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return null;
    }
    final origin = renderObject.localToGlobal(Offset.zero);
    final viewSize = MediaQuery.sizeOf(state.context);
    final x = (origin.dx + renderObject.size.width / 2).clamp(1.0, viewSize.width - 1);
    final y = (origin.dy + renderObject.size.height / 2).clamp(1.0, viewSize.height - 1);
    return Rect.fromCenter(center: Offset(x, y), width: 1, height: 1);
  }

  String _friendlyDataError(Object error) {
    final rawText = '$error';
    if (rawText.contains('connection was closed') || rawText.contains('Tried to send Request')) {
      return state.context.l10n.profileDatabasePreparing;
    }
    return _localizedDataError(error);
  }

  String _localizedDataError(Object error) {
    return _localizedProfileDataError(state.context, error);
  }

  YoursDataManagementError _dataManagementError(Object error) {
    return YoursDataManagementError.raw(error);
  }

  void _showMessage(String message) {
    final safeMessage = message
        .replaceAll(
          RegExp(r'.*connection was closed.*', caseSensitive: false, dotAll: true),
          state.context.l10n.profileDatabasePreparing,
        )
        .replaceAll(
          RegExp(r'.*Tried to send Request.*', caseSensitive: false, dotAll: true),
          state.context.l10n.profileDatabasePreparing,
        )
        .replaceAll(
          RegExp(r'<!doctype html.*', caseSensitive: false, dotAll: true),
          state.context.l10n.profileServerReturnedHtml,
        )
        .replaceAll(
          RegExp(r'<html.*', caseSensitive: false, dotAll: true),
          state.context.l10n.profileServerReturnedHtml,
        )
        .replaceAll(
          RegExp(r'target-server', caseSensitive: false),
          state.context.l10n.profileTargetServer,
        );
    ScaffoldMessenger.of(state.context).showSnackBar(
      SnackBar(
        content: Text(safeMessage),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String fileName(String path) {
    final normalized = path.replaceAll(r'\', '/');
    final index = normalized.lastIndexOf('/');
    return index == -1 ? normalized : normalized.substring(index + 1);
  }
}
