import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const bg = Color(0xFF182024);
const panel = Color(0xFF1C252A);
const card = Color(0xFF212B31);
const border = Color(0xFF2A343A);
const green = Color(0xFF00D68F);
const cyan = Color(0xFF00D4FF);
const orange = Color(0xFFFF5722);
const yellow = Color(0xFFFBBF24);
const blue = Color(0xFF3B82F6);
const violet = Color(0xFFA78BFA);

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
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'COMMAND',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(seedColor: green, brightness: Brightness.dark),
        fontFamily: 'Roboto',
        useMaterial3: true,
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

class AppStore {
  bool ready = false;
  List<UserAccount> users = [];
  UserAccount? currentUser;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawUsers = prefs.getString('crisis_flutter_users');
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
    await prefs.setString('crisis_flutter_users', jsonEncode(users.map((user) => user.toJson()).toList()));
    if (currentUser != null) {
      await prefs.setString('crisis_flutter_current_user', jsonEncode(currentUser!.toJson()));
    } else {
      await prefs.remove('crisis_flutter_current_user');
    }
  }

  String? login(String email, String password) {
    final match = users.where((user) => user.email == email && user.password == password).firstOrNull;
    if (match == null) return 'Invalid credentials';
    currentUser = match;
    persist();
    return null;
  }

  String? signup({required String email, required String password, required String name, required String role}) {
    if (users.any((user) => user.email == email)) return 'Email already exists';
    final user = UserAccount(id: DateTime.now().millisecondsSinceEpoch.toString(), email: email, password: password, name: name, role: role);
    users.add(user);
    currentUser = user;
    persist();
    return null;
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
  int volunteerTab = 0;
  int userTab = 0;

  @override
  Widget build(BuildContext context) {
    final user = widget.store.currentUser;
    if (user == null) {
      return LoginScreen(store: widget.store, onChanged: widget.onChanged);
    }
    final isVolunteer = user.role == 'volunteer';
    final items = isVolunteer
        ? const [
            NavItem(Icons.dashboard_rounded, 'Dashboard'),
            NavItem(Icons.work_rounded, 'Allotment'),
            NavItem(Icons.assignment_rounded, 'Record'),
            NavItem(Icons.storage_rounded, 'History'),
          ]
        : const [
            NavItem(Icons.dashboard_rounded, 'Dashboard'),
            NavItem(Icons.history_rounded, 'History'),
            NavItem(Icons.work_rounded, 'Allocation'),
            NavItem(Icons.map_rounded, 'Routing'),
          ];
    final selected = isVolunteer ? volunteerTab : userTab;

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 250,
            color: bg,
            child: Column(
              children: [
                const SizedBox(height: 28),
                const ListTile(
                  leading: Icon(Icons.local_activity_rounded, color: green),
                  title: Text('COMMAND', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 2)),
                ),
                const SizedBox(height: 16),
                ...List.generate(items.length, (index) {
                  final item = items[index];
                  final active = selected == index;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      selected: active,
                      selectedTileColor: border,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      leading: Icon(item.icon, color: active ? green : Colors.grey),
                      title: Text(item.label, style: TextStyle(color: active ? Colors.white : Colors.grey.shade400)),
                      onTap: () => setState(() => isVolunteer ? volunteerTab = index : userTab = index),
                    ),
                  );
                }),
                const Spacer(),
                ListTile(
                  leading: CircleAvatar(backgroundColor: green, child: Text(user.name.isEmpty ? 'U' : user.name[0].toUpperCase(), style: const TextStyle(color: bg))),
                  title: Text(user.name.isEmpty ? user.email : user.name, overflow: TextOverflow.ellipsis),
                  subtitle: Text(user.role),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      widget.store.logout();
                      widget.onChanged();
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Log Out'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: panel,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: isVolunteer ? volunteerPage(selected) : userPage(selected),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget volunteerPage(int selected) => switch (selected) {
        0 => VolunteerDashboard(store: widget.store, onChanged: widget.onChanged),
        1 => VolunteerAllotment(store: widget.store, onChanged: widget.onChanged),
        2 => VolunteerRecord(store: widget.store, onChanged: widget.onChanged),
        _ => HistoryPage(title: 'Volunteer History', incidents: widget.store.allIncidents().where((item) => item.incident.status == 'completed').toList()),
      };

  Widget userPage(int selected) => switch (selected) {
        0 => UserDashboard(store: widget.store, onChanged: widget.onChanged),
        1 => HistoryPage(title: 'Your History', incidents: widget.store.currentUser!.incidents.where((incident) => incident.status == 'completed').map((incident) => IncidentView(incident, widget.store.currentUser!)).toList()),
        2 => UserAllocation(store: widget.store),
        _ => UserRouting(store: widget.store, onChanged: widget.onChanged),
      };
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

  void submit() {
    setState(() => error = null);
    final message = login
        ? widget.store.login(email.text.trim(), password.text)
        : role == 'volunteer' && referral.text != 'qwerty'
            ? 'Invalid referral code for volunteer'
            : widget.store.signup(email: email.text.trim(), password: password.text, name: name.text.trim(), role: role);
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
        constraints: const BoxConstraints(maxWidth: 720),
        child: CommandCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(getStepIcon(), color: green, size: 44),
              const SizedBox(height: 16),
              Text(getStepTitle(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(getStepSubtitle(), textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400)),
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
              
              const SizedBox(height: 18),
              Row(
                children: [
                  if (step > 1)
                    Expanded(child: OutlinedButton(onPressed: back, child: const Text('Back'))),
                  if (step > 1) const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: green, foregroundColor: bg, padding: const EdgeInsets.all(16)),
                      onPressed: step == 5 ? submit : next,
                      child: Text(step == 5 ? 'Confirm & Report' : 'Next', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
    return accidentTypes.map((type) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RadioListTile<String>(
        title: Text(type),
        value: type,
        groupValue: selectedAccidentType,
        onChanged: (val) => setState(() => selectedAccidentType = val),
        tileColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: selectedAccidentType == type ? green : border)),
        activeColor: green,
      ),
    )).toList();
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

class VolunteerDashboard extends StatefulWidget {
  const VolunteerDashboard({super.key, required this.store, required this.onChanged});
  final AppStore store;
  final VoidCallback onChanged;

  @override
  State<VolunteerDashboard> createState() => _VolunteerDashboardState();
}

class _VolunteerDashboardState extends State<VolunteerDashboard> {
  bool running = false;

  @override
  Widget build(BuildContext context) {
    final incidents = widget.store.allIncidents();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Header(title: 'Global Dashboard', subtitle: 'View all reported incidents and assess severity.', action: FilledButton.icon(onPressed: running ? null : runEngine, icon: running ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.play_arrow_rounded), label: Text(running ? 'Running Engine...' : 'Run Engine'))),
        const SizedBox(height: 24),
        Expanded(
          child: CommandCard(
            padding: EdgeInsets.zero,
            child: incidents.isEmpty
                ? const EmptyState(icon: Icons.warning_rounded, text: 'No incidents reported yet.')
                : ListView.separated(
                    itemCount: incidents.length,
                    separatorBuilder: (context, index) => const Divider(color: border, height: 1),
                    itemBuilder: (context, index) {
                      final item = incidents[index];
                      final inc = item.incident;
                      return ListTile(
                        title: Text(inc.incidentType.isEmpty ? 'Unspecified' : inc.incidentType),
                        subtitle: Text('${inc.description}\n${inc.place}', maxLines: 2, overflow: TextOverflow.ellipsis),
                        leading: CircleAvatar(backgroundColor: statusColor(inc.status).withValues(alpha: .15), child: Icon(Icons.warning_rounded, color: statusColor(inc.status))),
                        trailing: Chip(label: Text(inc.score?.toString() ?? '-'), backgroundColor: scoreColor(inc.score).withValues(alpha: .15)),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> runEngine() async {
    setState(() => running = true);
    for (final item in widget.store.allIncidents()) {
      final inc = item.incident;
      inc.score ??= calculateScore(inc);
    }
    await widget.store.persist();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    setState(() => running = false);
    widget.onChanged();
  }
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
          action: FilledButton.icon(
            onPressed: running || pending.isEmpty ? null : () => runAllotment(pending, assigned),
            icon: running ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.bolt_rounded),
            label: Text(running ? 'Running allotment...' : 'Run Allotment'),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(spacing: 12, runSpacing: 12, children: [
          Metric('Pending', pending.length, Icons.work_rounded, yellow),
          Metric('Assigned', assigned.length, Icons.local_shipping_rounded, blue),
          Metric('Completed', completed.length, Icons.check_circle_rounded, green),
          Metric('Ambulances', resources['ambulance']!.length, Icons.emergency_rounded, cyan),
          Metric('Fire/Rescue', resources['fire']!.length + resources['rescue']!.length, Icons.local_fire_department_rounded, orange),
        ]),
        const SizedBox(height: 18),
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 430,
                child: CommandCard(
                  padding: EdgeInsets.zero,
                  child: active.isEmpty
                      ? const EmptyState(icon: Icons.work_rounded, text: 'No active incidents to allocate.')
                      : ListView.builder(
                          itemCount: active.length,
                          itemBuilder: (_, index) => IncidentTile(item: active[index], now: now),
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

class VolunteerRecord extends StatelessWidget {
  const VolunteerRecord({super.key, required this.store, required this.onChanged});
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
              Expanded(child: RecordColumn(title: 'Pending', icon: Icons.schedule_rounded, color: yellow, items: pending)),
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
              Expanded(child: StatusColumn(title: 'Pending', icon: Icons.schedule_rounded, color: yellow, incidents: incidents.where((item) => item.status == 'pending').toList())),
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

class GoogleMapPanel extends StatelessWidget {
  const GoogleMapPanel({super.key, required this.incidents});
  final List<IncidentView> incidents;

  @override
  Widget build(BuildContext context) {
    final assigned = incidents.where((item) => item.incident.status == 'assigned' && item.incident.lat != null && item.incident.lon != null).toList();
    final markers = assigned.take(8).map((item) {
      final inc = item.incident;
      return 'markers=color:red%7Clabel:I%7C${inc.lat},${inc.lon}&markers=color:blue%7Clabel:R%7C${inc.resourceLat},${inc.resourceLon}';
    }).join('&');
    final url = googleMapsApiKey.isEmpty
        ? null
        : 'https://maps.googleapis.com/maps/api/staticmap?center=12.9716,77.5946&zoom=11&size=900x620&maptype=roadmap&$markers&key=$googleMapsApiKey';

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFF10171B), border: Border.all(color: border), borderRadius: BorderRadius.circular(18)),
        child: Stack(
          children: [
            Positioned.fill(
              child: url == null
                  ? CustomPaint(painter: GridMapPainter(incidents), child: Container())
                  : Image.network(url, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => CustomPaint(painter: GridMapPainter(incidents), child: Container())),
            ),
            Positioned(
              left: 16,
              top: 16,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: panelBox(alpha: .92),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Icon(Icons.my_location_rounded, color: green, size: 16), SizedBox(width: 8), Text('Google Maps Dispatch View', style: TextStyle(color: green, fontWeight: FontWeight.bold))]),
                    SizedBox(height: 6),
                    Text('Set GOOGLE_MAPS_API_KEY for live static map tiles.', style: TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GridMapPainter extends CustomPainter {
  GridMapPainter(this.incidents);
  final List<IncidentView> incidents;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = border.withValues(alpha: .35)..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 34) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (final item in incidents) {
      final inc = item.incident;
      final loc = incidentLocation(inc);
      final p = Offset(size.width * (.5 + (loc.$2 - 77.5946) * 3.5), size.height * (.5 - (loc.$1 - 12.9716) * 3.5));
      final c = categoryColor(inc.responderCategory ?? classifyLocal(inc).$1);
      canvas.drawCircle(p, 8, Paint()..color = c);
      if (inc.status == 'assigned' && inc.resourceLat != null && inc.resourceLon != null) {
        final r = Offset(size.width * (.5 + (inc.resourceLon! - 77.5946) * 3.5), size.height * (.5 - (inc.resourceLat! - 12.9716) * 3.5));
        canvas.drawLine(r, p, Paint()..color = c..strokeWidth = 3);
        canvas.drawCircle(r, 7, Paint()..color = bg);
        canvas.drawCircle(r, 7, Paint()..color = c..style = PaintingStyle.stroke..strokeWidth = 3);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade400)),
          ]),
        ),
        ?action,
      ],
    );
  }
}

class CommandCard extends StatelessWidget {
  const CommandCard({super.key, required this.child, this.padding = const EdgeInsets.all(24)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(padding: padding, decoration: panelBox(), child: child);
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        maxLines: obscure ? 1 : maxLines,
        decoration: InputDecoration(labelText: label, hintText: hint, filled: true, fillColor: bg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: border)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: green))),
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
            decoration: InputDecoration(
              labelText: 'Location / Place',
              hintText: 'Start typing an exact Google Maps location',
              suffixIcon: loading ? const Padding(padding: EdgeInsets.all(12), child: SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))) : const Icon(Icons.location_on_rounded),
              filled: true,
              fillColor: bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: green)),
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
                separatorBuilder: (context, index) => const Divider(color: border, height: 1),
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
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 170, child: CommandCard(padding: const EdgeInsets.all(16), child: Row(children: [Icon(icon, color: color), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$value', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54, letterSpacing: 1))])]))); 
  }
}

BoxDecoration panelBox({double alpha = 1}) => BoxDecoration(color: card.withValues(alpha: alpha), border: Border.all(color: border), borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .18), blurRadius: 18, offset: const Offset(0, 8))]);

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
