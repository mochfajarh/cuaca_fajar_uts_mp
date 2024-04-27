import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:cuaca_fajar_uts_mp/var.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CuacaScreen(),
    );
  }
}


class ApiService {
  Future<Map<String, dynamic>> fetchWeatherDataByCoordinates(double latitude, double longitude) async {
    final url =
        '${Var.openWeatherUrl}/weather?lat=$latitude&lon=$longitude&appid=${Var.apiKey}&units=metric';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('gagal memuat data api');
    }
  }
}


class CuacaScreen extends StatelessWidget {
  const CuacaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FajarApp'),
      ),
      body: FutureBuilder(
        future: _getCurrentLocationWeather(), 
        builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              final weatherData = snapshot.data!;
              final wilayahName = weatherData['cityName'];
             final weather = weatherData['weather'];
              IconData iconData;

              switch (weather.toLowerCase()) {
                case 'clear':
                  iconData = Icons.wb_sunny;
                  break;
                case 'clouds':
                  iconData = Icons.cloud;
                  break;
                case 'rain':
                  iconData = Icons.beach_access;
                  break;
                case 'thunderstorm':
                  iconData = Icons.flash_on;
                  break;
                case 'drizzle':
                  iconData = Icons.grain;
                  break;
                case 'snow':
                  iconData = Icons.ac_unit;
                  break;
                case 'mist':
                  iconData = Icons.blur_on;
                  break;
                default:
                  iconData = Icons.error_outline;
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        wilayahName,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Cuaca Saat ini :  $weather',
                        style: const TextStyle(fontSize: 18),
                      ),
                            const SizedBox(height: 20),
                      const SizedBox(height: 10),
                      Icon(
                        iconData,
                        size: 60,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _getCurrentLocationWeather() async {
    try {
      if (!(await Permission.location.status.isGranted)) {
        await Permission.location.request();
      }
      
      if (await Permission.location.serviceStatus.isEnabled) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        final weatherService = ApiService();
        final weatherData = await weatherService.fetchWeatherDataByCoordinates(
            position.latitude, position.longitude);
        return {'cityName': weatherData['name'], 'temperature': weatherData['main']['temp'], 'weather': weatherData['weather'][0]['main']};
      } else {
        throw Exception('Akses lokasi dibutuhkan, mohon izinkan permission');
      }
    } catch (e) {
      return {'cityName': 'Unknown', 'temperature': 'Unknown', 'weather': 'Unknown'};
    }
  }
}
