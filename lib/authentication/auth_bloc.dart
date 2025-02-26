import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// AUTH EVENTS
abstract class AuthEvent extends Equatable {
  @override
  List<Object> get props => [];
}

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
  List<Object> get props => [firstName, lastName, email, password];
}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  LoginEvent({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class LogoutEvent extends AuthEvent {}

/// AUTH STATES
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

/// ✅ Updated AuthAuthenticated to include Firestore user data
class AuthAuthenticated extends AuthState {
  final User user;
  final Map<String, dynamic> userData; // Store Firestore user data

  AuthAuthenticated({required this.user, required this.userData});

  @override
  List<Object?> get props => [user, userData];
}

class AuthFailure extends AuthState {
  final String message;

  AuthFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

/// AUTH BLOC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthBloc() : super(AuthInitial()) {
    on<SignupEvent>(_onSignup);
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
  }

  /// ✅ SIGNUP (Store user data in Firestore)
  Future<void> _onSignup(SignupEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // ✅ Store user data in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'firstName': event.firstName,
          'lastName': event.lastName,
          'email': event.email,
          'createdAt': Timestamp.now(),
        });

        // ✅ Retrieve stored user data
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>? ?? {};

        emit(AuthAuthenticated(user: user, userData: userData));
      }
    } catch (e) {
      emit(AuthFailure(message: "Signup failed: ${e.toString()}"));
    }
  }

  /// ✅ LOGIN (Retrieve user data from Firestore)
  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      User? user = userCredential.user;
      if (user != null) {
        // ✅ Fetch user data from Firestore
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>? ?? {};

        emit(AuthAuthenticated(user: user, userData: userData));
      } else {
        emit(AuthFailure(message: "Login failed: User not found"));
      }
    } catch (e) {
      emit(AuthFailure(message: "Login failed: ${e.toString()}"));
    }
  }

  /// ✅ LOGOUT FUNCTION
  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    try {
      await _auth.signOut();
      emit(AuthInitial());
    } catch (e) {
      emit(AuthFailure(message: "Logout failed: ${e.toString()}"));
    }
  }
}
