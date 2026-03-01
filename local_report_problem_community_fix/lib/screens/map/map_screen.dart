import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/problem_provider.dart';
import '../../models/problem_model.dart';
import '../../theme/app_theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final LatLng _initialPosition = const LatLng(24.8607, 67.0011); // Karachi default
  LatLng? _myLocation;
  String _filterCategory = 'all';
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProblemProvider>(context, listen: false).fetchProblems();
      _getMyLocation();
    });
  }

  Future<void> _getMyLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() => _myLocation = LatLng(pos.latitude, pos.longitude));
          _mapController.move(_myLocation!, 14);
        }
      }
    } catch (_) {}
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'water': return Colors.blue;
      case 'electricity': return Colors.amber;
      case 'road': return Colors.grey.shade700;
      case 'garbage': return Colors.brown;
      case 'drainage': return Colors.teal;
      default: return Colors.deepPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final problemProvider = Provider.of<ProblemProvider>(context);

    // Apply local filters
    final filtered = problemProvider.problems.where((p) {
      final catOk = _filterCategory == 'all' || p.category == _filterCategory;
      final statusOk = _filterStatus == 'all' || p.status.name == _filterStatus;
      return catOk && statusOk;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Civic Issues Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _initialPosition,
          initialZoom: 12,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.local_report_problem_community_fix',
          ),
          MarkerLayer(
            markers: [
              // My location marker
              if (_myLocation != null)
                Marker(
                  point: _myLocation!,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.my_location, color: Colors.blue, size: 32),
                ),
              // Problem markers
              ...filtered.map((p) => Marker(
                point: LatLng(p.latitude, p.longitude),
                width: 42,
                height: 42,
                child: GestureDetector(
                  onTap: () => _showProblemSheet(p),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _categoryColor(p.category),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                    ),
                    child: const Icon(Icons.report_problem, color: Colors.white, size: 20),
                  ),
                ),
              )),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'locate',
        onPressed: () {
          if (_myLocation != null) _mapController.move(_myLocation!, 15);
          else _getMyLocation();
        },
        child: const Icon(Icons.gps_fixed),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(builder: (ctx, setSheetState) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filter Issues', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['all', 'road', 'garbage', 'water', 'electricity', 'drainage', 'other'].map((c) =>
                  ChoiceChip(
                    label: Text(c.toUpperCase()),
                    selected: _filterCategory == c,
                    onSelected: (_) {
                      setSheetState(() => _filterCategory = c);
                      setState(() => _filterCategory = c);
                    },
                  )
                ).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Status', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['all', 'pending', 'approved', 'resolved'].map((s) =>
                  ChoiceChip(
                    label: Text(s.toUpperCase()),
                    selected: _filterStatus == s,
                    onSelected: (_) {
                      setSheetState(() => _filterStatus = s);
                      setState(() => _filterStatus = s);
                    },
                  )
                ).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      }),
    );
  }

  void _showProblemSheet(ProblemModel p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (p.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(p.imageUrl, height: 180, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(height: 100, color: Colors.grey[200])),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(6)),
                  child: Text(p.category.toUpperCase(), style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(6)),
                  child: Text(p.status.name.toUpperCase(), style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(p.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(p.description, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 12),
            Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      final problemProvider = Provider.of<ProblemProvider>(context, listen: false);
                      if (authProvider.currentUserId != null) {
                        try {
                          await problemProvider.voteProblem(p.problemId, authProvider.currentUserId!);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Voted Successfully!'), duration: Duration(seconds: 1)),
                            );
                            Navigator.pop(context); // Close sheet to refresh view
                          }
                        } catch (e) {
                          print("LPRCF: Map vote error: $e");
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.thumb_up_alt_outlined, size: 20, color: Colors.blue),
                          const SizedBox(width: 6),
                          Text('${p.voteCount} Votes', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Flexible(child: Text(p.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey))),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
