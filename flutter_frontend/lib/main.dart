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

const Color bg = Color(0xFF0A0E1A);
const Color cardBg = Color(0xFF0F172A);
const Color emerald = Color(0xFF10B981);
const Color emeraldBorder = Color(0x3310B981);
const Color neonOrange = Color(0xFFF97316);
const Color slateText = Color(0xFFE0E6ED);
const Color blue = Color(0xFF3B82F6);
const Color cyan = Color(0xFF06B6D4);
const Color violet = Color(0xFF8B5CF6);
const Color orange = Color(0xFFF59E0B);
const Color green = emerald;
const Color yellow = Color(0xFFFFD60A);
const Color border = Color(0xFF1E293B);

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
    bg: Color(0xFF0A0E1A),
    bg2: Color(0xFF0F172A),
    card: Color(0x990F172A),
    border: Color(0x3310B981),
    text: Color(0xFFE0E6ED),
    primary: Color(0xFF10B981),
    secondary: Color(0xFFF97316),
    shadow: Color(0x1A10B981),
    grid: Color(0x0D10B981),
  );

  static const light = AppTheme(
    bg: Color(0xFFFAFBFB), // Base
    bg2: Color(0xFFE2E8F0), // Secondary background
    card: Color(0xD9FFFFFF), // rgba(255,255,255,0.85)
    border: Color(0x4094A3B8), // rgba(148,163,184,0.25)
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
    for (var item in all) {
      final id = item.incident.id;
      final status = item.incident.status;
      
      if (_lastStatus.containsKey(id)) {
        if (_lastStatus[id] != status) {
          if (currentUser?.role == 'user' && status == 'assigned' && item.user.id == currentUser?.id) {
            addNotification('Incident Assigned', 'Your report for ${item.incident.incidentType} has been assigned a responder.');
            changed = true;
          }
        }
      }
      _lastStatus[id] = status;
    }
    
    // Check for new reports for Admin
    if (currentUser?.role == 'admin') {
      final newItems = all.where((i) => !_lastStatus.containsKey(i.incident.id)).toList();
      if (newItems.isNotEmpty) {
        addNotification('New Report', '${newItems.length} new emergency report(s) received.');
        changed = true;
        for (var i in newItems) {
          _lastStatus[i.incident.id] = i.incident.status;
        }
      }
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

  void addIncident({required String description, required String incidentType, required String place, double? lat, double? lon, String? image}) {
    final user = currentUser;
    if (user == null) return;
    user.incidents.add(Incident(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      description: description,
      incidentType: incidentType,
      place: place,
      lat: lat,
      lon: lon,
      image: image,
      date: DateTime.now().toIso8601String(),
    ));
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

  void updateIncident(Incident incident) {
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
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: Row(
                        children: [
                          Icon(Icons.stars_rounded, color: green, size: 24),
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
                              const CircleAvatar(radius: 16, backgroundColor: green, child: Text('S', style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 12))),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user.name.isEmpty ? 'Span' : user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
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
                    // Top Bar
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
                                onPressed: () {
                                  // Show notifications
                                },
                              ),
                              if (widget.store.notifications.isNotEmpty)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    child: Text('${widget.store.notifications.length}', style: const TextStyle(fontSize: 10, color: Colors.white)),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
                            onPressed: () {},
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

class NavItem {
  const NavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.store, required this.onChanged});
  final AppStore store;
  final VoidCallback onChanged;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool login = true;
  String role = 'user';
  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();
  final referral = TextEditingController();
  String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: CommandCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.local_activity_rounded, color: green, size: 48),
                const SizedBox(height: 14),
                Text(login ? 'LOGIN TO COMMAND' : 'JOIN COMMAND', textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                if (error != null) ...[
                  const SizedBox(height: 16),
                  AlertBox(text: error!, color: Colors.redAccent),
                ],
                const SizedBox(height: 20),
                if (!login) AppTextField(label: 'Full Name', controller: name),
                AppTextField(label: 'Email Address', controller: email),
                AppTextField(label: 'Password', controller: password, obscure: true),
                if (!login) ...[
                  const SizedBox(height: 10),
                  SegmentedButton<String>(
                    segments: const [ButtonSegment(value: 'user', label: Text('User')), ButtonSegment(value: 'volunteer', label: Text('Volunteer'))],
                    selected: {role},
                    onSelectionChanged: (value) => setState(() => role = value.first),
                  ),
                ],
                if (!login && role == 'volunteer') AppTextField(label: 'Referral Code', controller: referral),
                const SizedBox(height: 18),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: green, foregroundColor: bg, padding: const EdgeInsets.all(16)),
                  onPressed: submit,
                  child: Text(login ? 'Sign In' : 'Create Account', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    login = !login;
                    error = null;
                  }),
                  child: Text(login ? "Don't have an account? Sign up" : 'Already have an account? Log in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void submit() async {
    setState(() => error = null);
    
    if (!login && role == 'volunteer' && referral.text != 'qwerty') {
      setState(() => error = 'Invalid referral code for volunteer');
      return;
    }

    final message = login
        ? await widget.store.login(email.text.trim(), password.text)
        : await widget.store.signup(
            email: email.text.trim(), 
            password: password.text, 
            name: name.text.trim(), 
            role: role
          );

    if (message != null) {
      setState(() => error = message);
    } else {
      widget.onChanged();
    }
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
  
  // MCQ Selections
  String? selectedAccidentType;
  String selectedSeverity = 'Low';
  String? groupOrIndividual;
  String? selectedGroupSize;
  final customGroupSize = TextEditingController();
  
  // Existing fields
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

  void next() {
    if (step == 1 && selectedAccidentType == null) return;
    if (step == 2 && groupOrIndividual == null) return;
    if (step == 2 && groupOrIndividual == 'Individual') {
      setState(() => step = 4); // Skip group size step
      return;
    }
    if (step == 3) {
      if (selectedGroupSize == null) return;
      if (selectedGroupSize == 'Other' && customGroupSize.text.trim().isEmpty) return;
    }
    if (step == 4 && place.text.trim().isEmpty) return;
    
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850),
        child: Column(
          children: [
            const SizedBox(height: 20),
            StepProgressIndicator(currentStep: step, totalSteps: 5),
            const SizedBox(height: 40),
            Expanded(
              child: CommandCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(getStepTitle(), style: const TextStyle(color: emerald, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                    const SizedBox(height: 24),
                    
                    // Step Content
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (step == 1) ...buildStep1(),
                            if (step == 2) ...buildStep2(),
                            if (step == 3) ...buildStep3(),
                            if (step == 4) ...buildStep4(),
                            if (step == 5) ...buildStep5(),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (step > 1)
                          SizedBox(
                            width: 150,
                            child: OutlinedButton.icon(
                              onPressed: back,
                              icon: const Icon(Icons.chevron_left_rounded),
                              label: const Text('Previous'),
                            ),
                          )
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
            ),
          ],
        ),
      ),
    );
  }

  IconData getStepIcon() {
    return switch (step) {
      1 => Icons.warning_amber_rounded,
      2 => Icons.people_outline_rounded,
      3 => Icons.groups_rounded,
      4 => Icons.location_on_rounded,
      _ => Icons.description_rounded,
    };
  }

  String getStepTitle() {
    return switch (step) {
      1 => 'Accident Type',
      2 => 'Scale of Incident',
      3 => 'Group Size',
      4 => 'Location',
      _ => 'Final Details (Optional)',
    };
  }

  String getStepSubtitle() {
    return switch (step) {
      1 => 'What type of emergency are you reporting?',
      2 => 'Is this affecting an individual or a group?',
      3 => 'Estimate how many people are involved.',
      4 => 'Where did this happen?',
      _ => 'Add any additional context or photos.',
    };
  }

  List<Widget> buildStep1() {
    return [
      const Text('Severity Level', style: TextStyle(color: neonOrange, fontSize: 16, fontWeight: FontWeight.w500)),
      const SizedBox(height: 16),
      Row(
        children: ['Low', 'Medium', 'Critical'].map((level) {
          final active = selectedSeverity == level;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: active ? emerald.withValues(alpha: .1) : Colors.transparent,
                  side: BorderSide(color: active ? emerald : emerald.withValues(alpha: .1)),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
                onPressed: () => setState(() => selectedSeverity = level),
                child: Text(level, style: TextStyle(color: active ? Colors.white : Colors.grey)),
              ),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 32),
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
      if (selectedGroupSize == 'Other')
        AppTextField(label: 'Enter number of people', controller: customGroupSize, hint: 'e.g. 150'),
    ];
  }

  List<Widget> buildStep4() {
    return [
      GooglePlaceField(
        controller: place,
        onSelected: (suggestion) => setState(() {
          place.text = suggestion.description;
          selectedLat = suggestion.lat;
          selectedLon = suggestion.lon;
        }),
      ),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(base64Decode(imageBase64!), width: 64, height: 64, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(imageName ?? 'Attached image', overflow: TextOverflow.ellipsis)),
              IconButton(
                onPressed: () => setState(() {
                  imageBase64 = null;
                  imageName = null;
                }),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
      OutlinedButton.icon(
        onPressed: pickImage,
        icon: const Icon(Icons.add_photo_alternate_rounded),
        label: const Text('Attach Photo'),
      ),
    ];
  }

  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    final file = result?.files.single;
    if (file?.bytes == null) return;
    setState(() {
      imageBase64 = base64Encode(file!.bytes!);
      imageName = file.name;
    });
  }

  void submit() {
    if (selectedAccidentType == null || place.text.trim().isEmpty) return;

    final finalGroupInfo = groupOrIndividual == 'Group' 
        ? 'Group Size: ${selectedGroupSize == 'Other' ? customGroupSize.text : selectedGroupSize}'
        : 'Individual';
    
    final finalDescription = 'Scale: $finalGroupInfo. ${description.text.trim()}';

    widget.store.addIncident(
      description: finalDescription,
      incidentType: selectedAccidentType!,
      place: place.text.trim(),
      lat: selectedLat,
      lon: selectedLon,
      image: imageBase64,
    );

    // Reset state
    setState(() {
      step = 1;
      selectedAccidentType = null;
      selectedSeverity = 'Low';
      groupOrIndividual = null;
      selectedGroupSize = null;
      customGroupSize.clear();
      description.clear();
      place.clear();
      imageBase64 = null;
      imageName = null;
      selectedLat = null;
      selectedLon = null;
    });

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
        const Header(title: 'Incident Reports', subtitle: 'Real-time overview of all reported emergencies and their current status.'),
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
          child: CommandCard(
            padding: EdgeInsets.zero,
            child: all.isEmpty
                ? const EmptyState(icon: Icons.description_rounded, text: 'No incident reports found.')
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: all.length,
                    itemBuilder: (_, index) {
                      final item = all[index];
                      final inc = item.incident;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: bg.withValues(alpha: .3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: border),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: statusColor(inc.status).withValues(alpha: .15),
                            child: Icon(statusIcon(inc.status), color: statusColor(inc.status), size: 20),
                          ),
                          title: Row(
                            children: [
                              Text(inc.incidentType.isEmpty ? 'General Emergency' : inc.incidentType, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: statusColor(inc.status).withValues(alpha: .1), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor(inc.status).withValues(alpha: .3))),
                                child: Text(inc.status.toUpperCase(), style: TextStyle(color: statusColor(inc.status), fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(inc.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, size: 12, color: Colors.white38),
                                  const SizedBox(width: 4),
                                  Text(inc.place, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                  const Spacer(),
                                  Text('Reported by: ${item.user.name.isEmpty ? item.user.email : item.user.name}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                          trailing: inc.image != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(base64Decode(inc.image!), width: 50, height: 50, fit: BoxFit.cover),
                                )
                              : const SizedBox(width: 50),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  IconData statusIcon(String status) => switch (status) {
        'pending' => Icons.timer_outlined,
        'assigned' => Icons.local_shipping_outlined,
        'completed' => Icons.check_circle_outlined,
        _ => Icons.error_outline,
      };
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
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

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
          subtitle: 'Run once to categorize incidents and assign nearest Google-ready responder units.',
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
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: active.length,
                          itemBuilder: (_, index) => _AllotmentTile(item: active[index]),
                        ),
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
      inc.lat = assignment.lat;
      inc.lon = assignment.lon;
      inc.resourceLat = assignment.resource.lat;
      inc.resourceLon = assignment.resource.lon;
      inc.distanceKm = assignment.distanceKm;
      inc.etaMinutes = assignment.etaMinutes;
      inc.etaSeconds = assignment.etaMinutes * 60;
      inc.assignedAt = DateTime.now().millisecondsSinceEpoch;
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: .1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$value', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  inc.incidentType.isEmpty ? 'Emergency' : inc.incidentType,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: yellow.withValues(alpha: .1), borderRadius: BorderRadius.circular(8), border: Border.all(color: yellow.withValues(alpha: .2))),
                child: Text(inc.status, style: const TextStyle(color: yellow, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(inc.description, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 10),
          Text('User: ${item.user.name.isEmpty ? "spa" : item.user.name}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
          Text('Location: ${inc.place}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: .2))),
            child: Text(inc.responderType ?? classifyLocal(inc).$2, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  (IconData, Color) _vehicleStyle(String? category) => switch (category) {
        'fire'   => (Icons.local_fire_department_rounded, orange),
        'rescue' => (Icons.safety_check_rounded, violet),
        _        => (Icons.emergency_rounded, cyan),
      };
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
              Expanded(
                child: RecordColumn(
                  title: 'Assigned & En Route',
                  icon: Icons.local_shipping_rounded,
                  color: blue,
                  items: assigned,
                  action: (item) {
                    item.incident.status = 'completed';
                    item.incident.completedAt = DateTime.now().toIso8601String();
                    store.persist();
                    onChanged();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
class ResourceAllocationDashboard extends StatelessWidget {
  const ResourceAllocationDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Header(title: 'Resource Allocation', subtitle: 'Global distribution of emergency units across the network.'),
        const SizedBox(height: 20),
        Expanded(
          child: Row(
            children: [
              Expanded(child: ResourceList(category: 'ambulance', icon: Icons.emergency_rounded, color: cyan)),
              const SizedBox(width: 18),
              Expanded(child: ResourceList(category: 'fire', icon: Icons.local_fire_department_rounded, color: orange)),
              const SizedBox(width: 18),
              Expanded(child: ResourceList(category: 'rescue', icon: Icons.health_and_safety_rounded, color: violet)),
            ],
          ),
        ),
      ],
    );
  }
}

class ResourceList extends StatelessWidget {
  const ResourceList({super.key, required this.category, required this.icon, required this.color});
  final String category;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final list = resources[category] ?? [];
    return CommandCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(leading: Icon(icon, color: color), title: Text('${category.toUpperCase()} (${list.length})', style: const TextStyle(fontWeight: FontWeight.bold))),
          Divider(color: Theme.of(context).dividerColor, height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                final res = list[index];
                return ListTile(
                  title: Text(res.name),
                  subtitle: Text('ID: ${res.id}'),
                  trailing: const PulseDot(color: emerald),
                );
              },
            ),
          ),
        ],
      ),
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
        const Header(title: 'Resource Allocation Status', subtitle: 'Pending, assigned, and completed requests.'),
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
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (widget.store.completeExpiredAssignments()) widget.onChanged();
      setState(() => now = DateTime.now().millisecondsSinceEpoch);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final incidents = widget.store.currentUser?.incidents.where((item) => item.status != 'completed').toList() ?? [];
    incidents.sort((a, b) => b.date.compareTo(a.date));
    final active = incidents.firstOrNull;
    if (active == null) return const EmptyState(icon: Icons.map_rounded, text: 'No active incidents to track.');
    if (active.status != 'assigned') return AnalyzingPanel(incident: active);

    final remaining = remainingSeconds(active, now);
    final total = max(1, active.etaSeconds ?? 1);
    final progress = ((total - remaining) / total).clamp(0.0, 1.0);
    return Column(
      children: [
        CommandCard(
          child: Row(
            children: [
              const Icon(Icons.timer_rounded, color: green),
              const SizedBox(width: 12),
              Text('${remaining ~/ 60} min ${remaining % 60} sec', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(' left to reach destination', style: TextStyle(color: Colors.grey.shade400)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Expanded(child: RoutePanel(incident: active, progress: progress)),
        const SizedBox(height: 18),
        CommandCard(
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: green, child: Icon(Icons.local_shipping_rounded, color: bg)),
            title: const Text('Responder Unit Dispatched'),
            subtitle: Text('${active.responderName ?? active.responderType ?? 'Emergency Unit'} | ${active.distanceKm?.toStringAsFixed(2) ?? '--'} km | ETA ${active.etaMinutes ?? '--'} min'),
            trailing: const Text('En Route', style: TextStyle(color: green, fontWeight: FontWeight.bold)),
          ),
        ),
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
        Header(title: title, subtitle: 'Completed incidents are archived here.'),
        const SizedBox(height: 20),
        Expanded(
          child: CommandCard(
            padding: EdgeInsets.zero,
            child: incidents.isEmpty
                ? const EmptyState(icon: Icons.history_rounded, text: 'No completed incidents yet.')
                : ListView.builder(itemCount: incidents.length, itemBuilder: (_, index) => IncidentTile(item: incidents[index])),
          ),
        ),
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

  static (IconData, Color) _vehicleStyle(String? category) => switch (category) {
        'fire'   => (Icons.local_fire_department_rounded, orange),
        'rescue' => (Icons.safety_check_rounded, violet),
        _        => (Icons.emergency_rounded, cyan),
      };

  static ll.LatLng _mapCenter(List<IncidentView> active) {
    if (active.isEmpty) return const ll.LatLng(12.9716, 77.5946);
    double latSum = 0, lonSum = 0;
    for (final v in active) {
      final loc = incidentLocation(v.incident);
      latSum += loc.$1;
      lonSum += loc.$2;
    }
    return ll.LatLng(latSum / active.length, lonSum / active.length);
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.incidents;

    final markers = <Marker>[];
    for (var i = 0; i < active.length; i++) {
      final item = active[i];
      final inc  = item.incident;
      final sno  = i + 1;
      final cat  = inc.responderCategory ?? classifyLocal(inc).$1;
      final (_, incColor) = _vehicleStyle(cat);
      final loc = incidentLocation(inc);

      markers.add(Marker(
        point: ll.LatLng(loc.$1, loc.$2),
        width: 36,
        height: 44,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = _HoveredPin(
            sno: sno,
            label: inc.incidentType.isEmpty ? 'Emergency' : inc.incidentType,
            sub: 'Location • ${inc.place}',
            color: incColor,
            isVehicle: false,
          )),
          onExit:  (_) => setState(() => _hovered = null),
          child: _IncidentPin(sno: sno, color: incColor),
        ),
      ));

      if (inc.status == 'assigned' && inc.resourceLat != null && inc.resourceLon != null) {
        final (icon, vColor) = _vehicleStyle(cat);
        markers.add(Marker(
          point: ll.LatLng(inc.resourceLat!, inc.resourceLon!),
          width: 42,
          height: 42,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovered = _HoveredPin(
              sno: sno,
              label: inc.responderName ?? inc.responderType ?? 'Unit',
              sub: 'Responding to incident #$sno • ${inc.distanceKm?.toStringAsFixed(1) ?? "--"} km',
              color: vColor,
              isVehicle: true,
              vehicleIcon: icon,
            )),
            onExit: (_) => setState(() => _hovered = null),
            child: _VehiclePin(icon: icon, color: vColor, sno: sno),
          ),
        ));
      }
    }

    final polylines = <Polyline>[];
    for (final item in active) {
      final inc = item.incident;
      if (inc.status == 'assigned' && inc.resourceLat != null && inc.resourceLon != null) {
        final loc = incidentLocation(inc);
        final cat = inc.responderCategory ?? classifyLocal(inc).$1;
        final (_, lColor) = _vehicleStyle(cat);
        polylines.add(Polyline(
          points: [
            ll.LatLng(inc.resourceLat!, inc.resourceLon!),
            ll.LatLng(loc.$1, loc.$2),
          ],
          color: lColor.withValues(alpha: .55),
          strokeWidth: 2.5,
          pattern: StrokePattern.dashed(segments: const [8, 6]),
        ));
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF10171B),
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: _mapCenter(active),
                initialZoom: active.isEmpty ? 11 : 12,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  tileBuilder: (context, tileWidget, tile) {
                    return ColorFiltered(
                      colorFilter: const ColorFilter.matrix([
                        0.72, 0,    0,    0, 0,
                        0,    0.76, 0,    0, 0,
                        0,    0,    0.82, 0, 0,
                        0,    0,    0,    1, 0,
                      ]),
                      child: tileWidget,
                    );
                  },
                ),
                PolylineLayer(polylines: polylines),
                MarkerLayer(markers: markers),
              ],
            ),
            Positioned(
              left: 12, top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: panelBox(alpha: .93),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.my_location_rounded, color: green, size: 15),
                    SizedBox(width: 8),
                    Text('Live Dispatch Map', style: TextStyle(color: green, fontWeight: FontWeight.bold, fontSize: 13)),
                    SizedBox(width: 6),
                    Text('• OpenStreetMap', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 12, bottom: 12,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: panelBox(alpha: .93),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LegendRow(icon: Icons.location_on_rounded, color: cyan, label: 'Incident site'),
                    _LegendRow(icon: Icons.emergency_rounded, color: cyan, label: 'Ambulance'),
                    _LegendRow(icon: Icons.local_fire_department_rounded, color: orange, label: 'Fire Engine'),
                    _LegendRow(icon: Icons.safety_check_rounded, color: violet, label: 'Rescue Team'),
                  ],
                ),
              ),
            ),
            if (_hovered != null)
              Positioned(
                left: 12, bottom: 12,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 240),
                  padding: const EdgeInsets.all(12),
                  decoration: panelBox(alpha: .97),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: _hovered!.color.withValues(alpha: .2),
                        child: _hovered!.isVehicle
                            ? Icon(_hovered!.vehicleIcon, color: _hovered!.color, size: 18)
                            : Text('#${_hovered!.sno}', style: TextStyle(color: _hovered!.color, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_hovered!.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(_hovered!.sub,   style: const TextStyle(color: Colors.white60, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (active.isEmpty)
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_outlined, size: 46, color: Colors.white24),
                    SizedBox(height: 10),
                    Text('No active incidents on map', style: TextStyle(color: Colors.white38)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HoveredPin {
  _HoveredPin({required this.sno, required this.label, required this.sub, required this.color, required this.isVehicle, this.vehicleIcon});
  final int sno;
  final String label;
  final String sub;
  final Color color;
  final bool isVehicle;
  final IconData? vehicleIcon;
}

class _IncidentPin extends StatelessWidget {
  const _IncidentPin({required this.sno, required this.color});
  final int sno;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: color.withValues(alpha: .5), blurRadius: 6, spreadRadius: 1)]),
          alignment: Alignment.center,
          child: Text('$sno', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        CustomPaint(size: const Size(10, 6), painter: _TrianglePainter(color)),
      ],
    );
  }
}

class _VehiclePin extends StatelessWidget {
  const _VehiclePin({required this.icon, required this.color, required this.sno});
  final IconData icon;
  final Color color;
  final int sno;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: const Color(0xFF0A0E1A), shape: BoxShape.circle, border: Border.all(color: color, width: 2.5), boxShadow: [BoxShadow(color: color.withValues(alpha: .4), blurRadius: 8)]),
          child: Icon(icon, color: color, size: 18),
        ),
        Positioned(
          top: -4, right: -4,
          child: Container(
            width: 16, height: 16,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF0A0E1A), width: 1.5)),
            alignment: Alignment.center,
            child: Text('$sno', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  _TrianglePainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()..moveTo(0, 0)..lineTo(size.width, 0)..lineTo(size.width / 2, size.height)..close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.icon, required this.color, required this.label});
  final IconData icon;
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}

class RoutePanel extends StatelessWidget {
  const RoutePanel({super.key, required this.incident, required this.progress});
  final Incident incident;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return CommandCard(
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final x = 70 + (width - 140) * progress;
        return Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: RouteBackgroundPainter())),
            Positioned(left: 70, right: 70, top: constraints.maxHeight / 2, child: Container(height: 7, decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(20)))),
            Positioned(left: 70, width: (width - 140) * progress, top: constraints.maxHeight / 2, child: Container(height: 7, decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(20)))),
            Positioned(left: 48, top: constraints.maxHeight / 2 - 20, child: const Column(children: [Icon(Icons.local_shipping_rounded), Text('Dispatch', style: TextStyle(fontSize: 12, color: Colors.white60))])),
            Positioned(right: 48, top: constraints.maxHeight / 2 - 20, child: const Column(children: [Icon(Icons.location_on_rounded, color: Colors.redAccent), Text('You', style: TextStyle(fontSize: 12, color: Colors.white60))])),
            Positioned(left: x - 24, top: constraints.maxHeight / 2 - 38, child: Column(children: [CircleAvatar(backgroundColor: green, child: Icon(Icons.local_shipping_rounded, color: bg)), const SizedBox(height: 8), Text(incident.responderType ?? 'Unit', style: const TextStyle(fontSize: 12))])),
          ],
        );
      }),
    );
  }
}

class RouteBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = border.withValues(alpha: .25);
    for (double x = 0; x < size.width; x += 30) {
      for (double y = 0; y < size.height; y += 30) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AnalyzingPanel extends StatelessWidget {
  const AnalyzingPanel({super.key, required this.incident});
  final Incident incident;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CommandCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.radar_rounded, color: orange, size: 72),
            const SizedBox(height: 18),
            const Text('Analyzing Request', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Waiting for volunteer allotment...', style: TextStyle(color: Colors.grey.shade400)),
            const SizedBox(height: 22),
            Chip(label: Text('Criticality ${incident.score ?? '--'}'), backgroundColor: orange.withValues(alpha: .15)),
          ],
        ),
      ),
    );
  }
}

class IncidentTile extends StatelessWidget {
  const IncidentTile({super.key, required this.item, this.now});
  final IncidentView item;
  final int? now;

  @override
  Widget build(BuildContext context) {
    final inc = item.incident;
    final classified = classifyLocal(inc);
    final remaining = remainingSeconds(inc, now);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: panelBox(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(inc.incidentType.isEmpty ? 'Emergency' : inc.incidentType, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                Chip(label: Text(inc.status), backgroundColor: statusColor(inc.status).withValues(alpha: .15)),
              ],
            ),
            const SizedBox(height: 6),
            Text(inc.description, style: TextStyle(color: Colors.grey.shade400)),
            const SizedBox(height: 8),
            Text('User: ${item.user.name.isEmpty ? item.user.email : item.user.name}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
            Text('Location: ${inc.place}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
            if (inc.image != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(base64Decode(inc.image!), height: 92, fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              Chip(label: Text(inc.responderType ?? classified.$2), backgroundColor: categoryColor(inc.responderCategory ?? classified.$1).withValues(alpha: .15)),
              if (inc.responderName != null) Chip(label: Text(inc.responderName!), backgroundColor: border),
              if (inc.status == 'assigned') Chip(label: Text('ETA ${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}'), backgroundColor: green.withValues(alpha: .12)),
              if (inc.distanceKm != null) Chip(label: Text('${inc.distanceKm!.toStringAsFixed(2)} km'), backgroundColor: border),
            ]),
          ],
        ),
      ),
    );
  }
}

class RecordColumn extends StatelessWidget {
  const RecordColumn({super.key, required this.title, required this.icon, required this.color, required this.items, this.action});
  final String title;
  final IconData icon;
  final Color color;
  final List<IncidentView> items;
  final void Function(IncidentView item)? action;

  @override
  Widget build(BuildContext context) {
    return CommandCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(leading: Icon(icon, color: color), title: Text('$title (${items.length})', style: const TextStyle(fontWeight: FontWeight.bold))),
          const Divider(color: border, height: 1),
          Expanded(
            child: items.isEmpty
                ? EmptyState(icon: icon, text: 'No $title records.')
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, index) {
                      final item = items[index];
                      return Column(
                        children: [
                          IncidentTile(item: item),
                          if (action != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: OutlinedButton.icon(onPressed: () => action!(item), icon: const Icon(Icons.check_circle_outline_rounded), label: const Text('Mark as Completed')),
                            ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class StatusColumn extends StatelessWidget {
  const StatusColumn({super.key, required this.title, required this.icon, required this.color, required this.incidents});
  final String title;
  final IconData icon;
  final Color color;
  final List<Incident> incidents;

  @override
  Widget build(BuildContext context) {
    return CommandCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(leading: Icon(icon, color: color), title: Text('$title (${incidents.length})')),
          const Divider(color: border, height: 1),
          Expanded(
            child: incidents.isEmpty
                ? EmptyState(icon: icon, text: 'No ${title.toLowerCase()} incidents')
                : ListView.builder(
                    itemCount: incidents.length,
                    itemBuilder: (_, index) {
                      final inc = incidents[index];
                      return ListTile(
                        title: Text(inc.incidentType),
                        subtitle: Text('${inc.description}\n${inc.place}', maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: inc.image == null
                            ? Text(inc.responderType ?? '')
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(base64Decode(inc.image!), width: 48, height: 48, fit: BoxFit.cover),
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
  final String title, subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 6),
              Text(subtitle, style: TextStyle(color: AppStore().theme.text.withValues(alpha: .6), fontSize: 16)),
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class CommandCard extends StatefulWidget {
  const CommandCard({super.key, required this.child, this.padding = const EdgeInsets.all(24), this.glow = false});
  final Widget child;
  final EdgeInsets padding;
  final bool glow;

  @override
  State<CommandCard> createState() => _CommandCardState();
}

class _CommandCardState extends State<CommandCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final store = AppStore();
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedScale(
        scale: isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: widget.padding,
              decoration: store.isDarkMode 
                  ? panelBox(glow: widget.glow || isHovered, alpha: isHovered ? 0.7 : 0.6)
                  : BoxDecoration(
                      color: AppTheme.light.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.light.border),
                      boxShadow: [
                        const BoxShadow(color: Color(0x140F172A), offset: Offset(0, 1), blurRadius: 3),
                        const BoxShadow(color: Color(0x120F172A), offset: Offset(0, 4), blurRadius: 6),
                        if (widget.glow || isHovered)
                          const BoxShadow(color: Color(0x1A0F172A), offset: Offset(0, 10), blurRadius: 24),
                      ],
                    ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({super.key, required this.label, required this.controller, this.obscure = false, this.maxLines = 1, this.hint});
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final int maxLines;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final store = AppStore();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        maxLines: obscure ? 1 : maxLines,
        style: TextStyle(color: store.isDarkMode ? Colors.white : const Color(0xFF0F172A)),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: store.isDarkMode ? const Color(0xFF0F172A).withValues(alpha: .5) : Colors.white.withValues(alpha: 0.9),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: store.isDarkMode ? emerald.withValues(alpha: 0.2) : const Color(0x4D94A3B8))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: store.isDarkMode ? emerald.withValues(alpha: 0.2) : const Color(0x4D94A3B8))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: store.isDarkMode ? emerald : const Color(0xFF0EA5E9), width: 1.5)),
          labelStyle: TextStyle(color: store.isDarkMode ? Colors.grey : const Color(0xFF64748B)),
        ),
      ),
    );
  }
}

class GooglePlaceField extends StatefulWidget {
  const GooglePlaceField({super.key, required this.controller, required this.onSelected});
  final TextEditingController controller;
  final ValueChanged<PlaceSuggestion> onSelected;

  @override
  State<GooglePlaceField> createState() => _GooglePlaceFieldState();
}

class _GooglePlaceFieldState extends State<GooglePlaceField> {
  Timer? debounce;
  List<PlaceSuggestion> suggestions = [];
  bool loading = false;

  @override
  void dispose() {
    debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: widget.controller,
            onChanged: onChanged,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Location / Place',
              hintText: 'Start typing an exact Google Maps location',
              suffixIcon: loading ? const Padding(padding: EdgeInsets.all(12), child: SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))) : const Icon(Icons.location_on_rounded),
              filled: true,
              fillColor: const Color(0xFF0F172A).withValues(alpha: .5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: emerald.withValues(alpha: 0.2))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: emerald.withValues(alpha: 0.2))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: emerald)),
              labelStyle: const TextStyle(color: Colors.grey),
            ),
          ),
          if (suggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 6),
              decoration: panelBox(),
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: suggestions.length,
                separatorBuilder: (context, index) => Divider(color: Theme.of(context).dividerColor, height: 1),
                itemBuilder: (context, index) {
                  final suggestion = suggestions[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.place_rounded, color: green),
                    title: Text(suggestion.description),
                    onTap: () async {
                      var selected = suggestion;
                      if (suggestion.placeId != null && (suggestion.lat == null || suggestion.lon == null)) {
                        selected = await fetchPlaceDetails(suggestion) ?? suggestion;
                      }
                      widget.onSelected(selected);
                      setState(() => suggestions = []);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void onChanged(String value) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 350), () async {
      if (value.trim().length < 2) {
        setState(() => suggestions = []);
        return;
      }
      setState(() => loading = true);
      final results = await fetchPlaceSuggestions(value.trim());
      if (!mounted) return;
      setState(() {
        suggestions = results;
        loading = false;
      });
    });
  }
}

Future<List<PlaceSuggestion>> fetchPlaceSuggestions(String query) async {
  try {
    final uri = Uri.parse('$backendBaseUrl/api/google/places/autocomplete').replace(queryParameters: {'q': query});
    final response = await http.get(uri).timeout(const Duration(seconds: 6));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final predictions = data['predictions'] as List? ?? [];
      return predictions
          .map((item) => PlaceSuggestion(description: item['description'] ?? '', placeId: item['place_id']))
          .where((item) => item.description.isNotEmpty)
          .toList();
    }
  } catch (_) {}

  final lower = query.toLowerCase();
  return places.entries
      .where((entry) => entry.key.contains(lower) || lower.contains(entry.key))
      .map((entry) => PlaceSuggestion(description: '${entry.key}, Bengaluru, Karnataka', lat: entry.value.$1, lon: entry.value.$2))
      .toList();
}

Future<PlaceSuggestion?> fetchPlaceDetails(PlaceSuggestion suggestion) async {
  try {
    final uri = Uri.parse('$backendBaseUrl/api/google/places/details').replace(queryParameters: {'place_id': suggestion.placeId!});
    final response = await http.get(uri).timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body);
    return PlaceSuggestion(
      description: data['formatted_address'] ?? suggestion.description,
      placeId: suggestion.placeId,
      lat: asDouble(data['lat']),
      lon: asDouble(data['lon']),
    );
  } catch (_) {
    return null;
  }
}

class AlertBox extends StatelessWidget {
  const AlertBox({super.key, required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: .12), border: Border.all(color: color.withValues(alpha: .4)), borderRadius: BorderRadius.circular(8)), child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: color)));
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 46, color: Colors.grey.shade600), const SizedBox(height: 12), Text(text, style: TextStyle(color: Colors.grey.shade500))]));
  }
}

class Metric extends StatelessWidget {
  const Metric(this.label, this.value, this.icon, this.color, {super.key});
  final String label;
  final dynamic value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      child: CommandCard(
        padding: const EdgeInsets.all(20),
        glow: color == emerald,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const Spacer(),
                if (color == emerald) const PulseDot(color: emerald),
              ],
            ),
            const SizedBox(height: 12),
            Text(value.toString(), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -1)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

BoxDecoration panelBox({double alpha = 0.6, bool glow = false, AppTheme? theme}) {
  final store = AppStore();
  final active = theme ?? store.theme;
  if (!store.isDarkMode) {
    return BoxDecoration(
      color: active.card.withValues(alpha: alpha),
      border: Border.all(color: active.border),
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        const BoxShadow(color: Color(0x140F172A), offset: Offset(0, 1), blurRadius: 3),
        const BoxShadow(color: Color(0x120F172A), offset: Offset(0, 4), blurRadius: 6),
        if (glow)
          const BoxShadow(color: Color(0x1A0F172A), offset: Offset(0, 10), blurRadius: 24),
      ],
    );
  }
  return BoxDecoration(
    color: active.card.withValues(alpha: alpha),
    border: Border.all(color: active.border),
    borderRadius: BorderRadius.circular(18),
    boxShadow: [
      if (glow)
        BoxShadow(color: active.primary.withValues(alpha: 0.15), blurRadius: 30, spreadRadius: -5),
      BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
    ],
  );
}

class CyberpunkBackground extends StatelessWidget {
  const CyberpunkBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore();
    final theme = store.theme;
    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: store.isDarkMode
                ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [theme.bg2, theme.bg])
                : RadialGradient(
                    center: const Alignment(-0.8, -0.8),
                    radius: 1.5,
                    colors: [const Color(0xFF0EA5E9).withValues(alpha: 0.08), theme.bg],
                  ),
          ),
        ),
        if (!store.isDarkMode)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.8, 0.8),
                  radius: 1.5,
                  colors: [const Color(0xFF10B981).withValues(alpha: 0.06), Colors.transparent],
                ),
              ),
            ),
          ),
        CustomPaint(
          painter: GridOverlayPainter(theme.grid),
          size: Size.infinite,
        ),
      ],
    );
  }
}

class GridOverlayPainter extends CustomPainter {
  GridOverlayPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const spacing = 40.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class PulseDot extends StatefulWidget {
  const PulseDot({super.key, required this.color});
  final Color color;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.5 * _controller.value),
                blurRadius: 8 * _controller.value,
                spreadRadius: 4 * _controller.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

class CyberpunkGradientButton extends StatelessWidget {
  const CyberpunkGradientButton({super.key, required this.onPressed, required this.label, this.icon, this.orange = false});
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool orange;

  @override
  Widget build(BuildContext context) {
    final color = orange ? neonOrange : emerald;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (onPressed != null)
            BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 15, spreadRadius: -2, offset: const Offset(0, 4)),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return Colors.grey.withValues(alpha: .2);
            return null; // Uses the decoration gradient
          }),
        ),
        onPressed: onPressed,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: onPressed == null 
                  ? [Colors.grey.withValues(alpha: .2), Colors.grey.withValues(alpha: .2)]
                  : [color, color.withValues(alpha: 0.85)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              if (onPressed != null)
                BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, color: Theme.of(context).scaffoldBackgroundColor, size: 18), const SizedBox(width: 8)],
                Text(label, style: TextStyle(color: Theme.of(context).scaffoldBackgroundColor, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.store, required this.onChanged});
  final AppStore store;
  final VoidCallback onChanged;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();
  String role = 'user';
  bool loading = false;
  String? error;

  void submit() async {
    setState(() { loading = true; error = null; });
    String? res;
    if (isLogin) {
      res = await widget.store.login(email.text, password.text);
    } else {
      res = await widget.store.signup(email: email.text, password: password.text, name: name.text, role: role);
    }
    if (!mounted) return;
    if (res == null) {
      widget.onChanged();
    } else {
      setState(() { error = res; loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const CyberpunkBackground(),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: CommandCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.shield_rounded, color: emerald, size: 48),
                    const SizedBox(height: 16),
                    Text(isLogin ? 'WELCOME BACK' : 'CREATE ACCOUNT', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(isLogin ? 'Nexus Dispatch Command Login' : 'Join the Nexus Network', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 32),
                    if (!isLogin) AppTextField(label: 'Full Name', controller: name),
                    AppTextField(label: 'Email Address', controller: email),
                    AppTextField(label: 'Security Password', controller: password, obscure: true),
                    if (!isLogin) ...[
                      const Text('Access Role', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('User'),
                              value: 'user',
                              groupValue: role,
                              onChanged: (v) => setState(() => role = v!),
                              activeColor: emerald,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Admin'),
                              value: 'admin',
                              groupValue: role,
                              onChanged: (v) => setState(() => role = v!),
                              activeColor: emerald,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (error != null) AlertBox(text: error!, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    CyberpunkGradientButton(
                      onPressed: loading ? null : submit,
                      label: loading ? 'PROCESSING...' : (isLogin ? 'LOGIN' : 'SIGN UP'),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => setState(() => isLogin = !isLogin),
                      child: Text(isLogin ? "Don't have an account? Sign Up" : "Already have an account? Login", style: const TextStyle(color: emerald)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final resources = <String, List<ResourceUnit>>{
  'ambulance': const [
    ResourceUnit('AMB_001', 'Victoria Hospital Ambulance', 12.9635, 77.5739),
    ResourceUnit('AMB_002', 'Manipal Hospital Ambulance', 12.9582, 77.6484),
    ResourceUnit('AMB_003', "St. John's Medical Response", 12.9294, 77.6187),
    ResourceUnit('AMB_004', 'Aster CMI Ambulance', 13.0545, 77.5928),
    ResourceUnit('AMB_005', 'Fortis Bannerghatta Ambulance', 12.8958, 77.5996),
  ],
  'fire': const [
    ResourceUnit('FIRE_001', 'High Grounds Fire Engine', 12.9866, 77.5938),
    ResourceUnit('FIRE_002', 'Indiranagar Fire Engine', 12.9784, 77.6408),
    ResourceUnit('FIRE_003', 'Jayanagar Fire Engine', 12.9257, 77.5930),
    ResourceUnit('FIRE_004', 'Whitefield Fire Engine', 12.9698, 77.7500),
    ResourceUnit('FIRE_005', 'Yeshwanthpur Fire Engine', 13.0285, 77.5409),
  ],
  'rescue': const [
    ResourceUnit('RES_001', 'Central Rescue Team', 12.9767, 77.5993),
    ResourceUnit('RES_002', 'East Zone Rescue Team', 12.9719, 77.6412),
    ResourceUnit('RES_003', 'South Zone Rescue Team', 12.9166, 77.6101),
    ResourceUnit('RES_004', 'North Zone Rescue Team', 13.0358, 77.5970),
  ],
};

final places = <String, (double, double)>{
  'pattanager': (12.9226, 77.4987),
  'pattanagere': (12.9226, 77.4987),
  'mg road': (12.9756, 77.6068),
  'indiranagar': (12.9784, 77.6408),
  'koramangala': (12.9352, 77.6245),
  'whitefield': (12.9698, 77.7500),
  'jayanagar': (12.9250, 77.5938),
  'majestic': (12.9767, 77.5713),
  'hebbal': (13.0358, 77.5970),
  'yeshwanthpur': (13.0285, 77.5409),
  'electronic': (12.8452, 77.6602),
  'bannerghatta': (12.8877, 77.5969),
};

Future<Assignment> createAssignment(Incident incident, Set<String> taken) async {
  final classified = await classifyWithGemini(incident) ?? classifyLocal(incident);
  final loc = incidentLocation(incident);
  final pool = resources[classified.$1]!;
  final available = pool.where((unit) => !taken.contains(unit.id)).toList();
  final ranked = (available.isEmpty ? pool : available)
      .map((unit) => (unit: unit, distance: haversine(loc.$1, loc.$2, unit.lat, unit.lon)))
      .toList()
    ..sort((a, b) => a.distance.compareTo(b.distance));
  final best = ranked.first;
  final eta = max(1, ((best.distance / 40) * 60).round());
  return Assignment(category: classified.$1, responderType: classified.$2, resource: best.unit, lat: loc.$1, lon: loc.$2, distanceKm: double.parse(best.distance.toStringAsFixed(2)), etaMinutes: eta);
}

Future<(String, String)?> classifyWithGemini(Incident incident) async {
  if (geminiApiKey.isEmpty) return null;
  try {
    final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$geminiApiKey');
    final prompt = 'Classify this emergency as exactly one of ambulance, fire, rescue. Return only the word. Type: ${incident.incidentType}. Description: ${incident.description}.';
    final response = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'contents': [{'parts': [{'text': prompt}]}]}));
    final text = (((jsonDecode(response.body)['candidates'] as List?)?.firstOrNull?['content']?['parts'] as List?)?.firstOrNull?['text'] ?? '').toString().toLowerCase();
    if (text.contains('fire')) return ('fire', 'Fire Engine');
    if (text.contains('rescue')) return ('rescue', 'Rescue Team');
    if (text.contains('ambulance')) return ('ambulance', 'Ambulance');
  } catch (_) {}
  return null;
}

(String, String) classifyLocal(Incident incident) {
  final text = '${incident.incidentType} ${incident.description}'.toLowerCase();
  if (RegExp(r'fire|burn|smoke|flame|blast|explosion|gas leak').hasMatch(text)) return ('fire', 'Fire Engine');
  if (RegExp(r'collapse|trapped|rescue|flood|drowning|stuck|earthquake|debris|building').hasMatch(text)) return ('rescue', 'Rescue Team');
  return ('ambulance', 'Ambulance');
}

(double, double) incidentLocation(Incident incident) {
  if (incident.lat != null && incident.lon != null) return (incident.lat!, incident.lon!);
  final place = incident.place.toLowerCase();
  for (final entry in places.entries) {
    if (place.contains(entry.key)) return entry.value;
  }
  final seed = place.codeUnits.fold<int>(0, (sum, code) => sum + code);
  final lat = 12.9716 + (((seed % 97) / 97) - .5) * .12;
  final lon = 77.5946 + ((((seed * 7) % 97) / 97) - .5) * .12;
  return (lat, lon);
}

double haversine(double lat1, double lon1, double lat2, double lon2) {
  const radius = 6371.0;
  final dlat = radians(lat2 - lat1);
  final dlon = radians(lon2 - lon1);
  final a = pow(sin(dlat / 2), 2) + cos(radians(lat1)) * cos(radians(lat2)) * pow(sin(dlon / 2), 2);
  return radius * 2 * atan2(sqrt(a), sqrt(1 - a));
}

double radians(double value) => value * pi / 180;

int remainingSeconds(Incident incident, [int? now]) {
  if (incident.status != 'assigned') return 0;
  final eta = incident.etaSeconds ?? 0;
  final assignedAt = incident.assignedAt;
  if (assignedAt == null || eta <= 0) return eta;
  return max(0, eta - (((now ?? DateTime.now().millisecondsSinceEpoch) - assignedAt) ~/ 1000));
}

int calculateScore(Incident inc) {
  final text = '${inc.incidentType} ${inc.description}'.toLowerCase();
  var score = 55;
  if (RegExp(r'fire|explosion|collapse|trapped|critical|blood|unconscious').hasMatch(text)) score += 28;
  if (RegExp(r'many|crowd|school|building|accident').hasMatch(text)) score += 12;
  return min(100, score);
}

Color statusColor(String status) => switch (status) { 'assigned' => blue, 'completed' => green, _ => yellow };
Color scoreColor(int? score) => score == null ? Colors.grey : score >= 80 ? Colors.redAccent : score >= 60 ? orange : yellow;
Color categoryColor(String category) => switch (category) { 'fire' => orange, 'rescue' => violet, _ => cyan };


int? asInt(dynamic value) => value == null ? null : int.tryParse('$value');
double? asDouble(dynamic value) => value == null ? null : double.tryParse('$value');

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key, required this.store, required this.onChanged});
  final AppStore store;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = store.theme;
    return GestureDetector(
      onTap: () {
        store.toggleTheme();
        onChanged();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 60,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: theme.bg2.withValues(alpha: 0.2),
          border: Border.all(color: theme.border),
          boxShadow: [
            BoxShadow(
              color: store.isDarkMode ? emerald.withValues(alpha: 0.1) : orange.withValues(alpha: 0.08),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: store.isDarkMode ? 32 : 2,
              top: 2,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: store.isDarkMode ? emerald : orange,
                  boxShadow: [
                    if (store.isDarkMode)
                      BoxShadow(color: emerald.withValues(alpha: 0.4), blurRadius: 10),
                    if (!store.isDarkMode)
                      BoxShadow(color: orange.withValues(alpha: 0.4), blurRadius: 10),
                  ],
                ),
                child: Icon(
                  store.isDarkMode ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
