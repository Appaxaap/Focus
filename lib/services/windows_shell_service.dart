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
  bool _trayReady = false;
  bool _hotkeyReady = false;
  HotKey? _registeredHotKey;
  final HotKey _openPaletteHotKey = HotKey(
    key: PhysicalKeyboardKey.keyK,
    modifiers: [HotKeyModifier.control],
    scope: HotKeyScope.system,
  );
  bool get _isSupportedDesktop => Platform.isWindows || Platform.isLinux;

  Future<void> initialize() async {
    if (_initialized || kIsWeb || !_isSupportedDesktop) return;

    windowManager.addListener(this);

    try {
      trayManager.addListener(this);
      try {
        if (Platform.isWindows) {
          await trayManager.setIcon('assets/images/tray_icon.ico');
        } else {
          await trayManager.setIcon('assets/images/512x512_logo.png');
        }
      } catch (_) {
        // Fallback for systems that fail to render the preferred tray asset.
        await trayManager.setIcon('assets/images/512x512_logo.png');
      }
      try {
        await trayManager.setToolTip('Focus');
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Tray tooltip unavailable on this platform: $e');
        }
      }
      try {
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
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Tray context menu unavailable on this platform: $e');
        }
      }
      _trayReady = true;
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('Desktop tray integration unavailable: $e');
        debugPrint('$s');
      }
      trayManager.removeListener(this);
      _trayReady = false;
    }

    if (Platform.isWindows) {
      try {
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
        _registeredHotKey = _openPaletteHotKey;
        _hotkeyReady = true;
      } catch (e, s) {
        if (kDebugMode) {
          debugPrint('Desktop global hotkey unavailable: $e');
          debugPrint('$s');
        }
      }
    }

    _initialized = true;
  }

  Future<void> dispose() async {
    if (!_initialized) return;
    if (_hotkeyReady && _registeredHotKey != null) {
      await hotKeyManager.unregister(_registeredHotKey!);
    }
    if (_trayReady) {
      await trayManager.destroy();
      trayManager.removeListener(this);
    }
    windowManager.removeListener(this);
    _registeredHotKey = null;
    _trayReady = false;
    _hotkeyReady = false;
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
    if (!_isSupportedDesktop) return;
    final isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      await windowManager.hide();
    }
  }

  @override
  void onWindowMinimize() {
    if (_isSupportedDesktop) {
      windowManager.hide();
    }
  }
}
