import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_assingment_todo/addTaskPage.dart';

import 'package:flutter_assingment_todo/taskDetailPage.dart';
import 'package:flutter_assingment_todo/task_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class Tasklistpage extends StatefulWidget {
  const Tasklistpage({super.key});

  @override
  State<Tasklistpage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<Tasklistpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'ToDo',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 3,
      ),
      body: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          // Show CircularProgressIndicator if tasks are still loading.
          if (state is TaskInitial) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TaskError) {
            return Center(child: Text(state.message));
          } else if (state is TaskLoaded) {
            // Filter tasks that are not expired.
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
      floatingActionButton: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 160, // Adjust width to match button size
            height: 56, // Adjust height to match button size
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30), // Rounded corners
            ),
          ),
          FloatingActionButton.extended(
            backgroundColor: Colors.transparent, // Transparent to show gradient
            elevation: 0, // Remove elevation for better blending
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddTaskPage()),
              );
              context.read<TaskBloc>().add(LoadTasksEvent());
            },
            icon: const Icon(Icons.add_circle, size: 23, color: Colors.white),
            label: const Text(
              'Add Task',
              style: TextStyle(color: Colors.white, fontSize: 17),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTaskView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.playlist_add, size: 60, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            "No tasks available!",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black54),
          ),
          SizedBox(height: 8),
          Text(
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
  bool _deletionScheduled = false; // Ensure deletion is scheduled only once

  @override
  void initState() {
    super.initState();
    _countdownText = _getTimeRemaining(widget.task.dateTime);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      String newCountdown = _getTimeRemaining(widget.task.dateTime);
      setState(() {
        _countdownText = newCountdown;
      });
      if (newCountdown == "Task Expired" && !_deletionScheduled) {
        _deletionScheduled = true;
        _timer.cancel();
        // Delay deletion by 3 seconds so user can see "Task Expired"
        Future.delayed(const Duration(seconds: 3), () {
          context.read<TaskBloc>().add(DeleteTaskEvent(widget.task.id));
        });
      }
    });
  }

  String _getTimeRemaining(DateTime dueDate) {
    Duration difference = dueDate.difference(DateTime.now());
    if (difference.isNegative) return "Task Expired";

    int days = difference.inDays;
    int hours = difference.inHours % 24;
    int minutes = difference.inMinutes % 60;
    int seconds = difference.inSeconds % 60;

    if (days > 0) return "$days days, $hours hrs left";
    if (hours > 0) return "$hours hrs, $minutes min left";
    if (minutes > 0) return "$minutes min, $seconds sec left";
    return "$seconds sec left";
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
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
                  style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 15, color: Colors.black54),
      ),
    );
  }
}
