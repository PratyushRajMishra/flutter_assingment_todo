import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Task Model
class Task extends Equatable {
  final String title;
  final DateTime dateTime;
  final String description; // Added description field

  Task({
    required this.title,
    required this.dateTime,
    required this.description, // Ensure it's required
  });

  @override
  List<Object> get props => [title, dateTime, description];
}

// Define the events
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
  final Task task;
  DeleteTaskEvent(this.task);

  @override
  List<Object> get props => [task];
}

// Define the states
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

// Bloc Implementation
class TaskBloc extends Bloc<TaskEvent, TaskState> {
  List<Task> taskList = [];

  TaskBloc() : super(TaskInitial()) {
    on<LoadTasksEvent>((event, emit) {
      emit(TaskLoaded(List.from(taskList)));
    });

    on<AddTaskEvent>((event, emit) {
      taskList.add(event.task);
      emit(TaskLoaded(List.from(taskList)));
    });

    on<DeleteTaskEvent>((event, emit) {
      taskList.removeWhere((task) => task.title == event.task.title);
      emit(TaskLoaded(List.from(taskList)));
    });
  }
}
