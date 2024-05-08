import 'package:flutter/material.dart'; // Import package flutter/material untuk membangun UI
import 'package:http/http.dart' as http; // Import package http untuk melakukan HTTP requests
import 'dart:convert'; // Import package untuk melakukan encoding/decoding JSON
import 'package:provider/provider.dart'; // Import package provider untuk menggunakan state management

class University {
  String name;
  String website;

  University({required this.name, required this.website}); // Constructor dengan parameter wajib
}

class UniversitiesList {
  List<University> universities = [];

  UniversitiesList.fromJson(List<dynamic> json) {
    universities = json.map((university) {
      return University(
        name: university['name'], // Mengambil nama perguruan tinggi dari JSON
        website: university['web_pages'][0], // Mengambil website pertama dari JSON
      );
    }).toList();
  }
}

void main() {
  runApp(MyApp()); // Menjalankan aplikasi Flutter
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider( // Menggunakan ChangeNotifierProvider untuk mengatur state
      create: (context) => SelectedCountryProvider(), // Membuat instance dari SelectedCountryProvider
      child: MaterialApp(
        title: 'Universities List',
        home: HomePage(), // Menampilkan HomePage sebagai halaman awal
      ),
    );
  }
}

class SelectedCountryProvider extends ChangeNotifier {
  String selectedCountry = "Indonesia"; // Negara yang dipilih defaultnya adalah Indonesia

  void setSelectedCountry(String country) {
    selectedCountry = country; // Mengatur negara yang dipilih
    notifyListeners(); // Memberitahu semua listener bahwa state telah berubah
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var selectedCountryProvider = Provider.of<SelectedCountryProvider>(context); // Mendapatkan instance dari SelectedCountryProvider
    return Scaffold(
      appBar: AppBar(
        title: Text('Universities List'),
      ),
      body: Column(
        children: [
          DropdownButton<String>(
            value: selectedCountryProvider.selectedCountry, // Nilai dropdown berdasarkan negara yang dipilih
            onChanged: (String? newValue) {
              if (newValue != null) {
                selectedCountryProvider.setSelectedCountry(newValue); // Mengubah negara yang dipilih saat dropdown diubah
              }
            },
            items: <String>['Indonesia', 'Singapore', 'Malaysia', 'Thailand', 'Vietnam'] // Daftar negara ASEAN
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          Expanded(
            child: FutureBuilder<UniversitiesList>(
              future: fetchData(selectedCountryProvider.selectedCountry), // Mengambil data universitas berdasarkan negara yang dipilih
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) { // Saat data masih dimuat
                  return CircularProgressIndicator(); // Tampilkan indicator loading
                } else if (snapshot.hasData) { // Jika data tersedia
                  return ListView.separated(
                    separatorBuilder: (context, index) => Divider(),
                    itemCount: snapshot.data!.universities.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(snapshot.data!.universities[index].name),
                        subtitle: Text(snapshot.data!.universities[index].website),
                      );
                    },
                  );
                } else if (snapshot.hasError) { // Jika terjadi kesalahan
                  return Text('${snapshot.error}'); // Tampilkan pesan kesalahan
                } else {
                  return Container(); // Jika tidak ada data
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<UniversitiesList> fetchData(String country) async {
    String url = "http://universities.hipolabs.com/search?country=$country"; // URL endpoint untuk mendapatkan data perguruan tinggi
    final response = await http.get(Uri.parse(url)); // Melakukan HTTP GET request

    if (response.statusCode == 200) { // Jika response berhasil
      return UniversitiesList.fromJson(jsonDecode(response.body)); // Mendecode response body menjadi objek UniversitiesList
    } else { // Jika terjadi kesalahan
      throw Exception('Failed to load universities'); // Melempar exception dengan pesan kesalahan
    }
  }
}
