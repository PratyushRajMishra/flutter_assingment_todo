import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_assingment_todo/tabs/notificationsPage.dart';
import 'package:flutter_assingment_todo/tabs/taskListPage.dart';
import 'package:flutter_assingment_todo/task_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'tabs/profilePage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String initials = ""; // Store user initials

  final List<Widget> _pages = [
    Tasklistpage(),
    Notificationspage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserInitials();
    // Trigger loading tasks as soon as the widget builds.
    Future.delayed(Duration.zero, () {
      context.read<TaskBloc>().add(LoadTasksEvent());
    });
  }

  /// Fetch user's first and last name from Firestore
  Future<void> _fetchUserInitials() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        String firstName = userDoc['firstName'] ?? "";
        String lastName = userDoc['lastName'] ?? "";
        setState(() {
          initials =
              "${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}"
                  .toUpperCase();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Tasks',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              radius: 12,
              child: Text(
                initials.isNotEmpty ? initials : 'U', // Default if empty
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            label: 'Profile',
          ),
        ],
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
