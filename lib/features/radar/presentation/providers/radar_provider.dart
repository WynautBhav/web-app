import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../../domain/entities/entities.dart';
import '../../../../core/di/repository_providers.dart';

final threatsProvider = FutureProvider<List<Threat>>((ref) async {
  final repository = ref.watch(threatRepositoryProvider);
  return repository.getTrendingThreats();
});

final threatLevelProvider = FutureProvider<String>((ref) async {
  final repository = ref.watch(threatRepositoryProvider);
  return repository.getLocationThreatLevel();
});

final userLocationProvider = FutureProvider<LatLng>((ref) async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Fallback to India center if services disabled
      return const LatLng(20.5937, 78.9629);
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const LatLng(20.5937, 78.9629);
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return const LatLng(20.5937, 78.9629);
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      ),
    );
    return LatLng(position.latitude, position.longitude);
  } catch (e) {
    // Fallback to India center
    return const LatLng(20.5937, 78.9629);
  }
});

final threatsRefreshProvider = FutureProvider.family<List<Threat>, void>((ref, _) async {
  final repository = ref.watch(threatRepositoryProvider);
  ref.invalidate(threatsProvider);
  ref.invalidate(threatLevelProvider);
  return repository.getTrendingThreats();
});
