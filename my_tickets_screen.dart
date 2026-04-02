

//16-03-26 change
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
//
// class MyTicketsScreen extends StatefulWidget {
//   const MyTicketsScreen({super.key});
//
//   @override
//   State<MyTicketsScreen> createState() => _MyTicketsScreenState();
// }
//
// class _MyTicketsScreenState extends State<MyTicketsScreen> {
//   final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
//   final User? user = FirebaseAuth.instance.currentUser;
//
//   List<Map<String, dynamic>> tickets = [];
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchTickets();
//   }
//
//   Future<void> fetchTickets() async {
//
//     final snapshot = await FirebaseDatabase.instance.ref('Bookings').get();
//
//     if (!snapshot.exists) {
//       setState(() => isLoading = false);
//       return;
//     }
//
//     for (var movie in snapshot.children) {
//       for (var month in movie.children) {
//         for (var day in month.children) {
//           for (var time in day.children) {
//             for (var booking in time.children) {
//
//               String? email = booking.child("userEmail").value?.toString();
//
//               if (email == user?.email) {
//
//                 String movieName =
//                 booking.child("movieName").value.toString();
//
//                 String date =
//                 booking.child("date").value.toString();
//
//                 String showTime =
//                 booking.child("showTime").value.toString();
//
//                 List seats = [];
//
//                 for (var s in booking.child("seats").children) {
//                   seats.add(s.value.toString());
//                 }
//
//                 tickets.add({
//                   "movie": movieName,
//                   "date": date,
//                   "time": showTime,
//                   "seats": seats.join(", ")
//                 });
//               }
//             }
//           }
//         }
//       }
//     }
//
//     setState(() => isLoading = false);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("My Tickets"),
//         centerTitle: true,
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : tickets.isEmpty
//           ? const Center(
//         child: Text(
//           "No tickets booked yet 🎟️",
//           style: TextStyle(fontSize: 16),
//         ),
//       )
//           : ListView.builder(
//         itemCount: tickets.length,
//         padding: const EdgeInsets.all(16),
//         itemBuilder: (context, index) {
//
//           final ticket = tickets[index];
//
//           return Card(
//             elevation: 4,
//             margin: const EdgeInsets.only(bottom: 16),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//
//                   Text(
//                     ticket["movie"],
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//
//                   const SizedBox(height: 8),
//
//                   Row(
//                     children: [
//
//                       const Icon(Icons.calendar_today, size: 16),
//                       const SizedBox(width: 5),
//                       Text(ticket["date"]),
//
//                       const SizedBox(width: 20),
//
//                       const Icon(Icons.access_time, size: 16),
//                       const SizedBox(width: 5),
//                       Text(ticket["time"]),
//                     ],
//                   ),
//
//                   const SizedBox(height: 8),
//
//                   Text(
//                     "Seats: ${ticket["seats"]}",
//                     style: const TextStyle(fontSize: 14),
//                   ),
//
//                   const SizedBox(height: 8),
//
//                   Text(
//                     "Booked by: ${user?.email ?? 'Guest'}",
//                     style: const TextStyle(
//                       fontSize: 13,
//                       color: Colors.grey,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }


// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
//
// class MyTicketsScreen extends StatefulWidget {
//   const MyTicketsScreen({super.key});
//
//   @override
//   State<MyTicketsScreen> createState() => _MyTicketsScreenState();
// }
//
// class _MyTicketsScreenState extends State<MyTicketsScreen> {
//   final DatabaseReference dbRef = FirebaseDatabase.instance.ref("Bookings");
//
//   final User? user = FirebaseAuth.instance.currentUser;
//
//   bool isLoading = true;
//   List<Map<String, dynamic>> myTickets = [];
//
//   @override
//   void initState() {
//     super.initState();
//     fetchMyTickets();
//   }
//
//   Future<void> fetchMyTickets() async {
//     final snapshot = await dbRef.get();
//
//     if (!snapshot.exists) {
//       setState(() => isLoading = false);
//       return;
//     }
//
//     final data = snapshot.value as Map<dynamic, dynamic>;
//
//     List<Map<String, dynamic>> tempTickets = [];
//
//     data.forEach((movieName, showTimes) {
//       if (showTimes is Map) {
//         showTimes.forEach((showTime, bookingData) {
//           if (bookingData is Map && bookingData["userEmail"] == user?.email) {
//             tempTickets.add({
//               "movieName": movieName,
//               "date": bookingData["date"],
//               "showTime": bookingData["showTime"],
//               "seats": List<int>.from(bookingData["seats"] ?? []),
//             });
//           }
//         });
//       }
//     });
//
//     setState(() {
//       myTickets = tempTickets;
//       isLoading = false;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("My Tickets"), centerTitle: true),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : myTickets.isEmpty
//           ? const Center(
//               child: Text(
//                 "No tickets booked yet 🎟️",
//                 style: TextStyle(fontSize: 16),
//               ),
//             )
//           : ListView.builder(
//               itemCount: myTickets.length,
//               padding: const EdgeInsets.all(16),
//               itemBuilder: (context, index) {
//                 final ticket = myTickets[index];
//
//                 return Card(
//                   elevation: 4,
//                   margin: const EdgeInsets.only(bottom: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         /// Movie Name
//                         Text(
//                           ticket["movieName"],
//                           style: const TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//
//                         const SizedBox(height: 8),
//
//                         /// Date & Time
//                         Row(
//                           children: [
//                             const Icon(Icons.calendar_today, size: 16),
//                             const SizedBox(width: 6),
//                             Text(ticket["date"]),
//                             const SizedBox(width: 16),
//                             const Icon(Icons.access_time, size: 16),
//                             const SizedBox(width: 6),
//                             Text(ticket["showTime"]),
//                           ],
//                         ),
//
//                         const SizedBox(height: 8),
//
//                         /// Seats
//                         Text(
//                           "Seats: ${ticket["seats"].join(', ')}",
//                           style: const TextStyle(fontSize: 14),
//                         ),
//
//                         const SizedBox(height: 8),
//
//                         /// User Email
//                         Text(
//                           "Booked by: ${user?.email}",
//                           style: const TextStyle(
//                             fontSize: 13,
//                             color: Colors.grey,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//     );
//   }
// }

/*   10-02-26 updated a last friday ticket price disscount  */

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
//
// class MyTicketsScreen extends StatefulWidget {
//   const MyTicketsScreen({super.key});
//
//   @override
//   State<MyTicketsScreen> createState() => _MyTicketsScreenState();
// }
//
// class _MyTicketsScreenState extends State<MyTicketsScreen> {
//   final DatabaseReference dbRef =
//   FirebaseDatabase.instance.ref("Bookings");
//
//   final User? user = FirebaseAuth.instance.currentUser;
//
//   bool isLoading = true;
//   List<Map<String, dynamic>> myTickets = [];
//
//   /// ✅ Check if date is last Friday of month
//   bool isLastFriday(DateTime date) {
//     if (date.weekday != DateTime.friday) return false;
//     final nextWeek = date.add(const Duration(days: 7));
//     return nextWeek.month != date.month;
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     fetchMyTickets();
//   }
//
//   Future<void> fetchMyTickets() async {
//     final snapshot = await dbRef.get();
//
//     if (!snapshot.exists) {
//       setState(() => isLoading = false);
//       return;
//     }
//
//     final data = snapshot.value as Map<dynamic, dynamic>;
//     List<Map<String, dynamic>> tempTickets = [];
//
//     data.forEach((movieName, showTimes) {
//       if (showTimes is Map) {
//         showTimes.forEach((showTime, bookingData) {
//           if (bookingData is Map &&
//               bookingData["userEmail"] == user?.email) {
//
//             final DateTime bookingDate =
//             DateTime.parse(bookingData["date"]); // yyyy-MM-dd
//
//             final int originalPrice = bookingData["price"] ?? 0;
//
//             final bool discountApplied =
//             isLastFriday(bookingDate);
//
//             final double finalPrice = discountApplied
//                 ? originalPrice * 0.8 // 20% discount
//                 : originalPrice.toDouble();
//
//             tempTickets.add({
//               "movieName": movieName,
//               "date": bookingData["date"],
//               "showTime": bookingData["showTime"],
//               "seats": List<int>.from(bookingData["seats"] ?? []),
//               "originalPrice": originalPrice,
//               "finalPrice": finalPrice,
//               "discount": discountApplied,
//             });
//           }
//         });
//       }
//     });
//
//     setState(() {
//       myTickets = tempTickets;
//       isLoading = false;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("My Tickets"),
//         centerTitle: true,
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : myTickets.isEmpty
//           ? const Center(
//         child: Text(
//           "No tickets booked yet 🎟️",
//           style: TextStyle(fontSize: 16),
//         ),
//       )
//           : ListView.builder(
//         itemCount: myTickets.length,
//         padding: const EdgeInsets.all(16),
//         itemBuilder: (context, index) {
//           final ticket = myTickets[index];
//
//           return Card(
//             elevation: 4,
//             margin: const EdgeInsets.only(bottom: 16),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   /// 🎬 Movie Name
//                   Text(
//                     ticket["movieName"],
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//
//                   const SizedBox(height: 8),
//
//                   /// 📅 Date & Time
//                   Row(
//                     children: [
//                       const Icon(Icons.calendar_today, size: 16),
//                       const SizedBox(width: 6),
//                       Text(ticket["date"]),
//                       const SizedBox(width: 16),
//                       const Icon(Icons.access_time, size: 16),
//                       const SizedBox(width: 6),
//                       Text(ticket["showTime"]),
//                     ],
//                   ),
//
//                   const SizedBox(height: 8),
//
//                   /// 💺 Seats
//                   Text(
//                     "Seats: ${ticket["seats"].join(', ')}",
//                   ),
//
//                   const SizedBox(height: 8),
//
//                   /// 💰 Price + Discount
//                   Row(
//                     children: [
//                       Text(
//                         "₹${ticket["finalPrice"].toStringAsFixed(0)}",
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(width: 10),
//
//                       if (ticket["discount"] == true)
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 8, vertical: 4),
//                           decoration: BoxDecoration(
//                             color: Colors.green,
//                             borderRadius:
//                             BorderRadius.circular(6),
//                           ),
//                           child: const Text(
//                             "Last Friday Offer 🎉",
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//
//                   const SizedBox(height: 8),
//
//                   /// 👤 User
//                   Text(
//                     "Booked by: ${user?.email}",
//                     style: const TextStyle(
//                       fontSize: 13,
//                       color: Colors.grey,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
  final User? user = FirebaseAuth.instance.currentUser;

  Map<String, List<int>> tickets = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTickets();
  }

  Future<void> fetchTickets() async {
    final snapshot =
    await FirebaseDatabase.instance.ref('Bookings').get();

    if (!snapshot.exists) {
      setState(() => isLoading = false);
      return;
    }

    final data = snapshot.value as Map<dynamic, dynamic>;

    data.forEach((movieName, seatMap) {
      if (seatMap is Map) {
        // Convert {0:1, 1:2, 2:3} → [1,2,3]
        tickets[movieName.toString()] =
            seatMap.values.whereType<int>().toList();
      }
    });

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Tickets"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tickets.isEmpty
          ? const Center(
        child: Text(
          "No tickets booked yet 🎟️",
          style: TextStyle(fontSize: 16),
        ),
      )
          : ListView.builder(
        itemCount: tickets.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final movieName = tickets.keys.elementAt(index);
          final seats = tickets[movieName]!;

          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movieName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Text(
                  //   "Seats: ${seats.join(', ')}",
                  //   style: const TextStyle(fontSize: 14),
                  // ),
                  const SizedBox(height: 8),
                  Text(
                    "Booked by: ${user?.email ?? 'Guest'}",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
