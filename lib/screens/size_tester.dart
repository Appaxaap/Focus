import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;
import 'package:uuid/uuid.dart'; // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    // Set minimum window size to 800x800 as requested
    await windowManager.setMinimumSize(const Size(800, 800));

    // Set initial window size to 1200x800
    await windowManager.setSize(const Size(1200, 800));

    // Center the window
    await windowManager.center();
  }

  // Initialize notifications after a delay to ensure window is ready
  Future.delayed(const Duration(seconds: 1), () {
    initNotifications();
  });

  runApp(const MyApp());
}

// Initialize notifications with proper platform configuration
Future<void> initNotifications() async {
  try {
    final FlutterLocalNotificationsPlugin notificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // Initialization settings for Android
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Generate a unique GUID for the app
    final String appGuid = const Uuid().v4();

    // Initialization settings for Windows - CORRECTED with proper values
    final WindowsInitializationSettings windowsSettings =
        WindowsInitializationSettings(
          appName: 'Window Size Tester',
          appUserModelId: 'WindowSizeTester.App.1.0.0',
          guid: appGuid, // Use the generated GUID
        );

    // Initialization settings for iOS
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: androidSettings,
          windows: windowsSettings,
          iOS: iosSettings,
        );

    await notificationsPlugin.initialize(initializationSettings);
    print('Notifications initialized successfully');
  } catch (e) {
    print('Error initializing notifications: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Window Size Tester',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SizeTester(),
    );
  }
}

class SizeTester extends StatefulWidget {
  const SizeTester({super.key});

  @override
  State<SizeTester> createState() => _SizeTesterState();
}

class _SizeTesterState extends State<SizeTester> with WindowListener {
  Size currentSize = const Size(1200, 800);
  bool _isInitialized = false;
  final bool _windowManagerError = false;

  @override
  void initState() {
    super.initState();
    // Delay window initialization to avoid race conditions
    Future.delayed(const Duration(milliseconds: 500), () {
      _initializeWindow();
    });
  }

  Future<void> _initializeWindow() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      try {
        windowManager.addListener(this);

        // Get initial size with error handling
        final size = await windowManager.getSize();
        setState(() {
          currentSize = size;
          _isInitialized = true;
        });
      } catch (e) {
        print('Error initializing window manager: $e');
        // Use default size instead of showing error
        setState(() {
          _isInitialized = true;
        });
      }
    } else {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void onWindowResize() {
    _updateCurrentSize();
  }

  Future<void> _updateCurrentSize() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      try {
        final size = await windowManager.getSize();
        setState(() {
          currentSize = size;
        });
      } catch (e) {
        print('Error updating window size: $e');
      }
    }
  }

  Future<void> _resetToInitialSize() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      try {
        await windowManager.setSize(const Size(1200, 800));
        await windowManager.center();
        _updateCurrentSize();
      } catch (e) {
        print('Error resetting window size: $e');
      }
    }
  }

  @override
  void dispose() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40),
                          const Text(
                            'Window Size Tester',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Resize the window to see dimensions update in real-time',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                          if (_windowManagerError) ...[
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange),
                              ),
                              child: Text(
                                'Window management features are currently unavailable. '
                                'The app is running with default size values.',
                                style: TextStyle(color: Colors.orange[800]),
                              ),
                            ),
                          ],
                          const SizedBox(height: 40),
                          Center(
                            child: Container(
                              width: 400,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _windowManagerError
                                        ? Icons.warning
                                        : Icons.aspect_ratio,
                                    size: 60,
                                    color: _windowManagerError
                                        ? Colors.orange
                                        : Colors.blue,
                                  ),
                                  const SizedBox(height: 30),
                                  Text(
                                    _windowManagerError
                                        ? 'Window Size'
                                        : 'Current Window Size',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF4A5568),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _SizeBox(
                                        value: currentSize.width.toInt(),
                                        label: 'Width',
                                        color: _windowManagerError
                                            ? Colors.orange
                                            : const Color(0xFF4299E1),
                                      ),
                                      const SizedBox(width: 30),
                                      _SizeBox(
                                        value: currentSize.height.toInt(),
                                        label: 'Height',
                                        color: _windowManagerError
                                            ? Colors.orange
                                            : const Color(0xFF48BB78),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 30),
                                  Text(
                                    '${currentSize.width.toStringAsFixed(1)} × ${currentSize.height.toStringAsFixed(1)} pixels',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Color(0xFF718096),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          Align(
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                const Text(
                                  'Try resizing this window',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF718096),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Icon(
                                  Icons.swap_vert,
                                  color: Colors.grey[500],
                                  size: 30,
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: _windowManagerError
                                      ? null
                                      : _resetToInitialSize,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _windowManagerError
                                        ? Colors.grey
                                        : Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Reset to 1200 × 800'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Text(
                              'Minimum size: 800 × 800 pixels',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _SizeBox extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _SizeBox({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
