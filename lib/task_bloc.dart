import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Task Model
class Task extends Equatable {
  final String id;
  final String title;
  final DateTime dateTime;
  final String description;

  Task({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.description,
  });

  // Convert Firestore document to Task object
  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      dateTime: _convertToDateTime(data['dateTime']),
    );
  }

  // Convert various types (String or Timestamp) to DateTime safely
  static DateTime _convertToDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    } else {
      throw Exception("Invalid date format: $value");
    }
  }

  // Convert Task object to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'dateTime':
          Timestamp.fromDate(dateTime), // Ensures Firestore stores as Timestamp
      'createdAt': Timestamp.now(), // Added for sorting
    };
  }

  @override
  List<Object> get props => [id, title, dateTime, description];
}

// Define Events
abstract class TaskEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadTasksEvent extends TaskEvent {}

class AddTaskEvent extends TaskEvent {
  final Task task;
  AddTaskEvent(this.task);

  @override
  List<Object> get props => [task];
}

class DeleteTaskEvent extends TaskEvent {
  final String taskId;
  DeleteTaskEvent(this.taskId);

  @override
  List<Object> get props => [taskId];
}

// Define States
abstract class TaskState extends Equatable {
  @override
  List<Object> get props => [];
}

class TaskInitial extends TaskState {}

class TaskLoaded extends TaskState {
  final List<Task> tasks;
  TaskLoaded(this.tasks);

  @override
  List<Object> get props => [tasks];
}

class TaskError extends TaskState {
  final String message;
  TaskError(this.message);

  @override
  List<Object> get props => [message];
}

// Bloc Implementation
class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  TaskBloc() : super(TaskInitial()) {
    on<LoadTasksEvent>(_loadTasks);
    on<AddTaskEvent>(_onAddTask);
    on<DeleteTaskEvent>(_onDeleteTask);
  }

  // Get the reference to the user's task collection
  CollectionReference _getUserTaskCollection() {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    return _firestore.collection('users').doc(user.uid).collection('tasks');
  }

  // Load tasks from Firestore
  Future<void> _loadTasks(LoadTasksEvent event, Emitter<TaskState> emit) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      emit(TaskError("User not logged in"));
      return;
    }

    try {
      QuerySnapshot taskSnapshot = await _getUserTaskCollection()
          .orderBy('createdAt',
              descending: true) // Ensures recent tasks show first
          .get();

      List<Task> tasks = taskSnapshot.docs
          .map((doc) {
            try {
              return Task.fromFirestore(doc);
            } catch (e) {
              print("Skipping task due to error: $e");
              return null; // Ignore invalid tasks
            }
          })
          .whereType<Task>()
          .toList();

      print("Tasks fetched: ${tasks.length}");
      emit(TaskLoaded(tasks));
    } catch (e) {
      print("Error loading tasks: $e");
      emit(TaskError("Failed to load tasks"));
    }
  }

  // Add task to Firestore
  Future<void> _onAddTask(AddTaskEvent event, Emitter<TaskState> emit) async {
    try {
      print("Adding Task: ${event.task.toFirestore()}");

      DocumentReference docRef =
          await _getUserTaskCollection().add(event.task.toFirestore());

      Task newTask = Task(
        id: docRef.id,
        title: event.task.title,
        dateTime: event.task.dateTime,
        description: event.task.description,
      );

      final currentState = state;
      if (currentState is TaskLoaded) {
        List<Task> updatedTasks = List.from(currentState.tasks)..add(newTask);
        print("Updated Task List: ${updatedTasks.length}");
        emit(TaskLoaded(updatedTasks));
      } else {
        emit(TaskLoaded([newTask]));
      }
    } catch (e) {
      print("Error adding task: $e");
      emit(TaskError("Failed to add task"));
    }
  }

  // Delete task from Firestore
  Future<void> _onDeleteTask(
      DeleteTaskEvent event, Emitter<TaskState> emit) async {
    try {
      await _getUserTaskCollection().doc(event.taskId).delete();
      final currentState = state;
      if (currentState is TaskLoaded) {
        emit(TaskLoaded(currentState.tasks
            .where((task) => task.id != event.taskId)
            .toList()));
      }
    } catch (e) {
      emit(TaskError("Failed to delete task"));
    }
  }
}
