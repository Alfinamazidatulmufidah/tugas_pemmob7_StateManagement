import 'package:flutter/material.dart'; // Import package flutter untuk membangun UI
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http; // Import package http untuk melakukan HTTP requests
import 'dart:convert'; // Import package untuk melakukan encoding/decoding JSON

class University {
  String name; // Nama perguruan tinggi
  String website; // Website perguruan tinggi

  University({required this.name, required this.website}); // Constructor dengan parameter wajib
}

class UniversitiesList {
  List<University> universities = []; // List untuk menyimpan objek University

  // Constructor untuk membuat objek UniversitiesList dari JSON
  UniversitiesList.fromJson(List<dynamic> json) {
    universities = json.map((university) {
      return University(
        name: university['name'], // Mengambil nama perguruan tinggi dari JSON
        website: university['web_pages'][0], // Mengambil website pertama dari JSON
      );
    }).toList();
  }
}

// Cubit untuk mengelola state aplikasi
class UniversityCubit extends Cubit<List<University>> {
  UniversityCubit() : super([]); // Menginisialisasi state dengan list kosong

  // Method untuk memuat data perguruan tinggi berdasarkan negara
  Future<void> fetchData(String country) async {
    final url = "http://universities.hipolabs.com/search?country=$country"; // URL endpoint untuk mendapatkan data perguruan tinggi
    final response = await http.get(Uri.parse(url)); // Melakukan HTTP GET request

    if (response.statusCode == 200) { // Jika response berhasil
      final universitiesList = UniversitiesList.fromJson(jsonDecode(response.body)); // Mendecode response body menjadi objek UniversitiesList
      emit(universitiesList.universities); // Mengirim list perguruan tinggi ke state
    } else { // Jika terjadi kesalahan
      throw Exception('Gagal load'); // Melempar exception dengan pesan kesalahan
    }
  }
}

void main() {
  runApp(MyApp()); // Menjalankan aplikasi Flutter
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universities List', // Judul aplikasi
      home: MyHomePage(), // Menggunakan MyHomePage sebagai halaman utama
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState(); // Mengembalikan instance dari _MyHomePageState
}

class _MyHomePageState extends State<MyHomePage> {
  late UniversityCubit _universityCubit; // Menginisialisasi cubit untuk mengelola state aplikasi
  late String _selectedCountry; // Menyimpan negara yang dipilih dari dropdown
  final List<String> _countries = ['Indonesia', 'Singapore', 'Malaysia']; // List negara ASEAN

  @override
  void initState() {
    super.initState();
    _universityCubit = UniversityCubit(); // Inisialisasi cubit
    _selectedCountry = _countries.first; // Set negara pertama sebagai negara awal
    _universityCubit.fetchData(_selectedCountry); // Memuat data perguruan tinggi saat initState dipanggil
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Indonesian Universities'), // Judul AppBar
      ),
      body: Column(
        children: [
          DropdownButton<String>(
            value: _selectedCountry, // Nilai dropdown saat ini
            onChanged: (newValue) {
              setState(() {
                _selectedCountry = newValue!; // Menyimpan negara yang dipilih
                _universityCubit.fetchData(_selectedCountry); // Memuat data perguruan tinggi berdasarkan negara yang dipilih
              });
            },
            items: _countries.map((country) {
              return DropdownMenuItem<String>(
                value: country,
                child: Text(country), // Menampilkan nama negara dalam dropdown
              );
            }).toList(),
          ),
          Expanded(
            child: BlocBuilder<UniversityCubit, List<University>>(
              bloc: _universityCubit,
              builder: (context, universities) {
                if (universities.isNotEmpty) { // Jika ada data perguruan tinggi yang diterima
                  return ListView.separated(
                    separatorBuilder: (context, index) => Divider(), // Menambahkan garis pemisah di antara setiap item
                    itemCount: universities.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(universities[index].name), // Menampilkan nama perguruan tinggi
                        subtitle: Text(universities[index].website), // Menampilkan website perguruan tinggi
                      );
                    },
                  );
                } else { // Jika tidak ada data yang diterima
                  return Center(
                    child: CircularProgressIndicator(), // Menampilkan indicator loading saat data sedang dimuat
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _universityCubit.close(); // Menutup cubit saat widget dihapus
    super.dispose();
  }
}
