import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class TicketScreen extends StatefulWidget {
  const TicketScreen({super.key});

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {

  final DatabaseReference dbRef =
  FirebaseDatabase.instance.ref("Bookings");

  List<Map> tickets = [];

  @override
  void initState() {
    super.initState();
    fetchTickets();
  }

  void fetchTickets() async {

    String? email = FirebaseAuth.instance.currentUser?.email;

    final snapshot = await dbRef.get();

    if (snapshot.exists) {

      for (var movie in snapshot.children) {
        for (var month in movie.children) {
          for (var day in month.children) {
            for (var time in day.children) {
              for (var booking in time.children) {

                String? userEmail =
                booking.child("userEmail").value.toString();

                if (userEmail == email) {

                  List seats = [];

                  for (var s in booking.child("seats").children) {
                    seats.add(s.value.toString());
                  }

                  tickets.add({
                    "movie": booking.child("movieName").value,
                    "date": booking.child("date").value,
                    "time": booking.child("showTime").value,
                    "seats": seats.join(", ")
                  });

                }
              }
            }
          }
        }
      }

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Tickets"),
      ),

      body: ListView.builder(
        itemCount: tickets.length,
        itemBuilder: (context, index) {

          var ticket = tickets[index];

          return Card(
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    ticket["movie"],
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(Icons.calendar_today,size:16),
                      const SizedBox(width:6),
                      Text(ticket["date"].toString()),
                      const SizedBox(width:20),
                      const Icon(Icons.access_time,size:16),
                      const SizedBox(width:6),
                      Text(ticket["time"].toString()),
                    ],
                  ),

                  const SizedBox(height:8),

                  Text("Seats: ${ticket["seats"]}"),

                  const SizedBox(height:6),

                  Text(
                    "Booked by: ${FirebaseAuth.instance.currentUser?.email}",
                    style: const TextStyle(
                        color: Colors.grey),
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