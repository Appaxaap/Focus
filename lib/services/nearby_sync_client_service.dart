import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/task_models.dart';
import 'hive_service.dart';

class NearbySyncResult {
  final int receivedCount;
  final int upsertedCount;
  final int ignoredCount;

  const NearbySyncResult({
    required this.receivedCount,
    required this.upsertedCount,
    required this.ignoredCount,
  });
}

class NearbySyncClientService {
  NearbySyncClientService._();
  static final NearbySyncClientService instance = NearbySyncClientService._();

  Future<NearbySyncResult> pullFromDesktop({
    required String endpoint,
    required String pairingCode,
    required HiveService hiveService,
  }) async {
    if (kDebugMode) debugPrint('[NearbySync] parse endpoint: $endpoint');
    final parsed = _parseEndpoint(endpoint);
    final host = parsed.$1;
    final port = parsed.$2;
    if (kDebugMode) debugPrint('[NearbySync] connecting to $host:$port');

    final socket = await Socket.connect(
      host,
      port,
      timeout: const Duration(seconds: 8),
    );
    if (kDebugMode) debugPrint('[NearbySync] socket connected');

    try {
      final lineStream = utf8.decoder.bind(socket).transform(const LineSplitter());
      final iterator = StreamIterator<String>(lineStream);

      // Read hello handshake first.
      final hasHello = await iterator.moveNext().timeout(
        const Duration(seconds: 8),
        onTimeout: () => false,
      );
      if (!hasHello) {
        throw Exception('Desktop sync host did not respond');
      }
      if (kDebugMode) debugPrint('[NearbySync] hello received');
      final localTasks = await hiveService.getAllTasks();

      final request = <String, dynamic>{
        'type': 'request_snapshot',
        'pairingCode': pairingCode.trim(),
        'clientDevice': 'Android ${Platform.localHostname}',
        'clientTasks': localTasks.map((t) => t.toJson()).toList(),
      };
      socket.write('${jsonEncode(request)}\n');
      await socket.flush();
      if (kDebugMode) debugPrint('[NearbySync] snapshot request sent');

      final hasSnapshot = await iterator.moveNext().timeout(
        const Duration(seconds: 10),
        onTimeout: () => false,
      );
      if (!hasSnapshot) {
        throw Exception('No snapshot received from desktop');
      }
      final snapshotLine = iterator.current;
      if (kDebugMode) {
        debugPrint(
          '[NearbySync] snapshot line received (${snapshotLine.length} chars)',
        );
      }
      final localUpdatedAt = <String, String>{
        for (final t in localTasks) t.id: t.updatedAt.toIso8601String(),
      };

      final mergePlan = await compute<Map<String, dynamic>, Map<String, dynamic>>(
        _buildMergePlan,
        <String, dynamic>{
          'snapshotLine': snapshotLine,
          'localUpdatedAt': localUpdatedAt,
        },
      );
      if (kDebugMode) debugPrint('[NearbySync] merge plan built');

      final upsertJson = (mergePlan['upsert'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
      final remoteTasks = upsertJson.map(Task.fromJson).toList();
      final upserted = (mergePlan['upserted'] as int?) ?? remoteTasks.length;
      final ignored = (mergePlan['ignored'] as int?) ?? 0;
      final received = (mergePlan['received'] as int?) ?? (upserted + ignored);

      await hiveService.upsertTasks(remoteTasks);
      if (kDebugMode) {
        debugPrint(
          '[NearbySync] hive upsert complete (${remoteTasks.length} tasks)',
        );
      }

      return NearbySyncResult(
        receivedCount: received,
        upsertedCount: upserted,
        ignoredCount: ignored,
      );
    } finally {
      await socket.close();
      socket.destroy();
      if (kDebugMode) debugPrint('[NearbySync] socket closed');
    }
  }

  (String, int) _parseEndpoint(String endpoint) {
    final trimmed = endpoint.trim();
    final parts = trimmed.split(':');
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
      throw Exception('Endpoint must be host:port');
    }
    final host = parts[0].trim();
    final port = int.tryParse(parts[1].trim());
    if (port == null || port <= 0 || port > 65535) {
      throw Exception('Endpoint port is invalid');
    }
    return (host, port);
  }
}

Map<String, dynamic> _buildMergePlan(Map<String, dynamic> input) {
  final snapshotLine = (input['snapshotLine'] ?? '').toString();
  final localUpdatedAtRaw =
      (input['localUpdatedAt'] as Map?)?.cast<String, String>() ??
          <String, String>{};

  final payload = jsonDecode(snapshotLine);
  if (payload is! Map<String, dynamic>) {
    throw Exception('Invalid sync payload');
  }
  if (payload['type'] == 'error') {
    throw Exception((payload['message'] ?? 'Sync failed').toString());
  }
  if (payload['type'] != 'snapshot') {
    throw Exception('Unexpected sync response');
  }

  final dynamic tasksRaw = payload['tasks'];
  if (tasksRaw is! List) {
    throw Exception('Snapshot tasks are invalid');
  }

  final upsert = <Map<String, dynamic>>[];
  var ignored = 0;
  var received = 0;

  for (final entry in tasksRaw) {
    if (entry is! Map) continue;
    Map<String, dynamic> taskJson;
    try {
      taskJson = Map<String, dynamic>.from(entry);
    } catch (_) {
      continue;
    }

    final id = (taskJson['id'] ?? '').toString();
    final remoteUpdatedAtRaw = (taskJson['updatedAt'] ?? '').toString();
    if (id.isEmpty || remoteUpdatedAtRaw.isEmpty) continue;

    received++;
    final localUpdatedAtRawValue = localUpdatedAtRaw[id];
    if (localUpdatedAtRawValue == null) {
      upsert.add(taskJson);
      continue;
    }

    DateTime? remoteUpdatedAt;
    DateTime? localUpdatedAt;
    try {
      remoteUpdatedAt = DateTime.parse(remoteUpdatedAtRaw);
      localUpdatedAt = DateTime.parse(localUpdatedAtRawValue);
    } catch (_) {
      upsert.add(taskJson);
      continue;
    }

    if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
      upsert.add(taskJson);
    } else {
      ignored++;
    }
  }

  return <String, dynamic>{
    'upsert': upsert,
    'upserted': upsert.length,
    'ignored': ignored,
    'received': received,
  };
}
