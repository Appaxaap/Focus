import 'dart:async';

enum DesktopShellEventType {
  showWindow,
  openCommandPalette,
  quickAddTask,
}

class DesktopShellEvent {
  final DesktopShellEventType type;
  const DesktopShellEvent(this.type);
}

class DesktopEventBus {
  DesktopEventBus._();
  static final DesktopEventBus instance = DesktopEventBus._();

  final StreamController<DesktopShellEvent> _controller =
      StreamController<DesktopShellEvent>.broadcast();

  Stream<DesktopShellEvent> get stream => _controller.stream;

  void emit(DesktopShellEventType type) {
    _controller.add(DesktopShellEvent(type));
  }
}

