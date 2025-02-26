import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_assingment_todo/profilePage.dart';
import 'package:flutter_assingment_todo/taskDetailPage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'addTaskPage.dart';
import 'task_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String initials = ""; // Store user initials

  @override
  void initState() {
    super.initState();
    _fetchUserInitials();
  }

  Future<void> _fetchUserInitials() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        String firstName = userDoc['firstName'] ?? "";
        String lastName = userDoc['lastName'] ?? "";

        setState(() {
          initials = "${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}".toUpperCase();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Todo List',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 3,
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blueAccent,
                radius: 18,
                child: Text(
                  initials,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          if (state is TaskLoaded) {
            final tasks = state.tasks
                .where((task) => task.dateTime.isAfter(DateTime.now()))
                .toList()
              ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

            if (tasks.isEmpty) {
              return _buildEmptyTaskView();
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return TaskCard(task: tasks[index]);
              },
            );
          } else {
            return _buildEmptyTaskView();
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTaskPage()),
          );
        },
        icon: const Icon(Icons.add_circle, size: 23, color: Colors.white),
        label: const Text('Add Task', style: TextStyle(color: Colors.white, fontSize: 17)),
      ),
    );
  }

  Widget _buildEmptyTaskView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.playlist_add, size: 60, color: Colors.grey),
          const SizedBox(height: 12),
          const Text(
            "No tasks available!",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          const Text(
            "Tap the 'Add Task' button below to create your first task.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}


class TaskCard extends StatefulWidget {
  final Task task;

  const TaskCard({super.key, required this.task});

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  late Timer _timer;
  late String _countdownText;

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateCountdown();
      }
    });
  }

  void _updateCountdown() {
    if (mounted) {
      setState(() {
        _countdownText = _getTimeRemaining(widget.task.dateTime);
        if (_countdownText == "Task Expired") {
          _removeTask();
        }
      });
    }
  }

  void _removeTask() {
    if (mounted) {
      context.read<TaskBloc>().add(DeleteTaskEvent(widget.task));
    }
  }

  String _getTimeRemaining(DateTime dueDate) {
    Duration difference = dueDate.difference(DateTime.now());
    if (difference.isNegative) {
      return "Task Expired";
    }

    int days = difference.inDays;
    int hours = difference.inHours % 24;
    int minutes = difference.inMinutes % 60;
    int seconds = difference.inSeconds % 60;

    if (days > 0) {
      return "$days days, $hours hrs left";
    } else if (hours > 0) {
      return "$hours hrs, $minutes min left";
    } else if (minutes > 0) {
      return "$minutes min, $seconds sec left";
    } else {
      return "$seconds sec left";
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isExpired = _countdownText == "Task Expired";

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailsPage(task: widget.task),
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: isExpired ? Colors.redAccent : Colors.teal,
          radius: 25,
          child: Icon(
            isExpired ? Icons.error_outline : Icons.check_circle,
            color: Colors.white,
            size: 28,
          ),
        ),
        title: Text(
          widget.task.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Due: ${DateFormat('MMM d, yyyy - h:mm a').format(widget.task.dateTime)}",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: isExpired ? Colors.redAccent : Colors.teal,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _countdownText,
                  style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 15, color: Colors.black54,)
      ),
    );
  }
}
