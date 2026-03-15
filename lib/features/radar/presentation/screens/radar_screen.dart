import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/threat.dart';
import '../../../../shared/widgets/widgets.dart';
import '../providers/radar_provider.dart';
import '../widgets/threat_card.dart';

class RadarScreen extends ConsumerStatefulWidget {
  const RadarScreen({super.key});

  @override
  ConsumerState<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends ConsumerState<RadarScreen> {
  bool _showAllThreats = false;
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final threatsAsync = ref.watch(threatsProvider);
    final threatLevelAsync = ref.watch(threatLevelProvider);
    final userLocationAsync = ref.watch(userLocationProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(threatsProvider);
                  ref.invalidate(threatLevelProvider);
                  ref.invalidate(userLocationProvider);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildMapSection(
                        threatLevelAsync,
                        threatsAsync,
                        userLocationAsync,
                      ),
                      _buildThreatsSection(ref, threatsAsync),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Threat Radar',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.slate900,
              letterSpacing: -0.5,
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  final threatsValue = ref.read(threatsProvider).valueOrNull;
                  if (threatsValue != null) {
                    showSearch(
                      context: context,
                      delegate: _ThreatSearchDelegate(threatsValue),
                    );
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: const Icon(Icons.search_rounded, color: AppColors.slate600, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection(
    AsyncValue<String> threatLevelAsync,
    AsyncValue<List<Threat>> threatsAsync,
    AsyncValue<LatLng> userLocationAsync,
  ) {
    return Container(
      height: 300,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          userLocationAsync.when(
            data: (userLocation) {
              final markers = <Marker>[];
              
              // User location marker
              markers.add(
                Marker(
                  point: userLocation,
                  width: 48,
                  height: 48,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_rounded, color: Colors.white, size: 12),
                      ),
                    ),
                  ),
                ),
              );

              // Threat markers
              final threats = threatsAsync.valueOrNull ?? [];
              for (final threat in threats) {
                if (threat.latitude != 0.0 && threat.longitude != 0.0) {
                  markers.add(
                    Marker(
                      point: LatLng(threat.latitude, threat.longitude),
                      width: 36,
                      height: 36,
                      child: GestureDetector(
                        onTap: () => _showThreatDetails(context, threat),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: threat.color, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: threat.color.withOpacity(0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(threat.icon, color: threat.color, size: 16),
                        ),
                      ),
                    ),
                  );
                }
              }

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: userLocation,
                  initialZoom: 5.0,
                  minZoom: 3.0,
                  maxZoom: 18.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.argus.eye',
                  ),
                  MarkerLayer(markers: markers),
                ],
              );
            },
            loading: () => Container(
              color: AppColors.slate100,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 12),
                    Text(
                      'Detecting your location...',
                      style: TextStyle(fontSize: 13, color: AppColors.slate500),
                    ),
                  ],
                ),
              ),
            ),
            error: (_, __) => Container(
              color: AppColors.slate100,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: const LatLng(20.5937, 78.9629), // India center
                  initialZoom: 4.5,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.argus.eye',
                  ),
                  MarkerLayer(
                    markers: (threatsAsync.valueOrNull ?? [])
                        .where((t) => t.latitude != 0.0)
                        .map((threat) => Marker(
                              point: LatLng(threat.latitude, threat.longitude),
                              width: 32,
                              height: 32,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: threat.color, width: 2),
                                ),
                                child: Icon(threat.icon, color: threat.color, size: 14),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          // Location overlay card
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shield_rounded, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LIVE THREAT MAP',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: 1,
                          ),
                        ),
                        threatLevelAsync.when(
                          data: (level) => Text(
                            level,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                          loading: () => const LoadingShimmer(height: 12, width: 100, borderRadius: 4),
                          error: (_, __) => const Text(
                            'Unknown threat level',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      final loc = ref.read(userLocationProvider).valueOrNull;
                      if (loc != null) {
                        _mapController.move(loc, 10.0);
                      }
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.slate100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreatsSection(WidgetRef ref, AsyncValue threatsAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Trending Threats',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _showAllThreats = !_showAllThreats),
                child: Text(
                  _showAllThreats ? 'Show Less' : 'View All',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          threatsAsync.when(
            data: (threats) {
              final displayed = _showAllThreats ? threats : threats.take(3).toList();
              return Column(
                children: displayed.map((threat) => ThreatCard(
                  threat: threat,
                  onTap: () => _showThreatDetails(context, threat),
                )).toList(),
              );
            },
            loading: () => const ListShimmer(itemCount: 3),
            error: (error, _) => ErrorStateWidget(
              title: 'Failed to load threats',
              message: 'Pull down to refresh',
              onRetry: () => ref.invalidate(threatsProvider),
            ),
          ),
        ],
      ),
    );
  }

  void _showThreatDetails(BuildContext context, Threat threat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.slate200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: threat.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(threat.icon, color: threat.color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        threat.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.slate400),
                          const SizedBox(width: 4),
                          Text(
                            threat.location,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.slate400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getSeverityColor(threat.severity).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${threat.severity.name.toUpperCase()} SEVERITY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getSeverityColor(threat.severity),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              threat.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.slate600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${threat.title} marked as reviewed'),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Mark as Reviewed'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(ThreatSeverity severity) {
    switch (severity) {
      case ThreatSeverity.high:
        return AppColors.slate900;
      case ThreatSeverity.medium:
        return AppColors.slate600;
      case ThreatSeverity.low:
        return AppColors.slate400;
    }
  }
}

class _ThreatSearchDelegate extends SearchDelegate<Threat?> {
  final List<Threat> threats;

  _ThreatSearchDelegate(this.threats);

  @override
  String get searchFieldLabel => 'Search threats...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.slate900,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: AppColors.slate400),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = threats.where((threat) =>
      threat.title.toLowerCase().contains(query.toLowerCase()) ||
      threat.description.toLowerCase().contains(query.toLowerCase()) ||
      threat.type.name.toLowerCase().contains(query.toLowerCase())
    ).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: AppColors.slate300),
            const SizedBox(height: 16),
            Text(
              'No threats found for "$query"',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.slate400,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final threat = results[index];
        return ThreatCard(
          threat: threat,
          onTap: () => close(context, threat),
        );
      },
    );
  }
}
