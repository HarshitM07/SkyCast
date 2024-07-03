import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:sky_cast/additional_info_item.dart';
import 'package:sky_cast/hourly_forecast_item.dart';
import 'package:http/http.dart' as http;
import 'package:sky_cast/secrets.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late Future<Map<String, dynamic>> weather = getCurrentWeather();
  Future testNetworkConnectivity() async {
    try {
      final res = await http.get(Uri.parse('https://www.google.com'));
      if (res.statusCode == 200) {
        print('Network is working');
      } else {
        print('Network request failed with status: ${res.statusCode}');
      }
    } catch (e) {
      print('Network test failed: $e');
    }
  }

  Future<Map<String, dynamic>> getCurrentWeather() async {
    try {
      String cityName = 'Mandi';
      final res = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?q=$cityName&APPID=$openWeatherAPIkey',
        ),
      );
      final data = jsonDecode(res.body);
      if (data['cod'] != '200') {
        throw 'An unexpected error occured';
      }

      return data;
      // data['list'][0]['main']['temp'];
    } catch (e) {
      print('error : $e');
      throw e.toString();
    }
  }

  @override
  void initState() {
    super.initState();
    weather = getCurrentWeather();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sky Cast',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                weather = getCurrentWeather();
              });
            },
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: FutureBuilder(
        future: weather,
        builder: (context, snapshot) {
          print(snapshot);
          print(snapshot.runtimeType);

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (snapshot.hasError) {
            return Text(snapshot.error.toString());
          }

          final data = snapshot.data!;

          final currentWeatherData = data['list'][0];
          final currentTemperature =
              currentWeatherData['main']['temp'] - 273.15;
          final String currentSky = currentWeatherData['weather'][0]['main'];
          final humidity = currentWeatherData['main']['humidity'];
          final windSpeed = currentWeatherData['wind']['speed'];
          final pressure = currentWeatherData['main']['pressure'];
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //main card
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    elevation: 0.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 4.0,
                          sigmaY: 4.0,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Text(
                                '${currentTemperature.toStringAsFixed(2)} °C',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Icon(
                                currentSky == 'Rain'
                                    ? Icons.cloudy_snowing
                                    : (currentSky == 'Clouds'
                                        ? Icons.cloud
                                        : Icons.sunny),
                                size: 64,
                              ),
                              const SizedBox(height: 7),
                              Text(
                                currentSky,
                                style: const TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Hourly Forecast',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                // weather forecast cards

                // SingleChildScrollView(
                //   scrollDirection: Axis.horizontal,
                //   child: Row(
                //     children: [
                //       for (int i = 0; i < 30; i++)
                //         HourlyForecastItem(
                //           time: data['list'][i + 1]['dt_txt'],
                //           temperature:
                //               data['list'][i + 1]['main']['temp'].toString(),
                //           icon: data['list'][i + 1]['weather'][0]['main'] ==
                //                   'Rain'
                //               ? Icons.cloudy_snowing
                //               : (currentSky == 'Clouds'
                //                   ? Icons.cloud
                //                   : Icons.sunny),
                //         ),
                //     ],
                //   ),
                // ),

                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 8,
                    itemBuilder: (BuildContext context, int index) {
                      final hourlyForecast = data['list'][index + 1];
                      final hourlySky =
                          data['list'][index + 1]['weather'][0]['main'];
                      final time = DateTime.parse(hourlyForecast['dt_txt']);
                      return HourlyForecastItem(
                        time: DateFormat.jm().format(time).toString(),
                        temperature: (hourlyForecast['main']['temp'] - 273.15),
                        icon: hourlySky == 'Rain'
                            ? Icons.cloudy_snowing
                            : (currentSky == 'Clouds'
                                ? Icons.cloud
                                : Icons.sunny),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 32),
                // additional informtion

                const Text(
                  'Additional Information',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    AdditionalInfoItem(
                      icon: Icons.water_drop,
                      atmosphere: 'Humidity',
                      value: '$humidity %',
                    ),
                    AdditionalInfoItem(
                      icon: Icons.air,
                      atmosphere: 'Wind Speed',
                      value: '$windSpeed km/h',
                    ),
                    AdditionalInfoItem(
                      icon: Icons.beach_access,
                      atmosphere: 'Pressure',
                      value: '$pressure mb',
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
