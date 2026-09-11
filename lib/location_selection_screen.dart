import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ===================================================================
// 📍 DATA MODEL: CUSTOMER LOCATION
// ===================================================================
class CustomerLocation {
  final double latitude;
  final double longitude;
  final String address;

  const CustomerLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      };

  factory CustomerLocation.fromJson(Map<String, dynamic> json) => CustomerLocation(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        address: json['address'] as String? ?? '',
      );

  @override
  String toString() => '$address ($latitude, $longitude)';
}

// ===================================================================
// 🛠️ LOCATION ACCESS SERVICE & DISTANCE HELPER
// ===================================================================
class LocationService {
  static const String _prefLatKey = 'customer_pinned_lat';
  static const String _prefLngKey = 'customer_pinned_lng';
  static const String _prefAddrKey = 'customer_pinned_address';

  // พิกัดเริ่มต้น กรณีไม่มีพิกัดบันทึกไว้ (โซน ม.มหาสารคาม / ขามเรียง)
  static const double defaultLat = 16.2468;
  static const double defaultLng = 103.2505;
  static const String defaultAddress = 'มหาวิทยาลัยมหาสารคาม (มมส. ขามเรียง) ตำบลขามเรียง อำเภอกันทรวิชัย มหาสารคาม';

  static List<String> mySavedAddresses = [
    'บ้าน - 999 ถนนเพลินจิต แขวงลุมพินี เขตปทุมวัน กรุงเทพมหานคร 10330',
    'ที่ทำงาน - มหาวิทยาลัยมหาสารคาม ต.ขามเรียง อ.กันทรวิชัย มหาสารคาม 44150',
  ];

  /// บันทึกตำแหน่งของลูกค้าลงใน SharedPreferences
  static Future<void> saveLocation(CustomerLocation loc) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefLatKey, loc.latitude);
      await prefs.setDouble(_prefLngKey, loc.longitude);
      await prefs.setString(_prefAddrKey, loc.address);
    } catch (e) {
      debugPrint('Error saving customer location: $e');
    }
  }

  /// โหลดตำแหน่งที่เคยบันทึกไว้
  static Future<CustomerLocation?> getSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble(_prefLatKey);
      final lng = prefs.getDouble(_prefLngKey);
      final addr = prefs.getString(_prefAddrKey);
      if (lat != null && lng != null && addr != null && addr.isNotEmpty) {
        return CustomerLocation(latitude: lat, longitude: lng, address: addr);
      }
    } catch (e) {
      debugPrint('Error loading saved location: $e');
    }
    return null;
  }

  /// ขอ Permission + ดึงตำแหน่ง GPS ปัจจุบันของอุปกรณ์
  static Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } on TimeoutException {
      return null;
    } catch (e) {
      return null;
    }
  }

  /// แปลงพิกัด (lat, lon) เป็นชื่อที่อยู่อ่านง่าย ผ่าน OpenStreetMap Nominatim (ฟรี 100%)
  static Future<String?> reverseGeocodeOSM(double lat, double lon) async {
    final uri = Uri.parse('https://nominatim.openstreetmap.org/reverse').replace(
      queryParameters: {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'format': 'json',
        'addressdetails': '1',
        'accept-language': 'th,en',
      },
    );

    try {
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'FlutterApp_FoodTruckTracker/1.0 (academic project)'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      // ดึงรายละเอียดที่อยู่เพื่อสร้างข้อความภาษาไทยกระชับ
      final addressObj = data['address'] as Map<String, dynamic>?;
      if (addressObj != null) {
        final List<String> parts = [];
        final road = addressObj['road'] ?? addressObj['suburb'] ?? addressObj['quarter'];
        final subDistrict = addressObj['subdistrict'] ?? addressObj['village'] ?? addressObj['town'];
        final district = addressObj['district'] ?? addressObj['city_district'] ?? addressObj['county'];
        final province = addressObj['province'] ?? addressObj['state'] ?? addressObj['city'];

        if (road != null && road.toString().trim().isNotEmpty) parts.add(road.toString().trim());
        if (subDistrict != null && subDistrict.toString().trim().isNotEmpty) parts.add(subDistrict.toString().trim());
        if (district != null && district.toString().trim().isNotEmpty) parts.add(district.toString().trim());
        if (province != null && province.toString().trim().isNotEmpty) parts.add(province.toString().trim());

        if (parts.isNotEmpty) {
          return parts.join(', ');
        }
      }

      return data['display_name']?.toString();
    } catch (e) {
      debugPrint('reverseGeocodeOSM error: $e');
      return null;
    }
  }

  /// ค้นหาชื่อสถานที่ผ่าน OpenStreetMap Nominatim
  static Future<List<Map<String, dynamic>>> searchPlacesOSM(String query) async {
    if (query.trim().isEmpty) return [];
    final uri = Uri.parse('https://nominatim.openstreetmap.org/search').replace(
      queryParameters: {
        'q': query.trim(),
        'format': 'json',
        'addressdetails': '1',
        'limit': '5',
        'countrycodes': 'th',
        'accept-language': 'th,en',
      },
    );

    try {
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'FlutterApp_FoodTruckTracker/1.0 (academic project)'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return [];
      final list = jsonDecode(response.body) as List;
      return list.map((item) => {
        'name': item['display_name'] ?? '',
        'lat': double.tryParse(item['lat']?.toString() ?? '') ?? 0.0,
        'lon': double.tryParse(item['lon']?.toString() ?? '') ?? 0.0,
      }).where((m) => (m['lat'] as double) != 0.0).toList();
    } catch (e) {
      debugPrint('searchPlacesOSM error: $e');
      return [];
    }
  }

  /// คำนวณระยะทางตรง (Haversine) คืนค่าเป็นกิโลเมตร
  static double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    final double meters = Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
    return meters / 1000.0;
  }

  /// แปลงระยะทางเป็นข้อความแสดงผลภาษาไทย (เช่น "450 ม." หรือ "1.8 กม.")
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1.0) {
      final meters = (distanceKm * 1000).round();
      return '$meters ม.';
    } else {
      return '${distanceKm.toStringAsFixed(1)} กม.';
    }
  }

  /// เปิดหน้าเลือกที่อยู่ (รองรับ Callback ทั้งแบบ CustomerLocation และแบบ String เดิม)
  static void openAddressSelector(
    BuildContext context,
    Function(dynamic) onSelected,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddressSelectionSheet(
          onLocationSelected: (loc) {
            onSelected(loc);
          },
        ),
      ),
    );
  }

  static void showPermissionDisabledModal(
    BuildContext context,
    VoidCallback onEnableSettings,
    VoidCallback onSpecifyManual,
  ) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFE5EEF5),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00C7E6).withValues(alpha: 0.3), width: 8),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.smartphone_rounded, size: 58, color: Color(0xFF0B1A30)),
                  Positioned(
                    top: 24,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Color(0xFF00C7E6), shape: BoxShape.circle),
                      child: const Icon(Icons.location_on, size: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'การเข้าถึงตำแหน่งถูกปิดอยู่',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'เปิดการเข้าถึงตำแหน่ง GPS เพื่อค้นหาร้านรถเข็นใกล้คุณ หรือเลือกปักหมุดบนแผนที่ด้วยตนเอง',
              style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B), height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C7E6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  onEnableSettings();
                },
                child: const Text('เปิดในการตั้งค่า', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  onSpecifyManual();
                },
                child: const Text('เลือกจากแผนที่เอง', style: TextStyle(color: Color(0xFF0B1A30), fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================================================================
// 1. หน้าเลือกที่อยู่ (AddressSelectionSheet)
// ===================================================================
class AddressSelectionSheet extends StatefulWidget {
  final Function(CustomerLocation) onLocationSelected;
  const AddressSelectionSheet({super.key, required this.onLocationSelected});

  @override
  State<AddressSelectionSheet> createState() => _AddressSelectionSheetState();
}

class _AddressSelectionSheetState extends State<AddressSelectionSheet> {
  final _searchCtrl = TextEditingController();
  bool _isGettingGps = false;
  CustomerLocation? _savedLocation;

  @override
  void initState() {
    super.initState();
    _loadInitialLocation();
  }

  Future<void> _loadInitialLocation() async {
    final saved = await LocationService.getSavedLocation();
    if (mounted && saved != null) {
      setState(() => _savedLocation = saved);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _onCurrentLocationTapped() async {
    setState(() => _isGettingGps = true);
    final pos = await LocationService.getCurrentPosition();

    if (!mounted) return;
    setState(() => _isGettingGps = false);

    if (pos == null) {
      LocationService.showPermissionDisabledModal(
        context,
        () async {
          await openAppSettings();
        },
        () {
          _openMapPinScreen();
        },
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF00C7E6))),
      );

      final address = await LocationService.reverseGeocodeOSM(pos.latitude, pos.longitude) ??
          'ตำแหน่งปัจจุบัน (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})';

      if (!mounted) return;
      Navigator.pop(context); // ปิด loading

      final loc = CustomerLocation(
        latitude: pos.latitude,
        longitude: pos.longitude,
        address: address,
      );

      await LocationService.saveLocation(loc);
      if (!mounted) return;
      widget.onLocationSelected(loc);
      Navigator.pop(context); // ปิด AddressSelectionSheet

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('อัปเดตตำแหน่งปัจจุบันจาก GPS สำเร็จ 🎯'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openMapPinScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapPinSelectionScreen(
          initialLocation: _savedLocation,
          onConfirmLocation: (loc) {
            widget.onLocationSelected(loc);
            Navigator.pop(context); // ปิด AddressSelectionSheet
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('เลือกตำแหน่งของคุณ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0B1A30), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── เมนู 1: เลือกจากแผนที่ OpenStreetMap (ปักหมุด)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFE0F7FA), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.map_outlined, color: Color(0xFF00C7E6), size: 24),
            ),
            title: const Text('เลือกจากแผนที่', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
            subtitle: const Text('ปักหมุดจุดที่คุณยืนอยู่บนแผนที่จริง', style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 22),
            onTap: _openMapPinScreen,
          ),
          const Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFE2E8F0)),

          // ── เมนู 2: ตำแหน่งปัจจุบัน (GPS จากเครื่อง)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
              child: _isGettingGps
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF10B981)))
                  : const Icon(Icons.my_location_rounded, color: Color(0xFF10B981), size: 24),
            ),
            title: const Text('ตำแหน่งปัจจุบัน (GPS)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
            subtitle: const Text('ดึงพิกัดอัตโนมัติจาก GPS ของสมาร์ตโฟน', style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 22),
            onTap: _isGettingGps ? null : _onCurrentLocationTapped,
          ),
          const Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFE2E8F0)),

          // ── แสดงตำแหน่งที่บันทึกไว้ล่าสุด
          if (_savedLocation != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
              child: const Text('ตำแหน่งล่าสุดของคุณ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              leading: const Icon(Icons.history, color: Color(0xFF00C7E6), size: 24),
              title: Text(_savedLocation!.address, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0B1A30)), maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text('พิกัด: ${_savedLocation!.latitude.toStringAsFixed(4)}, ${_savedLocation!.longitude.toStringAsFixed(4)}', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              onTap: () {
                widget.onLocationSelected(_savedLocation!);
                Navigator.pop(context);
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ===================================================================
// 2. หน้าต่างแผนที่ปักหมุด (MapPinSelectionScreen) ด้วย OpenStreetMap
// ===================================================================
class MapPinSelectionScreen extends StatefulWidget {
  final CustomerLocation? initialLocation;
  final Function(CustomerLocation) onConfirmLocation;

  const MapPinSelectionScreen({
    super.key,
    this.initialLocation,
    required this.onConfirmLocation,
  });

  @override
  State<MapPinSelectionScreen> createState() => _MapPinSelectionScreenState();
}

class _MapPinSelectionScreenState extends State<MapPinSelectionScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchCtrl = TextEditingController();

  late LatLng _currentCenter;
  String _currentAddress = 'กำลังโหลดตำแหน่ง...';
  bool _isGeocoding = false;
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _currentCenter = LatLng(widget.initialLocation!.latitude, widget.initialLocation!.longitude);
      _currentAddress = widget.initialLocation!.address;
    } else {
      _currentCenter = const LatLng(LocationService.defaultLat, LocationService.defaultLng);
      _currentAddress = LocationService.defaultAddress;
    }

    // ทำ Reverse Geocode จุดเริ่มต้น
    _reverseGeocodePoint(_currentCenter);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  /// ดึงที่อยู่จากพิกัดกึ่งกลางจอ
  void _reverseGeocodePoint(LatLng point) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      setState(() => _isGeocoding = true);

      final addr = await LocationService.reverseGeocodeOSM(point.latitude, point.longitude);
      if (!mounted) return;

      setState(() {
        _isGeocoding = false;
        if (addr != null && addr.isNotEmpty) {
          _currentAddress = addr;
        } else {
          _currentAddress = 'พิกัด ${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
        }
      });
    });
  }

  /// ค้นหาสถานที่ตามชื่อที่พิมพ์
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    final results = await LocationService.searchPlacesOSM(query);
    if (!mounted) return;

    setState(() {
      _isSearching = false;
      _searchResults = results;
    });
  }

  /// เลือกสถานที่จากผลลัพธ์การค้นหา
  void _selectSearchResult(Map<String, dynamic> item) {
    final double lat = item['lat'];
    final double lon = item['lon'];
    final LatLng newPos = LatLng(lat, lon);

    _mapController.move(newPos, 16.5);
    setState(() {
      _currentCenter = newPos;
      _currentAddress = item['name'] ?? '';
      _searchResults = [];
      _searchCtrl.clear();
    });
    FocusScope.of(context).unfocus();
  }

  /// ดึงตำแหน่ง GPS ปัจจุบันมาที่กึ่งกลางจอ
  Future<void> _recenterToCurrentGps() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('กำลังค้นหาพิกัด GPS ปัจจุบัน... 📡'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );

    final pos = await LocationService.getCurrentPosition();
    if (!mounted) return;

    if (pos != null) {
      final newPos = LatLng(pos.latitude, pos.longitude);
      _mapController.move(newPos, 16.5);
      setState(() => _currentCenter = newPos);
      _reverseGeocodePoint(newPos);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่สามารถดึงตำแหน่ง GPS ได้ กรุณาเปิด GPS หรือให้สิทธิ์เข้าถึง'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: Stack(
        children: [
          // ── 1. Real OpenStreetMap Canvas (flutter_map)
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentCenter,
                initialZoom: 16.0,
                minZoom: 4.0,
                maxZoom: 18.5,
                onPositionChanged: (camera, hasGesture) {
                  if (hasGesture) {
                    _currentCenter = camera.center;
                    _reverseGeocodePoint(camera.center);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.myapp',
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('© OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),

          // ── 2. Fixed Center Pin with Guide Badge
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1A30),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.touch_app, color: Color(0xFF00C7E6), size: 16),
                        SizedBox(width: 6),
                        Text('ลากแผนที่เพื่อเลื่อนหมุด', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Icon(Icons.location_on_rounded, size: 50, color: Color(0xFF00C7E6)),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1A30),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 6)],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 3. Top Search Overlay Bar & Auto-suggestions
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 14, offset: const Offset(0, 4))],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0B1A30), size: 18),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            onSubmitted: _performSearch,
                            decoration: const InputDecoration(
                              hintText: 'ค้นหาชื่อสถานที่, ซอย, ตึก...',
                              hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14.5),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                            ),
                          ),
                        ),
                        if (_isSearching)
                          const Padding(
                            padding: EdgeInsets.all(10),
                            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00C7E6))),
                          )
                        else if (_searchCtrl.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, color: Color(0xFF94A3B8), size: 20),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchResults = []);
                            },
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.search, color: Color(0xFF00C7E6), size: 22),
                            onPressed: () => _performSearch(_searchCtrl.text),
                          ),
                      ],
                    ),
                  ),

                  // รายการผลลัพธ์การค้นหา (Dropdown Drop)
                  if (_searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      constraints: const BoxConstraints(maxHeight: 220),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        itemBuilder: (ctx, i) {
                          final item = _searchResults[i];
                          return ListTile(
                            leading: const Icon(Icons.location_on_outlined, color: Color(0xFF00C7E6), size: 20),
                            title: Text(item['name'] ?? '', style: const TextStyle(fontSize: 13.5, color: Color(0xFF0B1A30)), maxLines: 2, overflow: TextOverflow.ellipsis),
                            onTap: () => _selectSearchResult(item),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── 4. GPS Recalibrate Floating Button
          Positioned(
            right: 18,
            bottom: 230,
            child: FloatingActionButton(
              heroTag: 'recenter_gps_btn',
              backgroundColor: Colors.white,
              elevation: 4,
              shape: const CircleBorder(),
              onPressed: _recenterToCurrentGps,
              child: const Icon(Icons.my_location, color: Color(0xFF00C7E6), size: 24),
            ),
          ),

          // ── 5. Bottom Info Panel (ตำแหน่งหมุด & ปุ่มยืนยัน)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.09), blurRadius: 20, offset: const Offset(0, -6))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.place, color: Color(0xFF00C7E6), size: 22),
                          const SizedBox(width: 8),
                          const Text('ตำแหน่งหมุดปัจจุบัน', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0B1A30))),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          '${_currentCenter.latitude.toStringAsFixed(4)}, ${_currentCenter.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isGeocoding) ...[
                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00C7E6))),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Text(
                          _currentAddress,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.4),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C7E6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final loc = CustomerLocation(
                          latitude: _currentCenter.latitude,
                          longitude: _currentCenter.longitude,
                          address: _currentAddress,
                        );
                        await LocationService.saveLocation(loc);
                        widget.onConfirmLocation(loc);
                      },
                      child: const Text('ยืนยันตำแหน่งนี้', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
}
