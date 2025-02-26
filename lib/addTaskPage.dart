import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'task_bloc.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final List<String> _presetTasks = [
    "Meeting with client",
    "Workout session",
    "Complete project report",
    "Call with manager",
    "Grocery shopping",
    "Playing Cricket",
    "Job Interview"
  ];
  String? _selectedPresetTask;

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Add Task')),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _taskController,
                      decoration: InputDecoration(
                        hintText: 'Enter your task title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.task),
                      ),
                      autofocus: false,
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Or Select a task:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8.0,
                      children: _presetTasks.map((task) {
                        bool isSelected = _selectedPresetTask == task;
                        return ChoiceChip(
                          label: Text(task),
                          selected: isSelected,
                          selectedColor: Colors.blue.shade200,
                          onSelected: (selected) {
                            setState(() {
                              _selectedPresetTask = selected ? task : null;
                              _taskController.text = selected ? task : '';
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),

                    // Description Field
                    TextField(
                      maxLength: 100,
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: 'Enter task description (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        //prefixIcon: const Icon(Icons.description),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 10),

                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                        _selectedDate == null
                            ? 'Select Date'
                            : DateFormat('MMM d, yyyy').format(_selectedDate!),
                        style: const TextStyle(fontSize: 16),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _pickDate,
                    ),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: Text(
                        _selectedTime == null
                            ? 'Select Time'
                            : _selectedTime!.format(context),
                        style: const TextStyle(fontSize: 16),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _pickTime,
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_taskController.text.isNotEmpty &&
                              _selectedDate != null &&
                              _selectedTime != null) {
                            DateTime finalDateTime = DateTime(
                              _selectedDate!.year,
                              _selectedDate!.month,
                              _selectedDate!.day,
                              _selectedTime!.hour,
                              _selectedTime!.minute,
                            );

                            BlocProvider.of<TaskBloc>(context).add(
                              AddTaskEvent(Task(
                                title: _taskController.text,
                                description: _descriptionController.text,
                                dateTime: finalDateTime,
                              )),
                            );
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter task and select date & time')),
                            );
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Task'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
