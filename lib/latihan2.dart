import 'package:flutter/material.dart'; // Mengimpor package flutter/material yang dibutuhkan untuk membangun UI Flutter
import 'package:flutter_bloc/flutter_bloc.dart'; // Mengimpor package flutter_bloc yang dibutuhkan untuk manajemen state
import 'package:http/http.dart' as http; // Mengimpor package http untuk melakukan permintaan HTTP
import 'dart:convert'; // Mengimpor package dart:convert untuk mengonversi data JSON

void main() {
  runApp(MyApp()); // Menjalankan aplikasi Flutter dengan widget MyApp sebagai root widget
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider( // Memberikan akses ke UniversitiesBloc ke seluruh aplikasi
      create: (context) => UniversitiesBloc(), // Membuat instance dari UniversitiesBloc
      child: MaterialApp( // Mengatur konfigurasi aplikasi dengan MaterialApp
        title: 'Universities List', // Judul aplikasi
        home: UniversitiesPage(), // Menetapkan UniversitiesPage sebagai halaman beranda
      ),
    );
  }
}

class University {
  String name; // Properti untuk menyimpan nama universitas
  String website; // Properti untuk menyimpan website universitas

  University({required this.name, required this.website}); // Constructor untuk membuat objek University
}

class UniversitiesList {
  List<University> universities = []; // List untuk menyimpan objek University

  UniversitiesList.fromJson(List<dynamic> json) { // Constructor untuk mengonversi data JSON ke objek UniversitiesList
    universities = json.map((university) {
      return University(
        name: university['name'], // Mendapatkan nama universitas dari JSON
        website: university['web_pages'][0], // Mendapatkan website universitas dari JSON
      );
    }).toList();
  }
}

abstract class UniversitiesEvent {} // Kelas abstrak untuk merepresentasikan event dalam aplikasi

class FetchUniversities extends UniversitiesEvent { // Event untuk memicu pengambilan data universitas dari server
  final String country; // Properti untuk menyimpan nama negara

  FetchUniversities(this.country); // Constructor untuk membuat event FetchUniversities
}

abstract class UniversitiesState {} // Kelas abstrak untuk merepresentasikan state dalam aplikasi

class UniversitiesInitial extends UniversitiesState {} // State awal ketika aplikasi dimulai

class UniversitiesLoading extends UniversitiesState {} // State ketika aplikasi sedang memuat data

class UniversitiesLoaded extends UniversitiesState { // State ketika data universitas berhasil dimuat
  final UniversitiesList universitiesList; // Properti untuk menyimpan daftar universitas

  UniversitiesLoaded(this.universitiesList); // Constructor untuk membuat state UniversitiesLoaded
}

class UniversitiesError extends UniversitiesState { // State ketika terjadi kesalahan dalam memuat data
  final String message; // Properti untuk menyimpan pesan kesalahan

  UniversitiesError(this.message); // Constructor untuk membuat state UniversitiesError
}

class UniversitiesBloc extends Bloc<UniversitiesEvent, UniversitiesState> { // Kelas untuk mengatur logika bisnis dan state aplikasi
  UniversitiesBloc() : super(UniversitiesInitial()) { // Constructor untuk menginisialisasi state awal
    on<FetchUniversities>(_fetchUniversities); // Mengatur handler untuk event FetchUniversities
  }

  Future<void> _fetchUniversities(
    FetchUniversities event,
    Emitter<UniversitiesState> emit,
  ) async {
    emit(UniversitiesLoading()); // Mengirim state UniversitiesLoading untuk menampilkan indikator loading
    try {
      final universitiesList = await _fetchData(event.country); // Mengambil data universitas dari server
      emit(UniversitiesLoaded(universitiesList)); // Mengirim state UniversitiesLoaded dengan data universitas yang berhasil dimuat
    } catch (e) {
      emit(UniversitiesError('Failed to load universities')); // Mengirim state UniversitiesError jika terjadi kesalahan dalam memuat data
    }
  }

  Future<UniversitiesList> _fetchData(String country) async { // Metode untuk melakukan permintaan HTTP ke server
    String url = "http://universities.hipolabs.com/search?country=$country"; // URL endpoint untuk mendapatkan data universitas
    final response = await http.get(Uri.parse(url)); // Melakukan permintaan HTTP
    if (response.statusCode == 200) {
      return UniversitiesList.fromJson(jsonDecode(response.body)); // Mengembalikan objek UniversitiesList berdasarkan respons JSON dari server
    } else {
      throw Exception('Failed to load'); // Melemparkan Exception jika gagal memuat data
    }
  }
}

class UniversitiesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final universitiesBloc = BlocProvider.of<UniversitiesBloc>(context); // Mendapatkan instance dari UniversitiesBloc
    return Scaffold( // Scaffold sebagai kerangka dasar UI
      appBar: AppBar( // AppBar sebagai bagian atas UI
        title: Text('ASEAN Universities'), // Judul AppBar
      ),
      body: Column( // Column untuk menampilkan widget secara vertikal
        children: [
          Padding( // Padding untuk menambahkan jarak antara widget dan tepi layar
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>( // DropdownButton untuk memilih negara
              onChanged: (value) { // Handler ketika nilai DropdownButton berubah
                universitiesBloc.add(FetchUniversities(value!)); // Memicu event FetchUniversities dengan nilai negara yang dipilih
              },
              items: [ // List item DropdownButton
                'Indonesia',
                'Singapore',
                'Malaysia',
                // Add other ASEAN countries here
              ].map<DropdownMenuItem<String>>((String value) { // Mapping item ke DropdownMenuItem
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          Expanded( // Expanded untuk menempatkan widget agar dapat memanfaatkan ruang yang tersedia
            child: BlocBuilder<UniversitiesBloc, UniversitiesState>( // BlocBuilder untuk membangun UI berdasarkan state dari UniversitiesBloc
              builder: (context, state) { // Builder untuk menentukan UI berdasarkan state
                if (state is UniversitiesLoading) { // Jika state adalah UniversitiesLoading
                  return Center(child: CircularProgressIndicator()); // Tampilkan indikator loading di tengah layar
                } else if (state is UniversitiesLoaded) { // Jika state adalah UniversitiesLoaded
                  return ListView.separated( // ListView untuk menampilkan daftar universitas
                    separatorBuilder: (context, index) => Divider(), // Menambahkan pemisah antara item
                    itemCount: state.universitiesList.universities.length, // Jumlah item dalam ListView
                    itemBuilder: (context, index) { // Builder untuk membuat setiap item dalam ListView
                      University university = state.universitiesList.universities[index]; // Mengambil universitas dari daftar
                      return ListTile( // ListTile untuk menampilkan setiap item dalam daftar
                        title: Text(university.name), // Judul universitas
                        subtitle: Text(university.website), // Website universitas
                      );
                    },
                  );
                } else if (state is UniversitiesError) { // Jika state adalah UniversitiesError
                  return Center(child: Text(state.message)); // Tampilkan pesan kesalahan di tengah layar
                } else { // Jika state tidak dikenali
                  return Container(); // Tampilkan kontainer kosong
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
