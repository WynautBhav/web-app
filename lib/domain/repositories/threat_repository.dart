import '../entities/entities.dart';

abstract class ThreatRepository {
  Future<List<Threat>> getTrendingThreats();
  Future<Threat> getThreatById(String id);
  Future<String> getLocationThreatLevel();
}
