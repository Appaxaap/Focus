import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task_models.dart';
import '../services/hive_service.dart';

class DesktopSyncStatus {
  final bool isHosting;
  final String deviceId;
  final String deviceName;
  final String? localAddress;
  final int? port;
  final String? pairingCode;
  final String? lastError;
  final DateTime? lastStartedAt;
  final DateTime? lastClientSyncedAt;
  final String? lastClientAddress;
  final String? lastClientDevice;

  const DesktopSyncStatus({
    this.isHosting = false,
    this.deviceId = '',
    this.deviceName = '',
    this.localAddress,
    this.port,
    this.pairingCode,
    this.lastError,
    this.lastStartedAt,
    this.lastClientSyncedAt,
    this.lastClientAddress,
    this.lastClientDevice,
  });

  DesktopSyncStatus copyWith({
    bool? isHosting,
    String? deviceId,
    String? deviceName,
    String? localAddress,
    int? port,
    String? pairingCode,
    String? lastError,
    DateTime? lastStartedAt,
    DateTime? lastClientSyncedAt,
    String? lastClientAddress,
    String? lastClientDevice,
    bool clearError = false,
    bool clearClient = false,
  }) {
    return DesktopSyncStatus(
      isHosting: isHosting ?? this.isHosting,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      localAddress: localAddress ?? this.localAddress,
      port: port ?? this.port,
      pairingCode: pairingCode ?? this.pairingCode,
      lastError: clearError ? null : (lastError ?? this.lastError),
      lastStartedAt: lastStartedAt ?? this.lastStartedAt,
      lastClientSyncedAt: clearClient
          ? null
          : (lastClientSyncedAt ?? this.lastClientSyncedAt),
      lastClientAddress:
          clearClient ? null : (lastClientAddress ?? this.lastClientAddress),
      lastClientDevice:
          clearClient ? null : (lastClientDevice ?? this.lastClientDevice),
    );
  }
}

class DesktopOfflineSyncService {
  DesktopOfflineSyncService._();
  static final DesktopOfflineSyncService instance = DesktopOfflineSyncService._();

  static const String _deviceIdKey = 'offline_sync_device_id';
  static const int _protocolVersion = 1;

  final ValueNotifier<DesktopSyncStatus> statusNotifier =
       ValueNotifier<DesktopSyncStatus>(DesktopSyncStatus());
  final HiveService _hiveService = HiveService();

  ServerSocket? _serverSocket;
  StreamSubscription<Socket>? _serverSub;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await _hiveService.initialize();
      final prefs = await SharedPreferences.getInstance();
      var deviceId = prefs.getString(_deviceIdKey);
      if (deviceId == null || deviceId.isEmpty) {
        deviceId = _randomDeviceId();
        await prefs.setString(_deviceIdKey, deviceId);
      }
      statusNotifier.value = statusNotifier.value.copyWith(
        deviceId: deviceId,
        deviceName: Platform.localHostname,
        clearError: true,
      );
      _initialized = true;
    } catch (e) {
      statusNotifier.value = statusNotifier.value.copyWith(
        lastError: 'Failed to initialize offline sync: $e',
      );
    }
  }

  Future<void> startHosting() async {
    await initialize();
    if (_serverSocket != null) return;

    try {
      final socket = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        0,
        shared: true,
      );
      _serverSocket = socket;
      _serverSub = socket.listen(
        _handleClient,
        onError: (Object e) {
          statusNotifier.value = statusNotifier.value.copyWith(
            lastError: 'Offline sync host error: $e',
          );
        },
      );

      final localAddress = await _findLocalIpv4Address();
      final pairingCode = _buildPairingCode(
        statusNotifier.value.deviceId,
        socket.port,
      );

      statusNotifier.value = statusNotifier.value.copyWith(
        isHosting: true,
        localAddress: localAddress,
        port: socket.port,
        pairingCode: pairingCode,
        lastStartedAt: DateTime.now(),
        clearError: true,
      );
    } catch (e) {
      statusNotifier.value = statusNotifier.value.copyWith(
        lastError: 'Could not start offline sync host: $e',
      );
    }
  }

  Future<void> stopHosting() async {
    await _serverSub?.cancel();
    _serverSub = null;
    await _serverSocket?.close();
    _serverSocket = null;

    statusNotifier.value = statusNotifier.value.copyWith(
      isHosting: false,
      port: null,
      localAddress: null,
      pairingCode: null,
      clearError: true,
      clearClient: true,
    );
  }

  Future<void> dispose() async {
    await stopHosting();
  }

  Future<void> _handleClient(Socket socket) async {
    try {
      final taskCount = await _hiveService.getTaskCount();
      final hello = <String, dynamic>{
        'type': 'hello',
        'protocolVersion': _protocolVersion,
        'deviceId': statusNotifier.value.deviceId,
        'deviceName': statusNotifier.value.deviceName,
        'taskCount': taskCount,
        'pairingCode': statusNotifier.value.pairingCode,
      };
      socket.write('${jsonEncode(hello)}\n');
      await socket.flush();

      final line = await utf8
          .decoder
          .bind(socket)
          .transform(const LineSplitter())
          .first
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => '',
          );

      if (line.isEmpty) return;
      final request = jsonDecode(line);
      if (request is! Map<String, dynamic>) return;
      if (request['type'] != 'request_snapshot') return;
      final requestedCode = (request['pairingCode'] ?? '').toString();
      final expectedCode = statusNotifier.value.pairingCode ?? '';
      final clientDevice = (request['clientDevice'] ?? '').toString();
      if (expectedCode.isNotEmpty && requestedCode != expectedCode) {
        socket.write(
          '${jsonEncode(<String, dynamic>{'type': 'error', 'message': 'Invalid pairing code'})}\n',
        );
        await socket.flush();
        return;
      }

      await _mergeIncomingClientTasks(request['clientTasks']);

      final tasks = await _hiveService.getAllTasks();
      final payload = <String, dynamic>{
        'type': 'snapshot',
        'protocolVersion': _protocolVersion,
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'generatedAt': DateTime.now().toIso8601String(),
      };
      socket.write('${jsonEncode(payload)}\n');
      await socket.flush();
      statusNotifier.value = statusNotifier.value.copyWith(
        lastClientSyncedAt: DateTime.now(),
        lastClientAddress: socket.remoteAddress.address,
        lastClientDevice: clientDevice.isEmpty ? 'Unknown device' : clientDevice,
        clearError: true,
      );
    } catch (e) {
      statusNotifier.value = statusNotifier.value.copyWith(
        lastError: 'Client sync handshake failed: $e',
      );
    } finally {
      await socket.close();
      socket.destroy();
    }
  }

  Future<void> _mergeIncomingClientTasks(dynamic rawClientTasks) async {
    if (rawClientTasks is! List || rawClientTasks.isEmpty) return;

    final localTasks = await _hiveService.getAllTasks();
    final localById = <String, DateTime>{
      for (final t in localTasks) t.id: t.updatedAt,
    };
    final toUpsert = <Task>[];

    for (final entry in rawClientTasks) {
      if (entry is! Map) continue;
      Map<String, dynamic> json;
      try {
        json = Map<String, dynamic>.from(entry);
      } catch (_) {
        continue;
      }
      final id = (json['id'] ?? '').toString();
      final updatedAtRaw = (json['updatedAt'] ?? '').toString();
      if (id.isEmpty || updatedAtRaw.isEmpty) continue;

      DateTime? remoteUpdatedAt;
      try {
        remoteUpdatedAt = DateTime.parse(updatedAtRaw);
      } catch (_) {
        continue;
      }
      final localUpdatedAt = localById[id];
      if (localUpdatedAt == null || remoteUpdatedAt.isAfter(localUpdatedAt)) {
        try {
          toUpsert.add(Task.fromJson(json));
        } catch (_) {
          continue;
        }
      }
    }

    if (toUpsert.isEmpty) return;
    await _hiveService.upsertTasks(toUpsert);
  }

  Future<String?> _findLocalIpv4Address() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4) {
            return address.address;
          }
        }
      }
    } catch (_) {
      // Best effort only.
    }
    return null;
  }

  String _randomDeviceId() {
    final r = Random.secure();
    final bytes = List<int>.generate(12, (_) => r.nextInt(256));
    final b = StringBuffer();
    for (final v in bytes) {
      b.write(v.toRadixString(16).padLeft(2, '0'));
    }
    return b.toString();
  }

  String _buildPairingCode(String deviceId, int port) {
    final seed = '$deviceId:$port';
    var hash = 2166136261;
    for (final codeUnit in seed.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
    final code = hash.abs() % 1000000;
    return code.toString().padLeft(6, '0');
  }
}
