import 'package:aarvi_cinema/btm_profile_sc.dart';
import 'package:aarvi_cinema/home_bottom_sc.dart';
import 'package:aarvi_cinema/movies_bottom_sc.dart';
import 'package:aarvi_cinema/settings_menu_profile.dart';
import 'package:aarvi_cinema/ticket_screen.dart';
import 'package:flutter/material.dart';

import 'my_tickets_screen.dart';

class BottomNavigationSc extends StatefulWidget {
  const BottomNavigationSc({super.key});

  @override
  State<BottomNavigationSc> createState() => _BottomNavigationScState();
}

class _BottomNavigationScState extends State<BottomNavigationSc> {
  int currentitem = 0;
  List Screenlist = [HomeBottomSc(), MoviesBottomSc(), BtmProfileSc()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0B5D7E),
        title: Text("Aarvi Cinema", style: TextStyle(color: Color(0xFFC9EED6))),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: Container(
          color: Color.fromRGBO(20, 60, 90, 10),
          child: ListView(
            children: [
              DrawerHeader(
                child: Center(
                  child: Text(
                    "Aarvi Cinema",
                    style: TextStyle(
                      fontSize: 30,
                      color: Color(0xFFC9EED6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.home, color: Colors.white),
                title: Text('Home', style: TextStyle(color: Colors.teal[200])),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => HomeBottomSc()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.settings, color: Colors.white),
                title: Text(
                  'Settings',
                  style: TextStyle(color: Colors.teal[200]),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SettingsMenuScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.library_add_check_outlined,
                  color: Colors.white,
                ),
                title: Text(
                  'Tickets',
                  style: TextStyle(color: Colors.teal[200]),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => MyTicketsScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.movie_creation_outlined),
            label: "Movies",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.man), label: "Profile"),
        ],
        unselectedItemColor: Colors.grey,
        //Color(0xFFC9EED6),
        selectedItemColor: Color(0xFF0B5D7E),
        onTap: (value) {
          setState(() {
            currentitem = value;
          });
        },
        currentIndex: currentitem,
      ),
      body: Screenlist[currentitem],
    );
  }
}
