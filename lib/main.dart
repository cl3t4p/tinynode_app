import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TinyNode',
      debugShowCheckedModeBanner: false,
      // --- AUTOMATIC THEME LOGIC ---
      themeMode: ThemeMode.system, // Switches based on System Settings
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      // -----------------------------
      home: const HomeScreen(),
    );
  }
}

// --- DATA MODEL ---
class IotButton {
  String name;
  String deviceId;
  int state;
  int port;
  int colorValue;

  IotButton({
    required this.name,
    required this.deviceId,
    required this.state,
    required this.port,
    required this.colorValue,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'deviceId': deviceId,
    'state': state,
    'port': port,
    'colorValue': colorValue,
  };

  factory IotButton.fromJson(Map<String, dynamic> json) {
    return IotButton(
      name: json['name'],
      deviceId: json['deviceId'],
      state: json['state'],
      port: json['port'] ?? 16,
      colorValue: json['colorValue'],
    );
  }
}

// --- MAIN SCREEN ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<IotButton> buttons = [];
  bool _isEditMode = false;

  String serverUrl = "http://192.168.1.1:9006";
  String apiKey = "devtoken";
  String username = "";
  String password = "";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      serverUrl = prefs.getString('server_url') ?? "http://192.168.1.1:9006";
      apiKey = prefs.getString('api_key') ?? "";
      username = prefs.getString('username') ?? "";
      password = prefs.getString('password') ?? "";

      final String? buttonsString = prefs.getString('buttons_list');
      if (buttonsString != null) {
        List<dynamic> jsonList = jsonDecode(buttonsString);
        buttons = jsonList.map((e) => IotButton.fromJson(e)).toList();
      }
    });
  }

  Future<void> _saveButtons() async {
    final prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(buttons.map((e) => e.toJson()).toList());
    await prefs.setString('buttons_list', jsonString);
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final IotButton item = buttons.removeAt(oldIndex);
      buttons.insert(newIndex, item);
    });
    _saveButtons();
  }

  Future<void> _sendRequest(IotButton btn) async {
    String cleanUrl = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;

    final url = Uri.parse('$cleanUrl/device/${btn.deviceId}/relay');

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "state": btn.state,
          "port": btn.port,
        }),
      );

      if (!mounted) return;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Errore ${response.statusCode}: ${response.body}'),
              backgroundColor: Colors.red
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eccezione: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showButtonDialog({IotButton? existingButton, int? index}) {
    bool isEditing = existingButton != null;
    String name = isEditing ? existingButton.name : "";
    String deviceId = isEditing ? existingButton.deviceId : "esp32_01";
    final stateController = TextEditingController(text: isEditing ? existingButton.state.toString() : "0");
    final portController = TextEditingController(text: isEditing ? existingButton.port.toString() : "16");
    Color selectedColor = isEditing ? Color(existingButton.colorValue) : Colors.blue;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? "Modifica Azione" : "Aggiungi Azione"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(labelText: "Nome Pulsante"),
                      controller: TextEditingController(text: name)..selection = TextSelection.collapsed(offset: name.length),
                      onChanged: (v) => name = v,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: const InputDecoration(labelText: "Device ID"),
                      controller: TextEditingController(text: deviceId),
                      onChanged: (v) => deviceId = v,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: stateController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: "State (Integer)", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: portController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: "Port (Integer)", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    const Text("Colore Pulsante"),
                    Wrap(
                      spacing: 8,
                      children: [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.grey]
                          .map((c) => GestureDetector(
                        onTap: () => setDialogState(() => selectedColor = c),
                        child: Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: selectedColor == c ? Border.all(width: 3, color: Theme.of(context).colorScheme.onSurface) : null,
                          ),
                        ),
                      )).toList(),
                    )
                  ],
                ),
              ),
              actions: [
                if (isEditing)
                  TextButton(
                    onPressed: () {
                      setState(() => buttons.removeAt(index!));
                      _saveButtons();
                      Navigator.pop(ctx);
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text("Elimina"),
                  ),
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annulla")),
                ElevatedButton(
                  onPressed: () {
                    int? parsedState = int.tryParse(stateController.text);
                    int? parsedPort = int.tryParse(portController.text);
                    if (name.isNotEmpty && deviceId.isNotEmpty && parsedState != null && parsedPort != null) {
                      setState(() {
                        IotButton newBtn = IotButton(name: name, deviceId: deviceId, state: parsedState, port: parsedPort, colorValue: selectedColor.value);
                        if (isEditing) buttons[index!] = newBtn; else buttons.add(newBtn);
                      });
                      _saveButtons();
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text("Salva"),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _isEditMode ? (isDark ? Colors.orange.withOpacity(0.2) : Colors.orange.shade100) : null,
        title: Text(_isEditMode ? "Modifica / Sposta" : "TinyNode"),
        actions: [
          IconButton(
            icon: Icon(_isEditMode ? Icons.check : Icons.edit),
            onPressed: () => setState(() => _isEditMode = !_isEditMode),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (c) => const SettingsScreen()));
              _loadData();
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: buttons.isEmpty
          ? const Center(child: Text("Nessun pulsante. Premi + per aggiungerne uno."))
          : _isEditMode
          ? ReorderableListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: buttons.length,
        onReorder: _onReorder,
        itemBuilder: (ctx, i) {
          final btn = buttons[i];
          return Card(
            key: ValueKey(btn),
            color: Color(btn.colorValue).withOpacity(isDark ? 0.3 : 0.7),
            child: InkWell(
              onTap: () => _showButtonDialog(existingButton: btn, index: i),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    const Icon(Icons.edit),
                    const SizedBox(width: 20),
                    Expanded(child: Text(btn.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    const Icon(Icons.drag_handle),
                  ],
                ),
              ),
            ),
          );
        },
      )
          : ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: buttons.length,
        itemBuilder: (ctx, i) {
          final btn = buttons[i];
          // Use button color directly, but slightly darken for text contrast in light mode
          return Card(
            color: Color(btn.colorValue),
            child: InkWell(
              onTap: () => _sendRequest(btn),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    const Icon(Icons.touch_app, color: Colors.white),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(btn.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("ID: ${btn.deviceId} | S:${btn.state} P:${btn.port}", style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                    const Icon(Icons.send, color: Colors.white24, size: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showButtonDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// --- SETTINGS SCREEN ---
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _serverCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverCtrl.text = prefs.getString('server_url') ?? "http://192.168.1.1:9006";
      _keyCtrl.text = prefs.getString('api_key') ?? "";
      _userCtrl.text = prefs.getString('username') ?? "";
      _passCtrl.text = prefs.getString('password') ?? "";
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', _serverCtrl.text);
    await prefs.setString('api_key', _keyCtrl.text);
    await prefs.setString('username', _userCtrl.text);
    await prefs.setString('password', _passCtrl.text);
    if(mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Impostazioni Server")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _serverCtrl, decoration: const InputDecoration(labelText: "Indirizzo Server", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _keyCtrl, decoration: const InputDecoration(labelText: "Key / Token (Bearer)", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _userCtrl, decoration: const InputDecoration(labelText: "Username (Opzionale)", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(labelText: "Password (Opzionale)", border: OutlineInputBorder())),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saveSettings, child: const Text("Salva Impostazioni"))),
          ],
        ),
      ),
    );
  }
}