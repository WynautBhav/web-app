import 'dart:convert';
import 'dart:math';
import 'package:appwrite/appwrite.dart';
import 'package:crypto/crypto.dart';
import '../core/config/app_config.dart';

class ThreatService {
  static late Client _client;
  static late Databases _databases;
  static late Realtime _realtime;
  static bool _initialized = false;

  static void init() {
    if (_initialized) return;
    _client = Client()
        .setEndpoint(AppConfig.appwriteEndpoint)
        .setProject(AppConfig.appwriteProjectId);
    _databases = Databases(_client);
    _realtime = Realtime(_client);
    _initialized = true;
  }

  // Check trust badge for a UPI ID
  static Future<Map<String, dynamic>> getTrustBadge(
      String entityId) async {
    init();
    try {
      final result = await _databases.listDocuments(
        databaseId: AppConfig.appwriteDbId,
        collectionId: AppConfig.threatCollection,
        queries: [Query.equal('entityId', entityId)],
      );
      if (result.documents.isEmpty) {
        return {'state': 'SAFE', 'score': 0, 'reports': 0};
      }
      final doc = result.documents.first.data;
      return {
        'state': doc['status'] ?? 'SAFE',
        'score': doc['score'] ?? 0,
        'reports': doc['reports'] ?? 0,
      };
    } catch (e) {
      return {'state': 'SAFE', 'score': 0, 'reports': 0};
    }
  }

  // Report a scam UPI ID
  static Future<bool> reportScam({
    required String entityId,
    required String entityType,
    required String scamType,
    required String userId,
  }) async {
    init();
    try {
      final userHash = sha256
          .convert(utf8.encode(userId))
          .toString()
          .substring(0, 16);

      // Check if entity already exists
      final existing = await _databases.listDocuments(
        databaseId: AppConfig.appwriteDbId,
        collectionId: AppConfig.threatCollection,
        queries: [Query.equal('entityId', entityId)],
      );

      if (existing.documents.isNotEmpty) {
        // Increment report count
        final doc = existing.documents.first;
        await _databases.updateDocument(
          databaseId: AppConfig.appwriteDbId,
          collectionId: AppConfig.threatCollection,
          documentId: doc.$id,
          data: {
            'reports': (doc.data['reports'] ?? 0) + 1,
            'score': ((doc.data['score'] ?? 0) + 8).clamp(0, 100),
          },
        );
      } else {
        // Create new threat document
        await _databases.createDocument(
          databaseId: AppConfig.appwriteDbId,
          collectionId: AppConfig.threatCollection,
          documentId: ID.unique(),
          data: {
            'entityId': entityId,
            'entityType': entityType,
            'source': 'USER',
            'reports': 1,
            'score': 8,
            'status': 'CORROBORATED',
            'scamType': scamType,
            'reportedBy': userHash,
            'time': DateTime.now().toIso8601String(),
          },
        );
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // Subscribe to real-time updates for a specific entity
  static RealtimeSubscription subscribeToEntity(
    String entityId,
    Function(Map<String, dynamic>) onUpdate,
  ) {
    init();
    return _realtime.subscribe([
      'databases.${AppConfig.appwriteDbId}'
      '.collections.${AppConfig.threatCollection}.documents',
    ])
      ..stream.listen((event) {
        final payload = event.payload;
        if (payload['entityId'] == entityId) {
          onUpdate(payload);
        }
      });
  }
}
