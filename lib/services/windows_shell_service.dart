import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'desktop_event_bus.dart';

class WindowsShellService with TrayListener, WindowListener {
  WindowsShellService._();
  static final WindowsShellService instance = WindowsShellService._();

  bool _initialized = false;
  final HotKey _openPaletteHotKey = HotKey(
    key: PhysicalKeyboardKey.keyK,
    modifiers: [HotKeyModifier.control],
    scope: HotKeyScope.system,
  );

  Future<void> initialize() async {
    if (_initialized || kIsWeb || !Platform.isWindows) return;

    try {
      trayManager.addListener(this);
      windowManager.addListener(this);

      try {
        await trayManager.setIcon('assets/images/tray_icon.ico');
      } catch (_) {
        // Fallback for systems that fail to render ICO tray assets.
        await trayManager.setIcon('assets/images/512x512_logo.png');
      }
      await trayManager.setToolTip('Focus');
      await trayManager.setContextMenu(
        Menu(
          items: [
            MenuItem(key: 'show', label: 'Show Focus'),
            MenuItem.separator(),
            MenuItem(key: 'quick_add', label: 'Quick Add Task'),
            MenuItem(key: 'command_palette', label: 'Open Command Palette'),
            MenuItem.separator(),
            MenuItem(key: 'quit', label: 'Quit'),
          ],
        ),
      );

      await hotKeyManager.register(
        _openPaletteHotKey,
        keyDownHandler: (_) async {
          await windowManager.show();
          await windowManager.focus();
          DesktopEventBus.instance.emit(
            DesktopShellEventType.openCommandPalette,
          );
        },
      );
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('WindowsShellService initialize failed: $e');
        debugPrint('$s');
      }
    }

    _initialized = true;
  }

  Future<void> dispose() async {
    if (!_initialized) return;
    await hotKeyManager.unregister(_openPaletteHotKey);
    await trayManager.destroy();
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    _initialized = false;
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        DesktopEventBus.instance.emit(DesktopShellEventType.showWindow);
        break;
      case 'quick_add':
        DesktopEventBus.instance.emit(DesktopShellEventType.quickAddTask);
        break;
      case 'command_palette':
        DesktopEventBus.instance.emit(DesktopShellEventType.openCommandPalette);
        break;
      case 'quit':
        windowManager.setPreventClose(false);
        windowManager.close();
        break;
    }
  }

  @override
  void onTrayIconMouseDown() {
    DesktopEventBus.instance.emit(DesktopShellEventType.showWindow);
  }

  @override
  Future<void> onWindowClose() async {
    if (!Platform.isWindows) return;
    final isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      await windowManager.hide();
    }
  }

  @override
  void onWindowMinimize() {
    if (Platform.isWindows) {
      windowManager.hide();
    }
  }
}
