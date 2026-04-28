import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

// Tactical Tactical Design System (Prompt 4 Palette)
const Color bg = Color(0xFF182024);
const Color panel = Color(0xFF1C252A);
const Color cardBg = Color(0xFF212B31);
const Color border = Color(0xFF2A343A);
const Color green = Color(0xFF00D68F);
const Color emerald = green;
const Color emeraldBorder = Color(0x3300D68F);
const Color neonOrange = Color(0xFFFF5722);
const Color slateText = Color(0xFFE0E6ED);
const Color blue = Color(0xFF3B82F6);
const Color cyan = Color(0xFF00D4FF);
const Color violet = Color(0xFFA78BFA);
const Color orange = Color(0xFFFBBF24);
const Color yellow = Color(0xFFFBBF24);

class AppTheme {
  final Color bg;
  final Color bg2;
  final Color card;
  final Color border;
  final Color text;
  final Color primary;
  final Color secondary;
  final Color shadow;
  final Color grid;

  const AppTheme({
    required this.bg,
    required this.bg2,
    required this.card,
    required this.border,
    required this.text,
    required this.primary,
    required this.secondary,
    required this.shadow,
    required this.grid,
  });

  static const dark = AppTheme(
    bg: Color(0xFF182024),
    bg2: Color(0xFF1C252A),
    card: Color(0x99212B31),
    border: Color(0x3300D68F),
    text: Color(0xFFE0E6ED),
    primary: Color(0xFF00D68F),
    secondary: Color(0xFFFF5722),
    shadow: Color(0x1A00D68F),
    grid: Color(0x0D00D68F),
  );

  static const light = AppTheme(
    bg: Color(0xFFFAFBFB),
    bg2: Color(0xFFE2E8F0),
    card: Color(0xD9FFFFFF),
    border: Color(0x4094A3B8),
    text: Color(0xFF0F172A),
    primary: Color(0xFF0EA5E9),
    secondary: Color(0xFFF59E0B),
    shadow: Color(0x1A0F172A),
    grid: Color(0x1A94A3B8),
  );
}

const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
const googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
const backendBaseUrl = String.fromEnvironment('BACKEND_BASE_URL', defaultValue: 'http://127.0.0.1:5000');

void main() {
  runApp(const CommandApp());
}

class CommandApp extends StatefulWidget {
  const CommandApp({super.key});

  @override
  State<CommandApp> createState() => _CommandAppState();
}

class _CommandAppState extends State<CommandApp> {
  final store = AppStore();
  Timer? timer;

  @override
  void initState() {
    super.initState();
    store.load().then((_) => setState(() {}));
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (store.completeExpiredAssignments()) setState(() {});
      store.checkNotifications();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = store.theme;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NEXUS DISPATCH',
      theme: ThemeData(
        useMaterial3: true,
        brightness: store.isDarkMode ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: theme.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: theme.primary,
          brightness: store.isDarkMode ? Brightness.dark : Brightness.light,
          surface: theme.bg2,
        ),
        fontFamily: 'Inter',
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: store.isDarkMode ? theme.text : const Color(0xFF334155), letterSpacing: -0.2),
          bodyMedium: TextStyle(color: store.isDarkMode ? theme.text : const Color(0xFF64748B), letterSpacing: -0.2),
          headlineLarge: TextStyle(color: theme.text, fontWeight: FontWeight.w900, letterSpacing: -1.2, height: 1.1),
          headlineMedium: TextStyle(color: theme.text, fontWeight: FontWeight.bold, letterSpacing: -0.8),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primary,
            foregroundColor: store.isDarkMode ? theme.bg : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.primary,
            side: BorderSide(color: theme.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ),
      home: store.ready ? Shell(store: store, onChanged: () => setState(() {})) : const LoadingScreen(),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator(color: green)));
  }
}

class UserAccount {
  UserAccount({required this.id, required this.email, required this.password, required this.name, required this.role, List<Incident>? incidents})
      : incidents = incidents ?? [];

  final String id;
  final String email;
  final String password;
  final String name;
  final String role;
  final List<Incident> incidents;

  factory UserAccount.fromJson(Map<String, dynamic> json) => UserAccount(
        id: '${json['id']}',
        email: json['email'] ?? '',
        password: json['password'] ?? '',
        name: json['name'] ?? '',
        role: json['role'] ?? 'user',
        incidents: (json['incidents'] as List? ?? []).map((item) => Incident.fromJson(Map<String, dynamic>.from(item))).toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'password': password,
        'name': name,
        'role': role,
        'incidents': incidents.map((item) => item.toJson()).toList(),
      };
}

class Incident {
  Incident({
    required this.id,
    required this.description,
    required this.incidentType,
    required this.place,
    required this.date,
    this.status = 'pending',
    this.score,
    this.lat,
    this.lon,
    this.responderCategory,
    this.responderType,
    this.responderId,
    this.responderName,
    this.resourceLat,
    this.resourceLon,
    this.distanceKm,
    this.etaMinutes,
    this.etaSeconds,
    this.assignedAt,
    this.completedAt,
    this.image,
  });

  final String id;
  final String description;
  final String incidentType;
  final String place;
  final String date;
  String status;
  int? score;
  double? lat;
  double? lon;
  String? responderCategory;
  String? responderType;
  String? responderId;
  String? responderName;
  double? resourceLat;
  double? resourceLon;
  double? distanceKm;
  int? etaMinutes;
  int? etaSeconds;
  int? assignedAt;
  String? completedAt;
  String? image;

  factory Incident.fromJson(Map<String, dynamic> json) => Incident(
        id: '${json['id']}',
        description: json['description'] ?? '',
        incidentType: json['incidentType'] ?? '',
        place: json['place'] ?? '',
        date: json['date'] ?? DateTime.now().toIso8601String(),
        status: json['status'] ?? 'pending',
        score: asInt(json['score']),
        lat: asDouble(json['lat']),
        lon: asDouble(json['lon']),
        responderCategory: json['responderCategory'],
        responderType: json['responderType'],
        responderId: json['responderId'],
        responderName: json['responderName'],
        resourceLat: asDouble(json['resourceLat']),
        resourceLon: asDouble(json['resourceLon']),
        distanceKm: asDouble(json['distanceKm']),
        etaMinutes: asInt(json['etaMinutes']),
        etaSeconds: asInt(json['etaSeconds']),
        assignedAt: asInt(json['assignedAt']),
        completedAt: json['completedAt'],
        image: json['image'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'incidentType': incidentType,
        'place': place,
        'date': date,
        'status': status,
        'score': score,
        'lat': lat,
        'lon': lon,
        'responderCategory': responderCategory,
        'responderType': responderType,
        'responderId': responderId,
        'responderName': responderName,
        'resourceLat': resourceLat,
        'resourceLon': resourceLon,
        'distanceKm': distanceKm,
        'etaMinutes': etaMinutes,
        'etaSeconds': etaSeconds,
        'assignedAt': assignedAt,
        'completedAt': completedAt,
        'image': image,
      };
}

class IncidentView {
  IncidentView(this.incident, this.user);
  final Incident incident;
  final UserAccount user;
}

class ResourceUnit {
  const ResourceUnit(this.id, this.name, this.lat, this.lon);
  final String id;
  final String name;
  final double lat;
  final double lon;
}

class Assignment {
  Assignment({
    required this.category,
    required this.responderType,
    required this.resource,
    required this.lat,
    required this.lon,
    required this.distanceKm,
    required this.etaMinutes,
  });

  final String category;
  final String responderType;
  final ResourceUnit resource;
  final double lat;
  final double lon;
  final double distanceKm;
  final int etaMinutes;
}

class PlaceSuggestion {
  PlaceSuggestion({required this.description, this.placeId, this.lat, this.lon});
  final String description;
  final String? placeId;
  final double? lat;
  final double? lon;
}

class AppNotification {
  AppNotification({required this.title, required this.message, required this.timestamp});
  final String title;
  final String message;
  final DateTime timestamp;
}

class AppStore {
  static final AppStore _instance = AppStore._internal();
  factory AppStore() => _instance;
  AppStore._internal();

  bool ready = false;
  List<UserAccount> users = [];
  UserAccount? currentUser;
  bool isDarkMode = true;
  List<AppNotification> notifications = [];
  Map<String, String> _lastStatus = {};

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode = true;
    final rawUsers = prefs.getString('nexus_dispatch_users');
    final rawCurrent = prefs.getString('crisis_flutter_current_user');
    if (rawUsers != null) {
      users = (jsonDecode(rawUsers) as List).map((item) => UserAccount.fromJson(Map<String, dynamic>.from(item))).toList();
    }
    if (rawCurrent != null) {
      final saved = UserAccount.fromJson(Map<String, dynamic>.from(jsonDecode(rawCurrent)));
      currentUser = users.where((user) => user.id == saved.id).firstOrNull;
    }
    ready = true;
  }

  Future<void> persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
    await prefs.setString('nexus_dispatch_users', jsonEncode(users.map((e) => e.toJson()).toList()));
    if (currentUser != null) {
      await prefs.setString('crisis_flutter_current_user', jsonEncode(currentUser!.toJson()));
    } else {
      await prefs.remove('crisis_flutter_current_user');
    }
  }

  void checkNotifications() {
    final all = allIncidents();
    bool changed = false;
    
    // Track known IDs to detect truly new incidents
    final currentIds = all.map((i) => i.incident.id).toSet();
    
    for (var item in all) {
      final id = item.incident.id;
      final status = item.incident.status;
      
      if (_lastStatus.containsKey(id)) {
        if (_lastStatus[id] != status) {
          // Status change notification for users
          if (currentUser?.role == 'user' && status == 'assigned' && item.user.id == currentUser?.id) {
            addNotification('Incident Assigned', 'Your report for ${item.incident.incidentType} has been assigned a responder.');
            changed = true;
          }
          if (status == 'completed' && item.user.id == currentUser?.id) {
            addNotification('Incident Resolved', 'Your emergency request has been marked as resolved.');
            changed = true;
          }
        }
      } else {
        // New incident notification for admin
        if (currentUser?.role == 'admin') {
          if ((item.incident.score ?? 0) > 90) {
            addNotification('CRITICAL ALERT', 'High-severity incident detected: ${item.incident.incidentType}');
          } else {
            addNotification('New Report', 'New ${item.incident.incidentType} report from ${item.user.name}');
          }
          changed = true;
        }
      }
      _lastStatus[id] = status;
    }
  }

  AppTheme get theme => isDarkMode ? AppTheme.dark : AppTheme.light;

  void toggleTheme() {
    isDarkMode = !isDarkMode;
    persist();
  }

  void addNotification(String title, String message) {
    notifications.insert(0, AppNotification(title: title, message: message, timestamp: DateTime.now()));
  }

  Future<String?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$backendBaseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final user = UserAccount.fromJson(Map<String, dynamic>.from(data['user']));
        currentUser = user;
        final index = users.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          users[index] = user;
        } else {
          users.add(user);
        }
        persist();
        return null;
      } else {
        return data['message'] ?? 'Login failed';
      }
    } catch (e) {
      return 'Connection error: $e';
    }
  }

  Future<String?> signup({required String email, required String password, required String name, required String role}) async {
    try {
      final response = await http.post(
        Uri.parse('$backendBaseUrl/api/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'role': role,
        }),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final user = UserAccount.fromJson(Map<String, dynamic>.from(data['user']));
        currentUser = user;
        users.add(user);
        persist();
        return null;
      } else {
        return data['message'] ?? 'Signup failed';
      }
    } catch (e) {
      return 'Connection error: $e';
    }
  }

  void logout() {
    currentUser = null;
    persist();
  }

  Future<void> addIncident({required String description, required String incidentType, required String place, double? lat, double? lon, String? image}) async {
    final user = currentUser;
    if (user == null) return;
    
    final newIncident = Incident(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      description: description,
      incidentType: incidentType,
      place: place,
      lat: lat,
      lon: lon,
      image: image,
      date: DateTime.now().toIso8601String(),
    );

    try {
      final response = await http.post(
        Uri.parse('$backendBaseUrl/api/incidents'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': user.id,
          'incident': newIncident.toJson(),
        }),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final updatedUser = UserAccount.fromJson(Map<String, dynamic>.from(data['user']));
        currentUser = updatedUser;
        final idx = users.indexWhere((u) => u.id == user.id);
        if (idx != -1) users[idx] = updatedUser;
      } else {
        user.incidents.add(newIncident);
      }
    } catch (e) {
      user.incidents.add(newIncident);
    }
    persist();
  }

  List<IncidentView> allIncidents() {
    final all = <IncidentView>[];
    for (final user in users) {
      for (final incident in user.incidents) {
        all.add(IncidentView(incident, user));
      }
    }
    all.sort((a, b) => b.incident.date.compareTo(a.incident.date));
    return all;
  }

  Future<void> updateIncident(Incident incident) async {
    final user = currentUser;
    if (user == null) return;
    
    try {
      final response = await http.put(
        Uri.parse('$backendBaseUrl/api/incidents/${incident.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': user.id,
          'updates': incident.toJson(),
        }),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final updatedUser = UserAccount.fromJson(Map<String, dynamic>.from(data['user']));
        currentUser = updatedUser;
        final idx = users.indexWhere((u) => u.id == user.id);
        if (idx != -1) users[idx] = updatedUser;
      }
    } catch (e) {}
    persist();
  }

  bool completeExpiredAssignments() {
    var changed = false;
    for (final item in allIncidents()) {
      final incident = item.incident;
      if (incident.status == 'assigned' && remainingSeconds(incident) <= 0) {
        incident.status = 'completed';
        incident.completedAt = DateTime.now().toIso8601String();
        changed = true;
      }
    }
    if (changed) persist();
    return changed;
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key, required this.store, required this.onChanged});
  final AppStore store;
  final VoidCallback onChanged;

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int userTab = 0;
  int adminTab = 0;
  bool sidebarOpen = true;

  void showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            const Icon(Icons.notifications_rounded, color: emerald),
            const SizedBox(width: 12),
            const Text('Notifications', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton(
              onPressed: () { widget.store.notifications.clear(); Navigator.pop(context); widget.onChanged(); },
              child: const Text('Clear All', style: TextStyle(color: Colors.white38, fontSize: 12)),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: widget.store.notifications.isEmpty
              ? const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: EmptyState(icon: Icons.notifications_none_rounded, text: 'No new notifications'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.store.notifications.length,
                  itemBuilder: (context, index) {
                    final n = widget.store.notifications[index];
                    final isCritical = n.title.contains('CRITICAL');
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(color: isCritical ? Colors.red.withValues(alpha: .1) : cardBg.withValues(alpha: .5), borderRadius: BorderRadius.circular(12), border: Border.all(color: isCritical ? Colors.red.withValues(alpha: .3) : border)),
                      child: ListTile(
                        leading: Icon(isCritical ? Icons.warning_rounded : Icons.info_outline_rounded, color: isCritical ? Colors.redAccent : emerald),
                        title: Text(n.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.message, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('${n.timestamp.hour}:${n.timestamp.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.white24, fontSize: 10)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.store.currentUser;
    if (user == null) return AuthScreen(store: widget.store, onChanged: widget.onChanged);
    
    final isVolunteer = user.role == 'admin' || user.role == 'volunteer';
    final items = isVolunteer
        ? [
            (icon: Icons.grid_view_rounded, label: 'Dashboard'),
            (icon: Icons.business_center_rounded, label: 'Allotment'),
            (icon: Icons.assignment_rounded, label: 'Record'),
            (icon: Icons.format_list_bulleted_rounded, label: 'History'),
          ]
        : [
            (icon: Icons.report_problem_rounded, label: 'Report Incident'),
            (icon: Icons.map_rounded, label: 'Response Status'),
            (icon: Icons.history_rounded, label: 'My Reports'),
          ];

    final selected = isVolunteer ? adminTab : userTab;

    return Scaffold(
      body: Stack(
        children: [
          const CyberpunkBackground(),
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: sidebarOpen ? 250 : 0,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: widget.store.theme.bg2.withValues(alpha: .3),
                  border: Border(right: BorderSide(color: widget.store.theme.border)),
                ),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 28, 16, 24),
                      child: Row(
                        children: [
                          Icon(Icons.local_activity_rounded, color: green, size: 24),
                          SizedBox(width: 12),
                          Text('COMMAND', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        ],
                      ),
                    ),
                    ...List.generate(items.length, (index) {
                      final item = items[index];
                      final active = selected == index;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          selected: active,
                          selectedTileColor: emerald.withValues(alpha: .1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: active ? emerald.withValues(alpha: .3) : Colors.transparent)),
                          leading: Icon(item.icon, color: active ? emerald : Colors.grey),
                          title: Text(item.label, style: TextStyle(color: active ? Colors.white : Colors.grey.shade400, fontWeight: active ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
                          onTap: () => setState(() => isVolunteer ? adminTab = index : userTab = index),
                        ),
                      );
                    }),
                    const Spacer(),
                    const Divider(color: border, height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(radius: 16, backgroundColor: green, child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U', style: const TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 12))),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user.name.isEmpty ? 'Unit' : user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text(user.role, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              widget.store.logout();
                              widget.onChanged();
                            },
                            icon: const Icon(Icons.logout_rounded, size: 14, color: Colors.white),
                            label: const Text('Log Out', style: TextStyle(fontSize: 12, color: Colors.white)),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 36),
                              side: const BorderSide(color: border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 70,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: emerald.withValues(alpha: 0.1))),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => setState(() => sidebarOpen = !sidebarOpen),
                            icon: Icon(sidebarOpen ? Icons.menu_open_rounded : Icons.menu_rounded, color: emerald),
                          ),
                          const Spacer(),
                          Stack(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                                onPressed: () => showNotifications(context),
                              ),
                              if (widget.store.notifications.isNotEmpty)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: IgnorePointer(
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                      child: Text('${widget.store.notifications.length}', style: const TextStyle(fontSize: 10, color: Colors.white)),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: isVolunteer ? adminPage(selected) : userPage(selected),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget adminPage(int index) {
    final all = widget.store.allIncidents();
    final completed = all.where((item) => item.incident.status == 'completed').toList();
    return switch (index) {
      0 => AdminReportsView(store: widget.store, onChanged: widget.onChanged),
      1 => VolunteerAllotment(store: widget.store, onChanged: widget.onChanged),
      2 => AdminRecord(store: widget.store, onChanged: widget.onChanged),
      _ => HistoryPage(title: 'Mission History', incidents: completed),
    };
  }

  Widget userPage(int index) {
    return switch (index) {
      0 => UserDashboard(store: widget.store, onChanged: widget.onChanged),
      1 => UserAllocation(store: widget.store),
      _ => UserRouting(store: widget.store, onChanged: widget.onChanged),
    };
  }
}

class StepProgressIndicator extends StatelessWidget {
  const StepProgressIndicator({super.key, required this.currentStep, required this.totalSteps});
  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps * 2 - 1, (index) {
        if (index.isOdd) return Expanded(child: Container(height: 2, color: index ~/ 2 < currentStep - 1 ? emerald : border));
        final step = index ~/ 2 + 1;
        final active = step <= currentStep;
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? emerald : bg,
            border: Border.all(color: active ? emerald : border, width: 2),
            boxShadow: [if (active) BoxShadow(color: emerald.withValues(alpha: 0.3), blurRadius: 8)],
          ),
          child: Center(child: step < currentStep ? const Icon(Icons.check, size: 16, color: bg) : Text('$step', style: TextStyle(color: active ? bg : Colors.grey, fontWeight: FontWeight.bold))),
        );
      }),
    );
  }
}

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key, required this.store, required this.onChanged});
  final AppStore store;
  final VoidCallback onChanged;

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int step = 1;
  String? selectedAccidentType;
  String? groupOrIndividual;
  String? selectedGroupSize;
  final customGroupSize = TextEditingController();
  final description = TextEditingController();
  final place = TextEditingController();
  String? imageBase64;
  String? imageName;
  double? selectedLat;
  double? selectedLon;

  final List<String> accidentTypes = [
    'Fire related accident (Fire extinguishers required)',
    'Medical emergency (Ambulance required)',
    'Rescue operation (Rescue team required)',
    'Other Emergency',
  ];

  final List<String> groupSizes = ['< 10', '< 50', '< 100', '< 200', 'Other'];

  Future<void> fetchCurrentLocation() async {
    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition();
      setState(() { selectedLat = pos.latitude; selectedLon = pos.longitude; place.text = 'My Location (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})'; });
    } catch (_) {}
  }

  void next() {
    if (step == 1 && selectedAccidentType == null) return;
    if (step == 2 && groupOrIndividual == null) return;
    if (step == 2 && groupOrIndividual == 'Individual') {
      setState(() => step = 4);
      if (place.text.isEmpty) fetchCurrentLocation();
      return;
    }
    if (step == 3) {
      if (selectedGroupSize == null) return;
      if (selectedGroupSize == 'Other' && customGroupSize.text.trim().isEmpty) return;
    }
    if (step == 4 && place.text.trim().isEmpty) return;
    if (step == 3) fetchCurrentLocation(); // Fetch when moving to location step
    setState(() => step++);
  }

  void back() {
    if (step == 4 && groupOrIndividual == 'Individual') {
      setState(() => step = 2);
    } else {
      setState(() => step--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              StepProgressIndicator(currentStep: step, totalSteps: 5),
              const SizedBox(height: 40),
              CommandCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(getStepTitle(), style: const TextStyle(color: emerald, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                    const SizedBox(height: 24),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (step == 1) ...buildStep1(),
                        if (step == 2) ...buildStep2(),
                        if (step == 3) ...buildStep3(),
                        if (step == 4) ...buildStep4(),
                        if (step == 5) ...buildStep5(),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (step > 1)
                          SizedBox(width: 150, child: OutlinedButton.icon(onPressed: back, icon: const Icon(Icons.chevron_left_rounded), label: const Text('Previous')))
                        else
                          const SizedBox(width: 150),
                        SizedBox(
                          width: 180,
                          child: CyberpunkGradientButton(
                            onPressed: step == 5 ? submit : next,
                            label: step == 5 ? 'Confirm' : 'Next',
                            icon: step == 5 ? Icons.check_circle_outline : Icons.chevron_right_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String getStepTitle() => switch (step) {
    1 => 'Accident Type',
    2 => 'Scale of Incident',
    3 => 'Group Size',
    4 => 'Location',
    _ => 'Final Details (Optional)',
  };

  List<Widget> buildStep1() {
    return [
      const Text('Incident Category', style: TextStyle(color: emerald, fontSize: 16, fontWeight: FontWeight.w500)),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: panelBox(alpha: .2),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedAccidentType,
            hint: const Text('Select incident type'),
            isExpanded: true,
            dropdownColor: bg,
            items: accidentTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => selectedAccidentType = v),
          ),
        ),
      ),
    ];
  }

  List<Widget> buildStep2() {
    return ['Individual', 'Group'].map((type) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RadioListTile<String>(
        title: Text(type),
        value: type,
        groupValue: groupOrIndividual,
        onChanged: (val) => setState(() => groupOrIndividual = val),
        tileColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: groupOrIndividual == type ? green : border)),
        activeColor: green,
      ),
    )).toList();
  }

  List<Widget> buildStep3() {
    return [
      ...groupSizes.map((size) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: RadioListTile<String>(
          title: Text(size),
          value: size,
          groupValue: selectedGroupSize,
          onChanged: (val) => setState(() => selectedGroupSize = val),
          tileColor: bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: selectedGroupSize == size ? green : border)),
          activeColor: green,
        ),
      )),
      if (selectedGroupSize == 'Other') AppTextField(label: 'Enter number of people', controller: customGroupSize, hint: 'e.g. 150'),
    ];
  }

  List<Widget> buildStep4() {
    return [
      Row(
        children: [
          Expanded(
            child: GooglePlaceField(
              controller: place,
              onSelected: (suggestion) => setState(() {
                place.text = suggestion.description;
                selectedLat = suggestion.lat;
                selectedLon = suggestion.lon;
              }),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(onPressed: fetchCurrentLocation, icon: const Icon(Icons.my_location_rounded, size: 20), style: IconButton.styleFrom(backgroundColor: emerald.withValues(alpha: .1), foregroundColor: emerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
        ],
      ),
      const SizedBox(height: 12),
      const Text('The system will try to detect your location automatically. Use the icon above to re-sync.', style: TextStyle(color: Colors.white38, fontSize: 11)),
    ];
  }

  List<Widget> buildStep5() {
    return [
      AppTextField(label: 'Additional Description', controller: description, maxLines: 4, hint: 'Tell us more about the situation...'),
      if (imageBase64 != null)
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(10),
          decoration: panelBox(),
          child: Row(
            children: [
              ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(base64Decode(imageBase64!), width: 64, height: 64, fit: BoxFit.cover)),
              const SizedBox(width: 12),
              Expanded(child: Text(imageName ?? 'Attached image', overflow: TextOverflow.ellipsis)),
              IconButton(onPressed: () => setState(() { imageBase64 = null; imageName = null; }), icon: const Icon(Icons.close_rounded)),
            ],
          ),
        ),
      OutlinedButton.icon(onPressed: pickImage, icon: const Icon(Icons.add_photo_alternate_rounded), label: const Text('Attach Photo')),
    ];
  }

  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    final file = result?.files.single;
    if (file?.bytes == null) return;
    setState(() { imageBase64 = base64Encode(file!.bytes!); imageName = file.name; });
  }

  void submit() {
    if (selectedAccidentType == null || place.text.trim().isEmpty) return;
    final finalGroupInfo = groupOrIndividual == 'Group' ? 'Group Size: ${selectedGroupSize == 'Other' ? customGroupSize.text : selectedGroupSize}' : 'Individual';
    final finalDescription = 'Scale: $finalGroupInfo. ${description.text.trim()}';
    widget.store.addIncident(description: finalDescription, incidentType: selectedAccidentType!, place: place.text.trim(), lat: selectedLat, lon: selectedLon, image: imageBase64);
    setState(() { step = 1; selectedAccidentType = null; groupOrIndividual = null; selectedGroupSize = null; customGroupSize.clear(); description.clear(); place.clear(); imageBase64 = null; imageName = null; selectedLat = null; selectedLon = null; });
    widget.onChanged();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incident reported successfully'), backgroundColor: green));
  }
}

class AdminReportsView extends StatelessWidget {
  const AdminReportsView({super.key, required this.store, required this.onChanged});
  final AppStore store;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final all = store.allIncidents();
    final pending = all.where((item) => item.incident.status == 'pending').toList();
    final assigned = all.where((item) => item.incident.status == 'assigned').toList();
    final completed = all.where((item) => item.incident.status == 'completed').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Header(title: 'Incident Reports', subtitle: 'Real-time overview of all reported emergencies.'),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            Metric('Total Reports', all.length, Icons.analytics_rounded, blue),
            Metric('Pending', pending.length, Icons.pending_actions_rounded, orange),
            Metric('In Progress', assigned.length, Icons.run_circle_rounded, cyan),
            Metric('Resolved', completed.length, Icons.check_circle_rounded, green),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: all.isEmpty
              ? const EmptyState(icon: Icons.description_rounded, text: 'No incident reports found.')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: all.length,
                  itemBuilder: (_, index) {
                    final item = all[index];
                    final inc = item.incident;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: CommandCard(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(backgroundColor: statusColor(inc.status).withValues(alpha: .15), child: Icon(statusIcon(inc.status), color: statusColor(inc.status), size: 20)),
                          title: Row(
                            children: [
                              Expanded(child: Text(inc.incidentType.isEmpty ? 'General Emergency' : inc.incidentType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: statusColor(inc.status).withValues(alpha: .1), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor(inc.status).withValues(alpha: .3))),
                                child: Text(inc.status.toUpperCase(), style: TextStyle(color: statusColor(inc.status), fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(inc.description, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, size: 14, color: Colors.white38),
                                  const SizedBox(width: 4),
                                  Text(inc.place, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                  const Spacer(),
                                  Text('Reported by: ${item.user.name.isEmpty ? item.user.email : item.user.name}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                          trailing: inc.image != null ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(base64Decode(inc.image!), width: 60, height: 60, fit: BoxFit.cover)) : const SizedBox(width: 60),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  IconData statusIcon(String status) => switch (status) { 'pending' => Icons.timer_outlined, 'assigned' => Icons.local_shipping_outlined, 'completed' => Icons.check_circle_outlined, _ => Icons.error_outline };
}

class VolunteerAllotment extends StatefulWidget {
  const VolunteerAllotment({super.key, required this.store, required this.onChanged});
  final AppStore store;
  final VoidCallback onChanged;

  @override
  State<VolunteerAllotment> createState() => _VolunteerAllotmentState();
}

class _VolunteerAllotmentState extends State<VolunteerAllotment> {
  bool running = false;
  int now = DateTime.now().millisecondsSinceEpoch;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => now = DateTime.now().millisecondsSinceEpoch));
  }

  @override
  void dispose() { timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final all = widget.store.allIncidents();
    final active = all.where((item) => item.incident.status != 'completed').toList();
    final pending = all.where((item) => item.incident.status == 'pending').toList();
    final assigned = all.where((item) => item.incident.status == 'assigned').toList();
    final completed = all.where((item) => item.incident.status == 'completed').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Header(
          title: 'Resource Allotment',
          subtitle: 'Categorize incidents and assign nearest responder units.',
          action: CyberpunkGradientButton(
            onPressed: running || pending.isEmpty ? null : () => runAllotment(pending, assigned),
            icon: running ? null : Icons.bolt_rounded,
            label: running ? 'Running allotment...' : 'Run Allotment',
            orange: false,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(spacing: 12, runSpacing: 12, children: [
          _Metric('Pending', pending.length, Icons.business_center_rounded, orange),
          _Metric('Assigned', assigned.length, Icons.local_shipping_rounded, blue),
          _Metric('Completed', completed.length, Icons.check_circle_rounded, green),
          _Metric('Ambulances', resources['ambulance']!.length, Icons.ac_unit_rounded, cyan),
          _Metric('Fire/Rescue', resources['fire']!.length + resources['rescue']!.length, Icons.local_fire_department_rounded, orange),
        ]),
        const SizedBox(height: 18),
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 430,
                child: Container(
                  decoration: BoxDecoration(color: cardBg.withValues(alpha: .5), borderRadius: BorderRadius.circular(18), border: Border.all(color: border)),
                  child: active.isEmpty
                      ? const EmptyState(icon: Icons.work_rounded, text: 'No active incidents to allocate.')
                      : ListView.builder(padding: const EdgeInsets.all(16), itemCount: active.length, itemBuilder: (_, index) => _AllotmentTile(item: active[index])),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(child: GoogleMapPanel(incidents: active)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> runAllotment(List<IncidentView> pending, List<IncidentView> assigned) async {
    setState(() => running = true);
    final taken = assigned.map((item) => item.incident.responderId).whereType<String>().toSet();
    for (final item in pending) {
      final assignment = await createAssignment(item.incident, taken);
      final inc = item.incident;
      inc.status = 'assigned';
      inc.responderCategory = assignment.category;
      inc.responderType = assignment.responderType;
      inc.responderId = assignment.resource.id;
      inc.responderName = assignment.resource.name;
      inc.lat = assignment.lat; inc.lon = assignment.lon;
      inc.resourceLat = assignment.resource.lat; inc.resourceLon = assignment.resource.lon;
      inc.distanceKm = assignment.distanceKm; inc.etaMinutes = assignment.etaMinutes;
      inc.etaSeconds = assignment.etaMinutes * 60; inc.assignedAt = DateTime.now().millisecondsSinceEpoch;
      taken.add(assignment.resource.id);
    }
    await widget.store.persist();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    setState(() => running = false);
    widget.onChanged();
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.icon, this.color);
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg.withValues(alpha: .7), borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: .1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text('$value', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11))]),
        ],
      ),
    );
  }
}

class _AllotmentTile extends StatelessWidget {
  const _AllotmentTile({required this.item});
  final IncidentView item;

  @override
  Widget build(BuildContext context) {
    final inc = item.incident;
    final cat = inc.responderCategory ?? classifyLocal(inc).$1;
    final (_, color) = _vehicleStyle(cat);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg.withValues(alpha: .4), borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(inc.incidentType.isEmpty ? 'Emergency' : inc.incidentType, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: yellow.withValues(alpha: .1), borderRadius: BorderRadius.circular(8), border: Border.all(color: yellow.withValues(alpha: .2))), child: Text(inc.status, style: const TextStyle(color: yellow, fontSize: 11, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 4),
          Text(inc.description, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 10),
          Text('Location: ${inc.place}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: .2))), child: Text(inc.responderType ?? classifyLocal(inc).$2, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  (IconData, Color) _vehicleStyle(String? category) => switch (category) { 'fire' => (Icons.local_fire_department_rounded, orange), 'rescue' => (Icons.safety_check_rounded, violet), _ => (Icons.emergency_rounded, cyan) };
}

class AdminRecord extends StatelessWidget {
  const AdminRecord({super.key, required this.store, required this.onChanged});
  final AppStore store;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final all = store.allIncidents();
    final pending = all.where((item) => item.incident.status == 'pending').toList();
    final assigned = all.where((item) => item.incident.status == 'assigned').toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Header(title: 'Active Records', subtitle: 'Track pending and assigned missions.'),
        const SizedBox(height: 20),
        Expanded(
          child: Row(
            children: [
              Expanded(child: RecordColumn(title: 'Pending', icon: Icons.schedule_rounded, color: orange, items: pending)),
              const SizedBox(width: 18),
              Expanded(child: RecordColumn(title: 'Assigned', icon: Icons.local_shipping_rounded, color: blue, items: assigned, action: (item) { item.incident.status = 'completed'; item.incident.completedAt = DateTime.now().toIso8601String(); store.persist(); onChanged(); })),
            ],
          ),
        ),
      ],
    );
  }
}

class UserAllocation extends StatelessWidget {
  const UserAllocation({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final incidents = store.currentUser?.incidents ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Header(title: 'Allocation Status', subtitle: 'Track your reported requests.'),
        const SizedBox(height: 20),
        Expanded(
          child: Row(
            children: [
              Expanded(child: StatusColumn(title: 'Pending', icon: Icons.schedule_rounded, color: orange, incidents: incidents.where((item) => item.status == 'pending').toList())),
              const SizedBox(width: 16),
              Expanded(child: StatusColumn(title: 'Assigned', icon: Icons.local_shipping_rounded, color: blue, incidents: incidents.where((item) => item.status == 'assigned').toList())),
              const SizedBox(width: 16),
              Expanded(child: StatusColumn(title: 'Completed', icon: Icons.check_circle_rounded, color: green, incidents: incidents.where((item) => item.status == 'completed').toList())),
            ],
          ),
        ),
      ],
    );
  }
}

class UserRouting extends StatefulWidget {
  const UserRouting({super.key, required this.store, required this.onChanged});
  final AppStore store;
  final VoidCallback onChanged;

  @override
  State<UserRouting> createState() => _UserRoutingState();
}

class _UserRoutingState extends State<UserRouting> {
  Timer? timer;
  int now = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) { if (widget.store.completeExpiredAssignments()) widget.onChanged(); setState(() => now = DateTime.now().millisecondsSinceEpoch); });
  }

  @override
  void dispose() { timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final incidents = widget.store.currentUser?.incidents.where((item) => item.status != 'completed').toList() ?? [];
    incidents.sort((a, b) => b.date.compareTo(a.date));
    final active = incidents.firstOrNull;
    if (active == null) return const EmptyState(icon: Icons.map_rounded, text: 'No active incidents to track.');
    if (active.status != 'assigned') return AnalyzingPanel(incident: active);
    final remaining = remainingSeconds(active, now);
    final progress = ((max(1, active.etaSeconds ?? 1) - remaining) / max(1, active.etaSeconds ?? 1)).clamp(0.0, 1.0);
    return Column(
      children: [
        CommandCard(child: Row(children: [const Icon(Icons.timer_rounded, color: green), const SizedBox(width: 12), Text('${remaining ~/ 60} min ${remaining % 60} sec', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), Text(' left', style: TextStyle(color: Colors.grey.shade400))])),
        const SizedBox(height: 18),
        Expanded(child: RoutePanel(incident: active, progress: progress)),
        const SizedBox(height: 18),
        CommandCard(child: ListTile(leading: const CircleAvatar(backgroundColor: green, child: Icon(Icons.local_shipping_rounded, color: bg)), title: const Text('Responder Dispatched'), subtitle: Text('${active.responderName ?? active.responderType} | ${active.distanceKm?.toStringAsFixed(2)} km | ETA ${active.etaMinutes} min'))),
      ],
    );
  }
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, required this.title, required this.incidents});
  final String title;
  final List<IncidentView> incidents;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Header(title: title, subtitle: 'Completed incidents archive.'),
        const SizedBox(height: 20),
        Expanded(child: CommandCard(padding: EdgeInsets.zero, child: incidents.isEmpty ? const EmptyState(icon: Icons.history_rounded, text: 'No records.') : ListView.builder(itemCount: incidents.length, itemBuilder: (_, index) => IncidentTile(item: incidents[index])))),
      ],
    );
  }
}

class GoogleMapPanel extends StatefulWidget {
  const GoogleMapPanel({super.key, required this.incidents});
  final List<IncidentView> incidents;
  @override
  State<GoogleMapPanel> createState() => _GoogleMapPanelState();
}

class _GoogleMapPanelState extends State<GoogleMapPanel> {
  _HoveredPin? _hovered;
  (IconData, Color) _vehicleStyle(String? cat) => switch (cat) { 'fire' => (Icons.local_fire_department_rounded, orange), 'rescue' => (Icons.safety_check_rounded, violet), _ => (Icons.emergency_rounded, cyan) };
  ll.LatLng _mapCenter(List<IncidentView> active) {
    if (active.isEmpty) return const ll.LatLng(12.9716, 77.5946);
    double latSum = 0, lonSum = 0;
    for (final v in active) { final loc = incidentLocation(v.incident); latSum += loc.$1; lonSum += loc.$2; }
    return ll.LatLng(latSum / active.length, lonSum / active.length);
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.incidents;
    final markers = <Marker>[];
    final polylines = <Polyline>[];
    for (var i = 0; i < active.length; i++) {
      final inc = active[i].incident; final sno = i + 1; final loc = incidentLocation(inc);
      final cat = inc.responderCategory ?? classifyLocal(inc).$1; final (_, color) = _vehicleStyle(cat);
      markers.add(Marker(point: ll.LatLng(loc.$1, loc.$2), width: 36, height: 44, child: MouseRegion(cursor: SystemMouseCursors.click, onEnter: (_) => setState(() => _hovered = _HoveredPin(sno: sno, label: inc.incidentType.isEmpty ? 'Emergency' : inc.incidentType, sub: inc.place, color: color, isVehicle: false)), onExit: (_) => setState(() => _hovered = null), child: _IncidentPin(sno: sno, color: color))));
      if (inc.status == 'assigned' && inc.resourceLat != null) {
        final (icon, vColor) = _vehicleStyle(cat);
        markers.add(Marker(point: ll.LatLng(inc.resourceLat!, inc.resourceLon!), width: 42, height: 42, child: MouseRegion(onEnter: (_) => setState(() => _hovered = _HoveredPin(sno: sno, label: inc.responderName ?? 'Unit', sub: '${inc.distanceKm?.toStringAsFixed(1)} km away', color: vColor, isVehicle: true, vehicleIcon: icon)), onExit: (_) => setState(() => _hovered = null), child: _VehiclePin(icon: icon, color: vColor, sno: sno))));
        polylines.add(Polyline(points: [ll.LatLng(inc.resourceLat!, inc.resourceLon!), ll.LatLng(loc.$1, loc.$2)], color: vColor.withValues(alpha: .5), strokeWidth: 2, pattern: StrokePattern.dashed(segments: const [8, 6])));
      }
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFF10171B), border: Border.all(color: border)),
        child: Stack(
          children: [
            FlutterMap(options: MapOptions(initialCenter: _mapCenter(active), initialZoom: active.isEmpty ? 11 : 12), children: [
              TileLayer(urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', subdomains: const ['a', 'b', 'c', 'd']),
              PolylineLayer(polylines: polylines), MarkerLayer(markers: markers),
            ]),
            if (_hovered != null) Positioned(left: 12, bottom: 12, child: Container(padding: const EdgeInsets.all(12), decoration: panelBox(alpha: .97), child: Row(children: [CircleAvatar(radius: 18, backgroundColor: _hovered!.color.withValues(alpha: .2), child: _hovered!.isVehicle ? Icon(_hovered!.vehicleIcon, color: _hovered!.color, size: 18) : Text('#${_hovered!.sno}')), const SizedBox(width: 10), Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(_hovered!.label, style: const TextStyle(fontWeight: FontWeight.bold)), Text(_hovered!.sub, style: const TextStyle(fontSize: 11, color: Colors.white60))])]))),
          ],
        ),
      ),
    );
  }
}

class _HoveredPin {
  _HoveredPin({required this.sno, required this.label, required this.sub, required this.color, required this.isVehicle, this.vehicleIcon});
  final int sno; final String label, sub; final Color color; final bool isVehicle; final IconData? vehicleIcon;
}

class _IncidentPin extends StatelessWidget {
  const _IncidentPin({required this.sno, required this.color});
  final int sno; final Color color;
  @override
  Widget build(BuildContext context) { return Column(mainAxisSize: MainAxisSize.min, children: [Container(width: 28, height: 28, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), alignment: Alignment.center, child: Text('$sno', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))), CustomPaint(size: const Size(10, 6), painter: _TrianglePainter(color))]); }
}

class _VehiclePin extends StatelessWidget {
  const _VehiclePin({required this.icon, required this.color, required this.sno});
  final IconData icon; final Color color; final int sno;
  @override
  Widget build(BuildContext context) { return Stack(clipBehavior: Clip.none, children: [Container(width: 36, height: 36, decoration: BoxDecoration(color: bg, shape: BoxShape.circle, border: Border.all(color: color, width: 2.5)), child: Icon(icon, color: color, size: 18)), Positioned(top: -4, right: -4, child: Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: bg, width: 1.5)), alignment: Alignment.center, child: Text('$sno', style: const TextStyle(color: Colors.white, fontSize: 8))))]); }
}

class _TrianglePainter extends CustomPainter {
  _TrianglePainter(this.color); final Color color;
  @override void paint(Canvas canvas, Size size) { final paint = Paint()..color = color; final path = Path()..moveTo(0, 0)..lineTo(size.width, 0)..lineTo(size.width / 2, size.height)..close(); canvas.drawPath(path, paint); }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class RoutePanel extends StatelessWidget {
  const RoutePanel({super.key, required this.incident, required this.progress});
  final Incident incident; final double progress;
  @override
  Widget build(BuildContext context) {
    return CommandCard(child: LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth; final x = 70 + (width - 140) * progress;
      return Stack(children: [
        Positioned.fill(child: CustomPaint(painter: RouteBackgroundPainter())),
        Positioned(left: 70, right: 70, top: constraints.maxHeight / 2, child: Container(height: 6, decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(20)))),
        Positioned(left: 70, width: (width - 140) * progress, top: constraints.maxHeight / 2, child: Container(height: 6, decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(20)))),
        Positioned(left: 48, top: constraints.maxHeight / 2 - 20, child: const Icon(Icons.local_shipping_rounded, size: 20)),
        Positioned(right: 48, top: constraints.maxHeight / 2 - 20, child: const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 20)),
        Positioned(left: x - 20, top: constraints.maxHeight / 2 - 36, child: CircleAvatar(backgroundColor: green, radius: 18, child: Icon(Icons.local_shipping_rounded, color: bg, size: 18))),
      ]);
    }));
  }
}

class RouteBackgroundPainter extends CustomPainter {
  @override void paint(Canvas canvas, Size size) { final paint = Paint()..color = border.withValues(alpha: .2); for (double x = 0; x < size.width; x += 30) { for (double y = 0; y < size.height; y += 30) { canvas.drawCircle(Offset(x, y), 1, paint); } } }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AnalyzingPanel extends StatelessWidget {
  const AnalyzingPanel({super.key, required this.incident});
  final Incident incident;
  @override
  Widget build(BuildContext context) { return Center(child: CommandCard(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.radar_rounded, color: orange, size: 64), const SizedBox(height: 16), const Text('Analyzing...', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), Text('Criticality: ${incident.score ?? "Calculating..."}', style: TextStyle(color: Colors.grey.shade400))]))); }
}

class IncidentTile extends StatelessWidget {
  const IncidentTile({super.key, required this.item, this.now});
  final IncidentView item; final int? now;
  @override
  Widget build(BuildContext context) {
    final inc = item.incident; final remaining = remainingSeconds(inc, now);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: panelBox(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Expanded(child: Text(inc.incidentType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), Chip(label: Text(inc.status), backgroundColor: statusColor(inc.status).withValues(alpha: .15))]),
            const SizedBox(height: 6),
            Text(inc.description, style: TextStyle(color: Colors.grey.shade400)),
            const SizedBox(height: 8),
            Text('Place: ${inc.place}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
            if (inc.status == 'assigned') Padding(padding: const EdgeInsets.only(top: 10), child: Chip(label: Text('ETA ${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}'), backgroundColor: green.withValues(alpha: .1))),
          ],
        ),
      ),
    );
  }
}

class RecordColumn extends StatelessWidget {
  const RecordColumn({super.key, required this.title, required this.icon, required this.color, required this.items, this.action});
  final String title; final IconData icon; final Color color; final List<IncidentView> items; final void Function(IncidentView item)? action;
  @override
  Widget build(BuildContext context) {
    return CommandCard(padding: EdgeInsets.zero, child: Column(children: [ListTile(leading: Icon(icon, color: color), title: Text('$title (${items.length})')), const Divider(color: border, height: 1), Expanded(child: items.isEmpty ? EmptyState(icon: icon, text: 'No $title records.') : ListView.builder(itemCount: items.length, itemBuilder: (_, index) { final item = items[index]; return Column(children: [IncidentTile(item: item), if (action != null) Padding(padding: const EdgeInsets.all(12), child: OutlinedButton(onPressed: () => action!(item), child: const Text('Complete Mission')))]); }))]));
  }
}

class StatusColumn extends StatelessWidget {
  const StatusColumn({super.key, required this.title, required this.icon, required this.color, required this.incidents});
  final String title; final IconData icon; final Color color; final List<Incident> incidents;
  @override
  Widget build(BuildContext context) {
    return CommandCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(leading: Icon(icon, color: color), title: Text('$title (${incidents.length})', style: const TextStyle(fontWeight: FontWeight.bold))),
          const Divider(color: border, height: 1),
          Expanded(
            child: incidents.isEmpty
                ? EmptyState(icon: icon, text: 'None')
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: incidents.length,
                    itemBuilder: (_, index) {
                      final inc = incidents[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: bg.withValues(alpha: .3), borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          title: Text(inc.incidentType, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text(inc.place, style: const TextStyle(color: Colors.white38, fontSize: 10), maxLines: 1),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class Header extends StatelessWidget {
  const Header({super.key, required this.title, required this.subtitle, this.action});
  final String title, subtitle; final Widget? action;
  @override
  Widget build(BuildContext context) { return Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.headlineLarge), const SizedBox(height: 4), Text(subtitle, style: TextStyle(color: Colors.white38, fontSize: 14))])), if (action != null) action!]); }
}

class CommandCard extends StatefulWidget {
  const CommandCard({super.key, required this.child, this.padding = const EdgeInsets.all(24), this.glow = false});
  final Widget child; final EdgeInsets padding; final bool glow;
  @override State<CommandCard> createState() => _CommandCardState();
}

class _CommandCardState extends State<CommandCard> {
  bool isHovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true), onExit: (_) => setState(() => isHovered = false),
      child: AnimatedScale(scale: isHovered ? 1.01 : 1.0, duration: const Duration(milliseconds: 200), child: ClipRRect(borderRadius: BorderRadius.circular(18), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(padding: widget.padding, decoration: panelBox(glow: widget.glow || isHovered, alpha: isHovered ? 0.7 : 0.6), child: widget.child)))),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({super.key, required this.label, required this.controller, this.obscure = false, this.maxLines = 1, this.hint});
  final String label; final TextEditingController controller; final bool obscure; final int maxLines; final String? hint;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller, obscureText: obscure, maxLines: obscure ? 1 : maxLines, style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(labelText: label, hintText: hint, filled: true, fillColor: bg.withValues(alpha: .5), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: emerald.withValues(alpha: 0.2))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: emerald.withValues(alpha: 0.2))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: emerald, width: 1.5)), labelStyle: const TextStyle(color: Colors.grey)),
      ),
    );
  }
}

class GooglePlaceField extends StatefulWidget {
  const GooglePlaceField({super.key, required this.controller, required this.onSelected});
  final TextEditingController controller; final ValueChanged<PlaceSuggestion> onSelected;
  @override State<GooglePlaceField> createState() => _GooglePlaceFieldState();
}

class _GooglePlaceFieldState extends State<GooglePlaceField> {
  Timer? debounce; List<PlaceSuggestion> suggestions = []; bool loading = false;
  @override void dispose() { debounce?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(controller: widget.controller, onChanged: onChanged, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'Location', suffixIcon: loading ? const Padding(padding: EdgeInsets.all(12), child: SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))) : const Icon(Icons.location_on_rounded), filled: true, fillColor: bg.withValues(alpha: .5), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
      if (suggestions.isNotEmpty) Container(margin: const EdgeInsets.only(top: 4), decoration: panelBox(), constraints: const BoxConstraints(maxHeight: 200), child: ListView.builder(shrinkWrap: true, itemCount: suggestions.length, itemBuilder: (context, index) { final s = suggestions[index]; return ListTile(dense: true, title: Text(s.description), onTap: () async { var sel = s; if (s.placeId != null) sel = await fetchPlaceDetails(s) ?? s; widget.onSelected(sel); setState(() => suggestions = []); }); })),
    ]);
  }
  void onChanged(String v) { debounce?.cancel(); debounce = Timer(const Duration(milliseconds: 350), () async { if (v.length < 2) { setState(() => suggestions = []); return; } setState(() => loading = true); final r = await fetchPlaceSuggestions(v); if (!mounted) return; setState(() { suggestions = r; loading = false; }); }); }
}

Future<List<PlaceSuggestion>> fetchPlaceSuggestions(String query) async {
  try {
    final response = await http.get(Uri.parse('$backendBaseUrl/api/google/places/autocomplete?q=$query')).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) { final p = jsonDecode(response.body)['predictions'] as List? ?? []; return p.map((i) => PlaceSuggestion(description: i['description'] ?? '', placeId: i['place_id'])).toList(); }
  } catch (_) {}
  return places.entries.where((e) => e.key.contains(query.toLowerCase())).map((e) => PlaceSuggestion(description: '${e.key}, Bangalore', lat: e.value.$1, lon: e.value.$2)).toList();
}

Future<PlaceSuggestion?> fetchPlaceDetails(PlaceSuggestion s) async {
  try {
    final response = await http.get(Uri.parse('$backendBaseUrl/api/google/places/details?place_id=${s.placeId}')).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) { final d = jsonDecode(response.body); return PlaceSuggestion(description: d['formatted_address'] ?? s.description, placeId: s.placeId, lat: asDouble(d['lat']), lon: asDouble(d['lon'])); }
  } catch (_) {} return null;
}

class AlertBox extends StatelessWidget {
  const AlertBox({super.key, required this.text, required this.color});
  final String text; final Color color;
  @override Widget build(BuildContext context) { return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: .1), border: Border.all(color: color.withValues(alpha: .3)), borderRadius: BorderRadius.circular(8)), child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: color))); }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.text});
  final IconData icon; final String text;
  @override Widget build(BuildContext context) { return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 42, color: Colors.white24), const SizedBox(height: 8), Text(text, style: const TextStyle(color: Colors.white24))])); }
}

class Metric extends StatelessWidget {
  const Metric(this.label, this.value, this.icon, this.color, {super.key});
  final String label; final dynamic value; final IconData icon; final Color color;
  @override Widget build(BuildContext context) { return Container(width: 180, child: CommandCard(padding: const EdgeInsets.all(20), glow: color == emerald, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color, size: 20), const SizedBox(height: 12), Text(value.toString(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))]))); }
}

BoxDecoration panelBox({double alpha = 0.6, bool glow = false}) {
  return BoxDecoration(color: cardBg.withValues(alpha: alpha), border: Border.all(color: border), borderRadius: BorderRadius.circular(18), boxShadow: [if (glow) BoxShadow(color: emerald.withValues(alpha: 0.1), blurRadius: 20)]);
}

class CyberpunkBackground extends StatelessWidget {
  const CyberpunkBackground({super.key});
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [panel, bg]))),
      CustomPaint(painter: GridOverlayPainter(emerald.withValues(alpha: .03)), size: Size.infinite),
    ]);
  }
}

class GridOverlayPainter extends CustomPainter {
  GridOverlayPainter(this.color); final Color color;
  @override void paint(Canvas canvas, Size size) { final paint = Paint()..color = color..strokeWidth = 1; for (double i = 0; i < size.width; i += 40) { canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint); } for (double i = 0; i < size.height; i += 40) { canvas.drawLine(Offset(0, i), Offset(size.width, i), paint); } }
  @override bool shouldRepaint(CustomPainter old) => false;
}

class CyberpunkGradientButton extends StatelessWidget {
  const CyberpunkGradientButton({super.key, required this.onPressed, required this.label, this.icon, this.orange = false});
  final VoidCallback? onPressed; final String label; final IconData? icon; final bool orange;
  @override
  Widget build(BuildContext context) {
    final color = orange ? neonOrange : emerald;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      onPressed: onPressed,
      child: Ink(decoration: BoxDecoration(gradient: LinearGradient(colors: onPressed == null ? [Colors.grey.withValues(alpha: .2), Colors.grey.withValues(alpha: .2)] : [color, color.withValues(alpha: .8)]), borderRadius: BorderRadius.circular(12)), child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), child: Row(mainAxisSize: MainAxisSize.min, children: [if (icon != null) ...[Icon(icon, color: bg, size: 18), const SizedBox(width: 8)], Text(label, style: const TextStyle(color: bg, fontWeight: FontWeight.bold))]))),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.store, required this.onChanged});
  final AppStore store; final VoidCallback onChanged;
  @override State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true; final email = TextEditingController(), password = TextEditingController(), name = TextEditingController(); String role = 'user'; bool loading = false; String? error;
  void submit() async { setState(() { loading = true; error = null; }); final res = isLogin ? await widget.store.login(email.text, password.text) : await widget.store.signup(email: email.text, password: password.text, name: name.text, role: role); if (!mounted) return; if (res == null) widget.onChanged(); else setState(() { error = res; loading = false; }); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Stack(children: [const CyberpunkBackground(), Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: CommandCard(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [const Icon(Icons.shield_rounded, color: emerald, size: 48), const SizedBox(height: 24), Text(isLogin ? 'WELCOME BACK' : 'CREATE ACCOUNT', textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 32), if (!isLogin) AppTextField(label: 'Full Name', controller: name), AppTextField(label: 'Email Address', controller: email), AppTextField(label: 'Password', controller: password, obscure: true), if (!isLogin) ...[const Text('Role', style: TextStyle(color: Colors.grey)), Row(children: [Expanded(child: RadioListTile(title: const Text('User'), value: 'user', groupValue: role, onChanged: (v) => setState(() => role = v!))), Expanded(child: RadioListTile(title: const Text('Admin'), value: 'admin', groupValue: role, onChanged: (v) => setState(() => role = v!)))])], if (error != null) AlertBox(text: error!, color: Colors.redAccent), const SizedBox(height: 16), CyberpunkGradientButton(onPressed: loading ? null : submit, label: isLogin ? 'LOGIN' : 'SIGN UP'), TextButton(onPressed: () => setState(() => isLogin = !isLogin), child: Text(isLogin ? "Don't have an account? Sign Up" : "Have an account? Login", style: const TextStyle(color: emerald)))]))))]));
  }
}

final resources = <String, List<ResourceUnit>>{
  'ambulance': const [ResourceUnit('AMB_001', 'Victoria Hospital', 12.9635, 77.5739), ResourceUnit('AMB_002', 'Manipal Hospital', 12.9582, 77.6484), ResourceUnit('AMB_003', 'St. Johns', 12.9294, 77.6187), ResourceUnit('AMB_004', 'Aster CMI', 13.0545, 77.5928), ResourceUnit('AMB_005', 'Fortis Hospital', 12.8958, 77.5996)],
  'fire': const [ResourceUnit('FIRE_001', 'High Grounds Fire', 12.9866, 77.5938), ResourceUnit('FIRE_002', 'Indiranagar Fire', 12.9784, 77.6408), ResourceUnit('FIRE_003', 'Jayanagar Fire', 12.9257, 77.5930), ResourceUnit('FIRE_004', 'Whitefield Fire', 12.9698, 77.7500), ResourceUnit('FIRE_005', 'Yeshwanthpur Fire', 13.0285, 77.5409)],
  'rescue': const [ResourceUnit('RES_001', 'Central Rescue', 12.9767, 77.5993), ResourceUnit('RES_002', 'East Zone Rescue', 12.9719, 77.6412), ResourceUnit('RES_003', 'South Zone Rescue', 12.9166, 77.6101), ResourceUnit('RES_004', 'North Zone Rescue', 13.0358, 77.5970)],
};

final places = <String, (double, double)>{'mg road': (12.9756, 77.6068), 'indiranagar': (12.9784, 77.6408), 'koramangala': (12.9352, 77.6245), 'whitefield': (12.9698, 77.7500), 'jayanagar': (12.9250, 77.5938), 'majestic': (12.9767, 77.5713), 'hebbal': (13.0358, 77.5970), 'yeshwanthpur': (13.0285, 77.5409), 'electronic city': (12.8452, 77.6602)};

Future<Assignment> createAssignment(Incident inc, Set<String> taken) async {
  final classified = classifyLocal(inc); final loc = incidentLocation(inc); final pool = resources[classified.$1]!;
  final available = pool.where((u) => !taken.contains(u.id)).toList();
  final ranked = (available.isEmpty ? pool : available).map((u) => (unit: u, distance: haversine(loc.$1, loc.$2, u.lat, u.lon))).toList()..sort((a, b) => a.distance.compareTo(b.distance));
  final best = ranked.first; final eta = max(1, ((best.distance / 40) * 60).round());
  return Assignment(category: classified.$1, responderType: classified.$2, resource: best.unit, lat: loc.$1, lon: loc.$2, distanceKm: double.parse(best.distance.toStringAsFixed(2)), etaMinutes: eta);
}

(String, String) classifyLocal(Incident inc) {
  final t = '${inc.incidentType} ${inc.description}'.toLowerCase();
  
  // Rescue team priority: Group scale incidents or explicit rescue keywords
  if (t.contains('scale: group') || RegExp(r'collapse|trapped|rescue|flood|drowning|stuck').hasMatch(t)) {
    return ('rescue', 'Rescue Team');
  }
  
  if (RegExp(r'fire|burn|smoke|flame|blast|explosion').hasMatch(t)) {
    return ('fire', 'Fire Engine');
  }
  
  return ('ambulance', 'Ambulance');
}

(double, double) incidentLocation(Incident inc) {
  if (inc.lat != null) return (inc.lat!, inc.lon!); final p = inc.place.toLowerCase();
  for (final e in places.entries) { if (p.contains(e.key)) return e.value; }
  return (12.9716, 77.5946);
}

double haversine(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0; final dlat = radians(lat2 - lat1), dlon = radians(lon2 - lon1);
  final a = pow(sin(dlat / 2), 2) + cos(radians(lat1)) * cos(radians(lat2)) * pow(sin(dlon / 2), 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}
double radians(double v) => v * pi / 180;
int remainingSeconds(Incident inc, [int? now]) { if (inc.status != 'assigned' || inc.assignedAt == null) return 0; return max(0, (inc.etaSeconds ?? 0) - (((now ?? DateTime.now().millisecondsSinceEpoch) - inc.assignedAt!) ~/ 1000)); }
Color statusColor(String s) => switch (s) { 'assigned' => blue, 'completed' => green, _ => yellow };
int? asInt(dynamic v) => v == null ? null : int.tryParse('$v');
double? asDouble(dynamic v) => v == null ? null : double.tryParse('$v');