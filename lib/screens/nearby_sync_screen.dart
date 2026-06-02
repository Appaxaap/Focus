import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../providers/task_provider.dart';
import '../services/nearby_sync_client_service.dart';

class NearbySyncScreen extends ConsumerStatefulWidget {
  const NearbySyncScreen({super.key});

  @override
  ConsumerState<NearbySyncScreen> createState() => _NearbySyncScreenState();
}

class _NearbySyncScreenState extends ConsumerState<NearbySyncScreen> {
  static const String _prefEndpoint = 'nearby_sync_endpoint';
  static const String _prefPin = 'nearby_sync_pin';
  static const String _prefAuto = 'nearby_sync_auto_enabled';
  static const String _prefLastSync = 'nearby_sync_last_sync_ms';

  final TextEditingController _endpointController = TextEditingController();
  final TextEditingController _pairingController = TextEditingController();

  bool _syncing = false;
  bool _autoSyncEnabled = false;
  String? _message;
  bool _error = false;
  DateTime? _lastSyncedAt;
  Timer? _autoSyncTimer;
  Timer? _relativeTimeTicker;

  @override
  void initState() {
    super.initState();
    _relativeTimeTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _lastSyncedAt == null) return;
      setState(() {});
    });
    _loadSavedSyncConfig();
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    _relativeTimeTicker?.cancel();
    _endpointController.dispose();
    _pairingController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedSyncConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _endpointController.text = prefs.getString(_prefEndpoint) ?? '';
    _pairingController.text = prefs.getString(_prefPin) ?? '';
    final lastMs = prefs.getInt(_prefLastSync);
    if (!mounted) return;
    setState(() {
      _autoSyncEnabled = prefs.getBool(_prefAuto) ?? false;
      _lastSyncedAt = lastMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastMs);
    });
    _configureAutoSyncTimer();
  }

  Future<void> _persistSyncConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefEndpoint, _endpointController.text.trim());
    await prefs.setString(_prefPin, _pairingController.text.trim());
    await prefs.setBool(_prefAuto, _autoSyncEnabled);
    if (_lastSyncedAt != null) {
      await prefs.setInt(_prefLastSync, _lastSyncedAt!.millisecondsSinceEpoch);
    }
  }

  void _configureAutoSyncTimer() {
    _autoSyncTimer?.cancel();
    if (!_autoSyncEnabled) return;
    if (_endpointController.text.trim().isEmpty ||
        _pairingController.text.trim().isEmpty) {
      return;
    }
    // Run one sync immediately when auto-sync is enabled/restored.
    unawaited(_runSync(isAuto: true));
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!mounted || _syncing) return;
      await _runSync(isAuto: true);
    });
  }

  Future<void> _runSync({bool isAuto = false}) async {
    if (_syncing) return;
    final endpoint = _endpointController.text.trim();
    final pair = _pairingController.text.trim();

    if (endpoint.isEmpty || pair.isEmpty) {
      if (!isAuto) {
        setState(() {
          _error = true;
          _message = 'Enter endpoint and pairing code.';
        });
      }
      return;
    }

    setState(() {
      _syncing = true;
      if (!isAuto) {
        _error = false;
        _message = null;
      }
    });

    try {
      final hiveService = ref.read(hiveServiceProvider);
      final result = await NearbySyncClientService.instance
          .pullFromDesktop(
            endpoint: endpoint,
            pairingCode: pair,
            hiveService: hiveService,
          )
          .timeout(const Duration(seconds: 18));

      await ref.read(taskProvider.notifier).refresh();
      if (!mounted) return;
      final now = DateTime.now();
      setState(() {
        _lastSyncedAt = now;
        _error = false;
        if (!isAuto) {
          _message = result.upsertedCount == 0
              ? 'Already up to date. ${result.receivedCount} tasks checked.'
              : 'Connected and synced ${result.upsertedCount}/${result.receivedCount} tasks.';
        } else {
          _message = 'Auto-sync connected. ${result.receivedCount} checked.';
        }
      });
      await _persistSyncConfig();
    } on TimeoutException {
      if (!mounted) return;
      if (!isAuto) {
        setState(() {
          _error = true;
          _message = 'Sync timed out. Check Wi-Fi and desktop host.';
        });
      }
    } catch (e, st) {
      debugPrint('[NearbySyncScreen] Sync failed: $e');
      debugPrint('[NearbySyncScreen] Stack: $st');
      if (!mounted) return;
      if (!isAuto) {
        setState(() {
          _error = true;
          _message = 'Sync failed: $e';
        });
      } else {
        setState(() {
          _error = true;
          _message = 'Auto-sync retrying...';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  Future<void> _scanQr() async {
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _NearbySyncQrScannerScreen()),
    );
    if (!mounted || scanned == null || scanned.isEmpty) return;
    final endpoint = _extractEndpointFromQr(scanned);
    if (endpoint == null) {
      setState(() {
        _error = true;
        _message = 'QR invalid. Scan a Focus desktop sync QR.';
      });
      return;
    }
    _endpointController.text = endpoint;
    setState(() {
      _error = false;
      _message = 'Endpoint filled from QR.';
    });
    await _persistSyncConfig();
  }

  String? _extractEndpointFromQr(String raw) {
    final value = raw.trim();
    if (value.contains(':') && !value.startsWith('{')) return value;
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic> &&
          decoded['type'] == 'focus_nearby_sync' &&
          decoded['endpoint'] is String) {
        final endpoint = (decoded['endpoint'] as String).trim();
        return endpoint.isEmpty ? null : endpoint;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Sync')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scan desktop QR or paste endpoint, enter pairing code, then sync.',
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _endpointController,
                      onChanged: (_) {
                        _persistSyncConfig();
                        if (_autoSyncEnabled) _configureAutoSyncTimer();
                      },
                      decoration: const InputDecoration(
                        labelText: 'Desktop endpoint',
                        hintText: '192.168.1.4:53124',
                        prefixIcon: Icon(Icons.computer_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _scanQr,
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                      label: const Text('Scan QR'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pairingController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                onChanged: (_) {
                  _persistSyncConfig();
                  if (_autoSyncEnabled) _configureAutoSyncTimer();
                },
                decoration: const InputDecoration(
                  labelText: 'Pairing code',
                  hintText: '123456',
                  prefixIcon: Icon(Icons.password_rounded),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Switch.adaptive(
                    value: _autoSyncEnabled,
                    onChanged: (value) async {
                      setState(() => _autoSyncEnabled = value);
                      _configureAutoSyncTimer();
                      await _persistSyncConfig();
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _autoSyncEnabled
                          ? 'Auto-sync every 10 seconds (runs immediately when enabled)'
                          : 'Enable auto-sync',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: cs.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ),
                ],
              ),
              if (_lastSyncedAt != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Last synced: ${_formatLastSynced(_lastSyncedAt!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.68),
                  ),
                ),
              ],
              if (_message != null) ...[
                const SizedBox(height: 8),
                Text(
                  _message!,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: _error ? cs.error : Colors.green.shade600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _syncing ? null : () => _runSync(isAuto: false),
                  icon: const Icon(Icons.sync_rounded),
                  label: Text(_syncing ? 'Syncing...' : 'Sync now'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _syncing
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          Navigator.pop(context);
                        },
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLastSynced(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 5) return 'just now';
    if (diff.inMinutes < 1) return '${diff.inSeconds}s ago';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _NearbySyncQrScannerScreen extends StatefulWidget {
  const _NearbySyncQrScannerScreen();

  @override
  State<_NearbySyncQrScannerScreen> createState() =>
      _NearbySyncQrScannerScreenState();
}

class _NearbySyncQrScannerScreenState
    extends State<_NearbySyncQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Desktop QR')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_handled || capture.barcodes.isEmpty) return;
              final code = capture.barcodes.first.rawValue;
              if (code == null || code.isEmpty) return;
              _handled = true;
              Navigator.pop(context, code);
            },
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.58),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Point camera at the desktop Nearby Sync QR',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
