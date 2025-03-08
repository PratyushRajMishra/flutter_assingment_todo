import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// ✅ Event for Email/Password Login
class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  LoginEvent({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// ✅ Event for Signup with Email/Password
class SignupEvent extends AuthEvent {
  final String firstName;
  final String lastName;
  final String email;
  final String password;

  SignupEvent({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [firstName, lastName, email, password];
}

/// ✅ Event for Logout
class LogoutEvent extends AuthEvent {}

/// ✅ Event for Google Sign-In
class GoogleSignInEvent extends AuthEvent {}
