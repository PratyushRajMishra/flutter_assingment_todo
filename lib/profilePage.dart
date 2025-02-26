import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import '../authentication/auth_bloc.dart'; // Import AuthBloc

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            final User user = state.user;
            final Map<String, dynamic> userData = state.userData; // ✅ Firestore user data

            // Extract initials from Firestore data
            String initials = "U";
            if (userData.containsKey('firstName') && userData.containsKey('lastName')) {
              initials = "${userData['firstName'][0]}${userData['lastName'][0]}".toUpperCase();
            }

            // ✅ Format the joining date
            String joiningDate = "Not Available";
            if (userData.containsKey('createdAt') && userData['createdAt'] != null) {
              Timestamp timestamp = userData['createdAt'] as Timestamp;
              DateTime date = timestamp.toDate();
              joiningDate = DateFormat.yMMMMd().format(date); // Format as "January 1, 2024"
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.blueAccent,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Name: ${userData['firstName'] ?? 'Not Available'} ${userData['lastName'] ?? ''}",
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Email: ${user.email ?? 'Not Available'}",
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Joining Date: $joiningDate", // ✅ Display formatted joining date
                    style: const TextStyle(fontSize: 18),
                  ),
                  const Spacer(),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<AuthBloc>().add(LogoutEvent());
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      child: const Text("Logout", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: Text("User not authenticated"));
          }
        },
      ),
    );
  }
}
