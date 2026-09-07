import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScaKeyboardDialog extends StatelessWidget {
  const ScaKeyboardDialog({
    required this.child,
    this.dismissOnEscape = true,
    this.dismissValue,
    super.key,
  });

  final Widget child;
  final bool dismissOnEscape;
  final Object? dismissValue;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      child: Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          const SingleActivator(LogicalKeyboardKey.escape): const _DismissDialogIntent(),
          const SingleActivator(LogicalKeyboardKey.arrowLeft): const _MoveFocusIntent(TraversalDirection.left),
          const SingleActivator(LogicalKeyboardKey.arrowRight): const _MoveFocusIntent(TraversalDirection.right),
          const SingleActivator(LogicalKeyboardKey.arrowUp): const _MoveFocusIntent(TraversalDirection.up),
          const SingleActivator(LogicalKeyboardKey.arrowDown): const _MoveFocusIntent(TraversalDirection.down),
          const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _DismissDialogIntent: CallbackAction<_DismissDialogIntent>(
              onInvoke: (_) {
                if (dismissOnEscape) {
                  Navigator.of(context).pop(dismissValue);
                }
                return null;
              },
            ),
            _MoveFocusIntent: CallbackAction<_MoveFocusIntent>(
              onInvoke: (intent) {
                FocusScope.of(context).focusInDirection(intent.direction);
                return null;
              },
            ),
          },
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _DismissDialogIntent extends Intent {
  const _DismissDialogIntent();
}

class _MoveFocusIntent extends Intent {
  const _MoveFocusIntent(this.direction);

  final TraversalDirection direction;
}
