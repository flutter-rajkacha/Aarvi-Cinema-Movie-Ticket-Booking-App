import 'package:flutter/material.dart';

class HelpsupportScreen extends StatefulWidget {
  const HelpsupportScreen({super.key});

  @override
  State<HelpsupportScreen> createState() => _HelpsupportScreenState();
}

class _HelpsupportScreenState extends State<HelpsupportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0B5D7E),
        title: Text(
          "Help & Support",
          style: TextStyle(color: Color(0xFFC9EED6)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
        child: Center(
          child: ListView(
            children: [
              Text(
                'Need Help?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'You can contact us via email or phone, or check our FAQs below.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.email),
                title: Text('aarvicinema@gmail.com'),
                onTap: () {
                  // Optional: launch email
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
