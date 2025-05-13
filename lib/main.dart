import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';


// modelos e telas
import 'profile_model.dart';
import 'contact_model.dart';
import 'profilepage.dart';
import 'historypage.dart';
import 'settingspage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa o Hive
  await Hive.initFlutter();
  Hive.registerAdapter(ProfileAdapter());
  await Hive.openBox<Profile>('profileBox');
  Hive.registerAdapter(ContactAdapter());
  await Hive.openBox<Contact>('contactsBox');
  runApp(const MyApp());

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guardian Angel SOS',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          centerTitle: true,
        ),
      ),
      home: const GuardianHomePage(),
    );
  }
}

class GuardianHomePage extends StatefulWidget {
  const GuardianHomePage({super.key});

  @override
  State<GuardianHomePage> createState() => _GuardianHomePageState();
}

class _GuardianHomePageState extends State<GuardianHomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const ProfilePage(),
    const HistoryPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.security),
        title: const Text('Guardian Angel SOS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => setState(() => _selectedIndex = 3),
          ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class LocationService {
  final Location _location = Location();

  Future<LatLng> getCurrentLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // Verifica se o serviço de localização está habilitado
    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        throw Exception('Serviço de localização desabilitado.');
      }
    }

    // Verifica se a permissão de localização foi concedida
    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        throw Exception('Permissão de localização negada.');
      }
    }

    // Obtém a localização atual
    final locationData = await _location.getLocation();
    return LatLng(locationData.latitude!, locationData.longitude!);
  }
}
class _HomeScreenState extends State<HomeScreen> {
  bool _monitoring = false;
  late StreamSubscription<AccelerometerEvent> _accelSub;
  final Location _location = Location();
  LatLng _currentPosition = const LatLng(-23.5505, -46.6333); // Posição inicial (São Paulo)
  late GoogleMapController _mapController;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      // Verifica se o serviço de localização está habilitado
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          print('Serviço de localização desabilitado.');
          return;
        }
      }

      // Verifica permissões de localização
      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          print('Permissão de localização negada.');
          return;
        }
      }

      // Obtém a localização inicial
      final location = await _location.getLocation();
      setState(() {
        _currentPosition = LatLng(location.latitude!, location.longitude!);
      });

      // Move a câmera para a localização inicial
      _mapController.animateCamera(
        CameraUpdate.newLatLng(_currentPosition),
      );

      // Começa a ouvir mudanças de localização
      _listenToLocationChanges();
    } catch (e) {
      print('Erro ao obter localização: $e');
    }
  }

  void _listenToLocationChanges() {
    _location.onLocationChanged.listen((location) {
      setState(() {
        _currentPosition = LatLng(location.latitude!, location.longitude!);
      });

      // Atualiza a câmera do mapa
      _mapController.animateCamera(
        CameraUpdate.newLatLng(_currentPosition),
      );
    });
  }

  void _toggleMonitoring() {
    setState(() {
      _monitoring = !_monitoring;
    });
  }

  void _triggerSOS() {
    print('SOS acionado!');
    // Lógica para acionar SOS
  }

  @override
  void dispose() {
    if (_monitoring) _accelSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Botões e outros widgets
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _toggleMonitoring,
                icon: Icon(
                  _monitoring ? Icons.pause_circle : Icons.play_circle,
                  color: Colors.white,
                  size: 30, 
                ),
                label: Text(
                  _monitoring ? 'Parar' : 'Monitorar',
                  style: const TextStyle(fontSize: 20), 
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20), // Aumenta o tamanho do botão
                  backgroundColor: _monitoring ? Colors.grey : Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Bordas levemente arredondadas
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  print('Botão SOS pressionado');
                  _triggerSOS();
                },
                icon: const Icon(
                  Icons.warning,
                  color: Colors.white,
                  size: 30, // Aumenta o tamanho do ícone
                ),
                label: const Text(
                  'SOS',
                  style: TextStyle(fontSize: 20), // Aumenta o tamanho do texto
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20), // Aumenta o tamanho do botão
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Bordas levemente arredondadas
                  ),
                ),
              ),
            ],
          ),
        ),
        // Mapa ocupa o restante do espaço
        Expanded(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 12,
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            myLocationEnabled: true, // Mostra o ponto azul da localização
            myLocationButtonEnabled: true, // Botão para centralizar no local
          ),
        ),
      ],
    );
  }
}
