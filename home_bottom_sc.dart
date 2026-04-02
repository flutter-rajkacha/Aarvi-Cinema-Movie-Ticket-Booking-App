import 'package:aarvi_cinema/book_now_sc.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:aarvi_cinema/model/movie_model.dart'; // import your model

class HomeBottomSc extends StatefulWidget {
  const HomeBottomSc({super.key});

  @override
  State<HomeBottomSc> createState() => _HomeBottomScState();
}

class _HomeBottomScState extends State<HomeBottomSc> {
  List<String> menu = ['All', 'Hindi', 'English', 'Gujarati', 'South'];
  String selectedCategory = 'All';

  List<Movie> allMovies = [];
  List<Movie> filteredMovies = [];

  final DatabaseReference dbRef = FirebaseDatabase.instance.ref("Movies");

  @override
  void initState() {
    super.initState();
    fetchMovies();
  }

  // Fetch all movies from Firebase
  void fetchMovies() async {
    final snapshot = await dbRef.get();

    if (snapshot.exists) {
      allMovies.clear();

      final dynamic data = snapshot.value;

      if (data is Map) {
        // If data is a map (usual case)
        data.forEach((key, value) {
          if (value is Map) {
            allMovies.add(
              Movie(
                key: key,
                movieData: MovieData.fromJson(
                  Map<dynamic, dynamic>.from(value),
                ),
              ),
            );
          }
        });
      } else if (data is List) {
        // If Firebase saved as list (some indexes can be null)
        for (int i = 0; i < data.length; i++) {
          final value = data[i];
          if (value != null && value is Map) {
            allMovies.add(
              Movie(
                key: i.toString(),
                movieData: MovieData.fromJson(
                  Map<dynamic, dynamic>.from(value),
                ),
              ),
            );
          }
        }
      }

      applyFilter();
    }
  }

  // Apply category filter
  void applyFilter() {
    setState(() {
      if (selectedCategory == 'All') {
        filteredMovies = allMovies;
      } else {
        filteredMovies = allMovies
            .where((movie) => movie.movieData?.category == selectedCategory)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: Text(
              "Hello,",
              style: TextStyle(
                color: Colors.black,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
            child: Text(
              "Book Your Tickets",
              style: TextStyle(
                color: Colors.black,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Category menu
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: menu.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    selectedCategory = menu[index];
                    applyFilter();
                  },
                  child: Container(
                    margin: EdgeInsets.all(8),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: selectedCategory == menu[index]
                          ? Color(0xFF0B5D7E)
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        menu[index],
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Movies list
          Expanded(
            child: ListView.builder(
              itemCount: filteredMovies.length,
              itemBuilder: (context, index) {
                final movie = filteredMovies[index].movieData;

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: 210,
                    decoration: BoxDecoration(
                      color: Color(0xFF0B5D7E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Container(
                            width: 140,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(movie!.image!),
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                movie.name!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                "U/A • ${movie.category}",
                                style: TextStyle(color: Colors.white),
                              ),
                              SizedBox(height: 30),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          BookNowSc(movieName: movie.name),
                                    ),
                                  );
                                },
                                child: Container(
                                  height: 40,
                                  width: 150,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFC9EED6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Book Now",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
