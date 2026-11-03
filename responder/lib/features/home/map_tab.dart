import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/triage.dart';
import '../../../core/ui/app_widgets.dart';

/// Coverage map: the responder's position, live cases and facilities. Pins are
/// deliberately large — this is read on a phone, outdoors, often one-handed.
class MapTab extends StatefulWidget {
  const MapTab({
    super.key,
    required this.position,
    required this.alerts,
    required this.mine,
    required this.facilities,
    required this.onOpenAlert,
    required this.locationKnown,
  });

  final Position? position;
  final List<Map<String, dynamic>> alerts;
  final List<Map<String, dynamic>> mine;
  final List<Map<String, dynamic>> facilities;
  final ValueChanged<Map<String, dynamic>> onOpenAlert;
  final bool locationKnown;

  @override
  State<MapTab> createState() => _MapTabState();
}

enum _Layer { all, mine, facilities }

class _MapTabState extends State<MapTab> {
  final _map = MapController();
  _Layer _layer = _Layer.all;
  Map<String, dynamic>? _selectedFacility;

  LatLng get _center {
    final me = widget.position;
    if (me != null) return LatLng(me.latitude, me.longitude);
    final located = widget.alerts
        .map((a) => _coords(a['location']))
        .whereType<LatLng>()
        .toList();
    if (located.isNotEmpty) return located.first;
    return const LatLng(5.6037, -0.1870); // Accra fallback until GPS answers
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  LatLng? _coords(dynamic location) {
    final coords = (location is Map) ? location['coordinates'] : null;
    if (coords is List && coords.length == 2) {
      return LatLng((coords[1] as num).toDouble(), (coords[0] as num).toDouble());
    }
    return null;
  }

  List<Map<String, dynamic>> get _visibleAlerts => switch (_layer) {
        _Layer.mine => widget.mine,
        _Layer.facilities => const [],
        _Layer.all => widget.alerts,
      };

  @override
  Widget build(BuildContext context) {
    final me = widget.position;
    return Stack(
      children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: 12.4,
            minZoom: 4,
            maxZoom: 18,
            backgroundColor: AppColors.creamDeep,
            onTap: (_, _) => setState(() => _selectedFacility = null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.growwithme.responder',
              tileBuilder: _softTiles,
            ),
            MarkerLayer(
              markers: [
                if (me != null)
                  Marker(
                    point: LatLng(me.latitude, me.longitude),
                    width: 46,
                    height: 46,
                    child: const _MePin(),
                  ),
                if (_layer != _Layer.mine)
                  for (final f in widget.facilities)
                    if (_coords(f['location']) != null)
                      Marker(
                        point: _coords(f['location'])!,
                        width: 42,
                        height: 42,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedFacility = f),
                          child: const _FacilityPin(),
                        ),
                      ),
                if (_layer != _Layer.facilities)
                  for (final a in _visibleAlerts)
                    if (_coords(a['location']) != null)
                      Marker(
                        point: _coords(a['location'])!,
                        width: 50,
                        height: 50,
                        child: GestureDetector(
                          onTap: () => widget.onOpenAlert(a),
                          child: _AlertPin(
                            critical:
                                triageOf(a).level == TriageLevel.critical,
                            assigned: widget.mine.any(
                                (m) => m['_id'] == a['_id']),
                          ),
                        ),
                      ),
              ],
            ),
            const RichAttributionWidget(
              alignment: AttributionAlignment.bottomLeft,
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        // Layer filters.
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _LayerChip(
                        label: 'All',
                        active: _layer == _Layer.all,
                        onTap: () => setState(() => _layer = _Layer.all),
                      ),
                      const SizedBox(width: 7),
                      _LayerChip(
                        label: 'My cases',
                        active: _layer == _Layer.mine,
                        onTap: () => setState(() => _layer = _Layer.mine),
                      ),
                      const SizedBox(width: 7),
                      _LayerChip(
                        label: 'Facilities',
                        active: _layer == _Layer.facilities,
                        onTap: () => setState(() => _layer = _Layer.facilities),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _MapButton(
                icon: Icons.my_location_rounded,
                onTap: () {
                  if (widget.position != null) {
                    _map.move(_center, 14.5);
                  } else {
                    Geolocator.openLocationSettings();
                  }
                },
              ),
            ],
          ),
        ),
        if (!widget.locationKnown)
          Positioned(
            left: 12,
            right: 12,
            bottom: _selectedFacility == null ? 16 : 150,
            child: NoticeBanner(
              icon: Icons.location_off_rounded,
              message: 'Location is off. Enable GPS so nearby cases can find '
                  'you and appear on this map.',
              color: const Color(0xFF8A4A00),
              action: TextButton(
                onPressed: () => Geolocator.openLocationSettings(),
                child: const Text('Enable'),
              ),
            ),
          ),
        if (_selectedFacility != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 14,
            child: _FacilitySheet(
              facility: _selectedFacility!,
              myPosition: widget.position,
              onClose: () => setState(() => _selectedFacility = null),
            ),
          ),
      ],
    );
  }
}

Widget _softTiles(BuildContext context, Widget tile, TileImage tileImage) {
  return ColorFiltered(
    colorFilter: const ColorFilter.matrix([
      0.94, 0.04, 0.02, 0, 8, //
      0.02, 0.96, 0.02, 0, 10, //
      0.02, 0.04, 0.90, 0, 4, //
      0, 0, 0, 1, 0, //
    ]),
    child: tile,
  );
}

class _LayerChip extends StatelessWidget {
  const _LayerChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.forestDeep : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
              color: active ? AppColors.forestDeep : AppColors.line),
          boxShadow: AppShadows.card,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: active ? AppColors.cream : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(side: BorderSide(color: AppColors.line)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 19, color: AppColors.forest),
        ),
      ),
    );
  }
}

class _MePin extends StatelessWidget {
  const _MePin();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.sky.withValues(alpha: 0.18),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.sky,
          border: Border.all(color: AppColors.white, width: 2.5),
          boxShadow: AppShadows.floating,
        ),
      ),
    );
  }
}

class _AlertPin extends StatelessWidget {
  const _AlertPin({required this.critical, required this.assigned});

  final bool critical;
  final bool assigned;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white,
        border: Border.all(
          color: critical ? AppColors.coral : AppColors.amber,
          width: 2,
        ),
        boxShadow: AppShadows.floating,
      ),
      alignment: Alignment.center,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: critical ? AppColors.coral : AppColors.amber,
        ),
        child: Icon(
          assigned ? Icons.directions_run_rounded : Icons.warning_rounded,
          color: AppColors.white,
          size: 16,
        ),
      ),
    );
  }
}

class _FacilityPin extends StatelessWidget {
  const _FacilityPin();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white,
        border: Border.all(color: AppColors.teal, width: 2),
        boxShadow: AppShadows.card,
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.local_hospital_rounded,
          size: 19, color: AppColors.teal),
    );
  }
}

class _FacilitySheet extends StatelessWidget {
  const _FacilitySheet({
    required this.facility,
    required this.myPosition,
    required this.onClose,
  });

  final Map<String, dynamic> facility;
  final Position? myPosition;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final coords = (facility['location'] is Map)
        ? (facility['location'] as Map)['coordinates']
        : null;
    final phone = facility['phone'] as String?;
    String? distance;
    if (coords is List && coords.length == 2 && myPosition != null) {
      final meters = Geolocator.distanceBetween(
        myPosition!.latitude,
        myPosition!.longitude,
        (coords[1] as num).toDouble(),
        (coords[0] as num).toDouble(),
      );
      distance = distanceLabel(meters);
    }
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      radius: AppRadii.lg,
      shadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBubble(
                icon: Icons.local_hospital_rounded,
                color: AppColors.teal,
                size: 40,
                iconSize: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      facility['name'] as String? ?? 'Facility',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        facility['type'] as String?,
                        ?distance,
                      ].whereType<String>().join(' · '),
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, size: 19),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (phone != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => launchUrl(Uri.parse('tel:$phone')),
                    icon: const Icon(Icons.call_rounded, size: 18),
                    label: const Text('Call'),
                  ),
                ),
              if (phone != null && coords is List) const SizedBox(width: 8),
              if (coords is List && coords.length == 2)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse(
                          'https://www.google.com/maps/dir/?api=1&destination=${coords[1]},${coords[0]}'),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.navigation_rounded, size: 18),
                    label: const Text('Navigate'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
