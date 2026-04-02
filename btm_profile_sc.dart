import 'package:aarvi_cinema/HelpSupport_Screen.dart';
import 'package:aarvi_cinema/settings_menu_profile.dart';
import 'package:aarvi_cinema/ticket_summary_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'ReviewScreen.dart';
import 'firebase/auth_service.dart';
import 'login_sc.dart';
import 'my_tickets_screen.dart';

class BtmProfileSc extends StatefulWidget {
  const BtmProfileSc({super.key});

  @override
  State<BtmProfileSc> createState() => _BtmProfileScState();
}

class _BtmProfileScState extends State<BtmProfileSc> {
  late String loggedInUser;
  final List<IconData> icons = [
    Icons.person,
    Icons.settings,
    Icons.note_alt,
    Icons.favorite,
    Icons.contact_support_outlined,
  ];

  final List<String> titles = [
    'Profile',
    'Settings',
    'Ticket Details',
    'Review',
    'Help & Support',
  ];

  String? get userName => null;

  String? get movieName => null;

  List<int>? get bookedSeats => null;

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    // final String userName = user?.displayName ?? 'Guest';
    final String email = user?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          const SizedBox(height: 20),

          /// PROFILE IMAGE
          CircleAvatar(
            radius: 55,
            backgroundColor: Colors.teal.shade100,
            backgroundImage: const AssetImage("assets/user profile photo.png"),
          ),

          const SizedBox(height: 12),

          /// USER NAME
          if (email.isNotEmpty)
            Text(email, style: const TextStyle(color: Colors.grey)),

          const SizedBox(height: 25),

          /// OPTIONS LIST
          Expanded(
            child: ListView.builder(
              itemCount: titles.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF0B5D7E),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal.shade50,
                        child: Icon(icons[index], color: Colors.teal),
                      ),
                      title: Text(
                        index == 0 ? email : titles[index],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        if (index == 1) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsMenuScreen(),
                            ),
                          );
                        } else if (index == 2) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MyTicketsScreen(),
                            ),
                          );
                        } else if (index == 3) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ReviewScreen()),
                          );
                        } else if (index == 4) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HelpsupportScreen(),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          /// LOGOUT BUTTON
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFC9EED6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  await AuthService().signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => LoginSc()),
                    (route) => false,
                  );
                },
                child: const Text(
                  "Logout",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B5D7E),
                    // color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'firebase/auth_service.dart';
// import 'login_sc.dart';
// class BtmProfileSc extends StatefulWidget {
//   const BtmProfileSc({super.key});
//
//   @override
//   State<BtmProfileSc> createState() => _BtmProfileScState();
// }
//
// class _BtmProfileScState extends State<BtmProfileSc> {
//   List i=[
//     Icons.add,
//     Icons.settings,
//     Icons.note_alt,
//     Icons.favorite,
//     Icons.contact_support_outlined,
//   ];
//
//   List a=[
//     FirebaseAuth.instance.currentUser?.displayName ?? 'Guest',
//     'Settings',
//     'E-Statement',
//     'Refferal Code',
//     'Help & Support',
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         children: [
//           SizedBox(height: 40),
//           Container(
//             height: 110,
//             width: 110,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: Color(0xFFC9EED6),
//               image: DecorationImage(image: AssetImage("assets/profile.png"), fit: BoxFit.cover),
//             ),
//           ),
//           SizedBox(height: 40,),
//           Expanded(
//             child: ListView.builder(
//                 itemCount: a.length,
//                 itemBuilder: (context, index) {
//                   return Padding(
//                     padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
//                     child: Container(
//                     height: 50,
//                       width: 45,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(10),
//                         color: Color(0xFFC9EED6),
//                       ),
//                         child: Row(
//                           children: [
//                         Padding(
//                           padding: const EdgeInsets.fromLTRB(15,10, 10, 10),
//                           child: Container(
//                             height: 30,
//                             width:30,
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(5),
//                               color: Colors.blueAccent,
//                             ),
//                             child: Icon(i[index],color: Color(0xFFC9EED6)),
//                           ),
//                         ),
//                         Text(a[index],style: TextStyle(
//                           color: Colors.blueGrey,
//                           fontWeight: FontWeight.bold,
//                         ),),
//                       ],
//                         )
//                     ),
//                   );
//                   },
//             ),
//           ),
//           TextButton(onPressed: () async{
//             final message=await AuthService().signOut();
//             print("Logout");
//             Navigator.push(context, MaterialPageRoute(builder: (context) => LoginSc(),));
//           }, child: Text("Logout",style:
//           TextStyle(
//             fontSize: 20,
//             color: Colors.blue,
//             fontWeight: FontWeight.bold,
//           ),))
//           ]
//       ),
//     );
//   }
// }
