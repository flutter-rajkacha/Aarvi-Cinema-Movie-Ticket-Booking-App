import 'package:aarvi_cinema/ticket_summary_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class BookNowSc extends StatefulWidget {
  final String? movieName;

  const BookNowSc({super.key, this.movieName});

  @override
  State<BookNowSc> createState() => _BookNowScState();
}

class _BookNowScState extends State<BookNowSc> {
  final User? user = FirebaseAuth.instance.currentUser;
  late final String email = user?.email ?? "Guest";

  final int totalSeats = 50;
  List<int> selectedSeats = [];
  List<int> bookedSeats = [];
  double ticketPrice = 150;

  final DatabaseReference dbRef = FirebaseDatabase.instance.ref("Bookings");

  late String currentDate;
  late String showTime;

  @override
  void initState() {
    super.initState();
    _setDateAndTime();
    fetchBookedSeats();
    fetchMoviePrice();   // ✅ load price from Movies table
  }

  /// Set current date & time partition
  void _setDateAndTime() {
    final now = DateTime.now();

    currentDate = DateFormat('dd/MM/yy').format(now);

    if (now.hour < 12) {
      showTime = "10:00 AM";
    } else if (now.hour < 17) {
      showTime = "03:00 PM";
    } else {
      showTime = "07:00 PM";
    }
  }

  /// Fetch all active bookings and remove expired ones
  void fetchBookedSeats() async {
    bookedSeats.clear();

    final snapshot = await dbRef
        .child(widget.movieName ?? "DefaultMovie")
        .child(currentDate)
        .child(showTime)
        .get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final now = DateTime.now().millisecondsSinceEpoch;

      for (var entry in data.entries) {
        final bookingId = entry.key;
        final booking = Map<String, dynamic>.from(entry.value);

        final expiry = booking["expiresAt"];

        if (expiry != null && now > expiry) {
          // 🔥 Auto delete expired booking
          await dbRef
              .child(widget.movieName ?? "DefaultMovie")
              .child(currentDate)
              .child(showTime)
              .child(bookingId)
              .remove();
        } else {
          final seats = booking["seats"];
          if (seats is List) {
            bookedSeats.addAll(seats.whereType<int>());
          }
        }
      }
    }

    setState(() {});
  }

  /// Book seats
  void bookSeats() async {
    if (selectedSeats.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select seats")));
      return;
    }

    // Prevent double booking
    final alreadyBooked = selectedSeats.any(
      (seat) => bookedSeats.contains(seat),
    );

    if (alreadyBooked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Some seats already booked")),
      );
      return;
    }

    final now = DateTime.now();
    final expiryTime = now
        .add(const Duration(hours: 24))
        .millisecondsSinceEpoch;

    final bookingData = {
      "userEmail": email,
      "movieName": widget.movieName ?? "DefaultMovie",
      "date": currentDate,
      "showTime": showTime,
      "seats": selectedSeats,
      "timestamp": ServerValue.timestamp,
      "expiresAt": expiryTime,
    };

    await dbRef
        .child(widget.movieName ?? "DefaultMovie")
        .child(currentDate)
        .child(showTime)
        .push() // ✅ prevents overwrite
        .set(bookingData);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TicketSummaryScreen(
          userName: email,
          movieName: widget.movieName ?? "DefaultMovie",
          selectedSeats: selectedSeats,
          date: currentDate,
          showTime: showTime,
          ticketPrice: ticketPrice,
        ),
      ),
    );
  }
  void fetchMoviePrice() async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref("Movies").get();

      if (!snapshot.exists) {
        print("Movies node is empty");
        return;
      }

      final movies = snapshot.value;
      if (movies is Map) {
        double? price;

        movies.forEach((key, value) {
          if (value is Map) {
            if (value["name"] == widget.movieName) {
              price = double.tryParse(value["price"].toString()) ?? 0;
            }
          }
        });

        if (price != null) {
          setState(() {
            ticketPrice = price!;
          });
          print("Movie Price: $ticketPrice");
        } else {
          print("Movie not found");
        }
      } else {
        print("Unexpected Firebase structure: ${movies.runtimeType}");
      }
    } catch (e) {
      print("Error fetching price: $e");
    }
  }
  //       .child(widget.movieName ?? "DefaultMovie")
  //       .child("price")
  //       .get();
  //
  //   if (snapshot.exists) {
  //     setState(() {
  //       ticketPrice = double.parse(snapshot.value.toString());
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B5D7E),
        title: Text(
          widget.movieName ?? "Aarvi Cinema",
          style: const TextStyle(color: Color(0xFFC9EED6)),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(
              "$currentDate   $showTime",
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 10),

            /// Seats Grid
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 10, 30, 15),
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: totalSeats,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisExtent: 45,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final seatNumber = index + 1;
                  final isBooked = bookedSeats.contains(seatNumber);
                  final isSelected = selectedSeats.contains(seatNumber);

                  return GestureDetector(
                    onTap: () {
                      if (isBooked) return;
                      setState(() {
                        isSelected
                            ? selectedSeats.remove(seatNumber)
                            : selectedSeats.add(seatNumber);
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isBooked
                            ? Colors.red
                            : isSelected
                            ? Colors.green
                            : Colors.blueGrey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          "$seatNumber",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            /// Book Button
            // GestureDetector(
            //   onTap: bookSeats,
            //   child: Container(
            //     height: 40,
            //     width: 250,
            //     decoration: BoxDecoration(
            //       borderRadius: BorderRadius.circular(20),
            //       color: const Color(0xFFC9EED6),
            //     ),
            //     child: const Center(
            //       child: Text(
            //         "Book Selected Seats",
            //         style: TextStyle(fontWeight: FontWeight.bold),
            //       ),
            //     ),
            //   ),
            // ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TicketSummaryScreen(
                      userName: email,
                      movieName: widget.movieName ?? "DefaultMovie",
                      selectedSeats: selectedSeats,
                      date: currentDate,
                      showTime: showTime,
                      ticketPrice: ticketPrice,
                    ),
                  ),
                );
              },
              child: Container(
                height: 40,
                width: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFFC9EED6),
                ),
                child: const Center(
                  child: Text(
                    "Book Selected Seats",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// import 'package:aarvi_cinema/ticket_summary_screen.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:intl/intl.dart';
//
// class BookNowSc extends StatefulWidget {
//   final String? movieName;
//
//   const BookNowSc({super.key, this.movieName});
//
//   @override
//   State<BookNowSc> createState() => _BookNowScState();
// }
//
// class _BookNowScState extends State<BookNowSc> {
//   final User? user = FirebaseAuth.instance.currentUser;
//   late final String email = user?.email ?? "Guest";
//
//   final int totalSeats = 50;
//   List<int> selectedSeats = [];
//   List<int> bookedSeats = [];
//
//   final DatabaseReference dbRef =
//   FirebaseDatabase.instance.ref("Bookings");
//
//   late String currentDate;
//   late String showTime;
//
//   @override
//   void initState() {
//     super.initState();
//     _setDateAndTime();
//     fetchBookedSeats();
//   }
//
//   /// Set current date & time partition
//   void _setDateAndTime() {
//     final now = DateTime.now();
//
//     currentDate = DateFormat('dd/MM/yy').format(now);
//
//     if (now.hour < 12) {
//       showTime = "10:00 AM";
//     } else if (now.hour < 17) {
//       showTime = "03:00 PM";
//     } else {
//       showTime = "07:00 PM";
//     }
//   }
//
//   /// Fetch booked seats for this movie + time
//   void fetchBookedSeats() async {
//     final snapshot = await dbRef
//         .child(widget.movieName ?? "DefaultMovie")
//         .child(showTime)
//         .child("seats")
//         .get();
//
//     if (snapshot.exists) {
//       final data = snapshot.value;
//       if (data is List) {
//         bookedSeats = data.whereType<int>().toList();
//       }
//       setState(() {});
//     }
//   }
//
//   /// Book seats
//   void bookSeats() async {
//     if (selectedSeats.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please select seats")),
//       );
//       return;
//     }
//
//     final bookingData = {
//       "userEmail": email,
//       "movieName": widget.movieName ?? "DefaultMovie",
//       "date": currentDate,
//       "showTime": showTime,
//       "seats": [...bookedSeats, ...selectedSeats],
//       "timestamp": ServerValue.timestamp,
//     };
//
//     await dbRef
//         .child(widget.movieName ?? "DefaultMovie")
//         .child(showTime)
//         .set(bookingData);
//
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (_) =>
//             TicketSummaryScreen(
//               userName: email,
//               movieName: widget.movieName ?? "DefaultMovie",
//                bookedSeats: selectedSeats,
//               // showDate: '', showTime: '', hall: '',   //this is chage arguments
//             ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF0B5D7E),
//         title: Text(
//           widget.movieName ?? "Aarvi Cinema",
//           style: const TextStyle(color: Color(0xFFC9EED6)),
//         ),
//         centerTitle: true,
//       ),
//       body: Center(
//           child: Column(
//               children: [
//               const SizedBox(height: 10),
//           Text(
//             "$currentDate   $showTime",
//             style: const TextStyle(fontSize: 20),
//           ),
//           const SizedBox(height: 10),
//
//           /// Seats Grid
//           Padding(
//             padding: const EdgeInsets.fromLTRB(30, 10, 30, 15),
//             child: GridView.builder(
//               shrinkWrap: true,
//               itemCount: totalSeats,
//               physics: const NeverScrollableScrollPhysics(),
//               gridDelegate:
//               const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 5,
//                 mainAxisExtent: 45,
//                 crossAxisSpacing: 10,
//                 mainAxisSpacing: 10,
//               ),
//               itemBuilder: (context, index) {
//                 final seatNumber = index + 1;
//                 final isBooked = bookedSeats.contains(seatNumber);
//                 final isSelected =
//                 selectedSeats.contains(seatNumber);
//
//                 return GestureDetector(
//                   onTap: () {
//                     if (isBooked) return;
//                     setState(() {
//                       isSelected
//                           ? selectedSeats.remove(seatNumber)
//                           : selectedSeats.add(seatNumber);
//                     });
//                   },
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: isBooked
//                           ? Colors.red
//                           : isSelected
//                           ? Colors.green
//                           : Colors.blueGrey,
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     child: Center(
//                       child: Text(
//                         "$seatNumber",
//                         style: const TextStyle(
//                             color: Colors.white, fontSize: 15),
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.only(left:55),
//             child: Row(children: [
//               Container(
//                 height: 18,
//                 width: 18,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(4),
//                     color: Colors.green,
//                 ),
//               ),
//               SizedBox(width: 5),
//               Text("Selected"),
//               SizedBox(width: 10,),
//               Container(
//                 height: 18,
//                 width: 18,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(4),
//                     color: Colors.blueGrey,
//                 ),
//               ),
//               SizedBox(width: 5),
//               Text("Available"),
//               SizedBox(width: 10,),
//               Container(
//                 height: 18,
//                 width: 18,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(4),
//                     color: Colors.red,
//                 ),
//               ),
//               SizedBox(width: 5),
//               Text("Booked"),
//             ],
//             ),
//           ),
//       SizedBox(height: 12),
//
//                 /// Book Button
//       GestureDetector(
//       onTap: bookSeats,
//       child: Container(
//         height: 40,
//         width: 250,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(20),
//           color: const Color(0xFFC9EED6),
//         ),
//         child: const Center(
//           child: Text(
//             "Book Selected Seats",
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//       ),
//     )
//
//     ],
//     )
//     ,
//     )
//     ,
//     );
//   }
// }
//
//
