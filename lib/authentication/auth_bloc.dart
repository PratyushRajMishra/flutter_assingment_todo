import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

class GoogleSignInEvent extends AuthEvent {}

class LogoutEvent extends AuthEvent {}

/// AUTH STATES
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  final Map<String, dynamic> userData;

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
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthBloc() : super(AuthInitial()) {
    on<SignupEvent>(_onSignup);
    on<LoginEvent>(_onLogin);
    on<GoogleSignInEvent>(_onGoogleSignIn);
    on<LogoutEvent>(_onLogout);
  }

  /// ✅ SIGNUP WITH EMAIL/PASSWORD
  Future<void> _onSignup(SignupEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      User? user = userCredential.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'firstName': event.firstName,
          'lastName': event.lastName,
          'email': event.email,
          'createdAt': Timestamp.now(),
        });
        emit(AuthInitial());
      }
    } catch (e) {
      emit(AuthFailure(message: "Signup failed: ${e.toString()}"));
    }
  }

  /// ✅ LOGIN WITH EMAIL/PASSWORD
  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      User? user = userCredential.user;
      if (user != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        Map<String, dynamic> userData =
            userDoc.data() as Map<String, dynamic>? ?? {};
        emit(AuthAuthenticated(user: user, userData: userData));
      }
    } catch (e) {
      emit(AuthFailure(message: "Login failed: ${e.toString()}"));
    }
  }

  /// ✅ GOOGLE SIGN-IN
  Future<void> _onGoogleSignIn(
      GoogleSignInEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        emit(AuthFailure(message: "Google sign-in cancelled"));
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // Check if user exists in Firestore
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'firstName': googleUser.displayName?.split(' ')[0] ?? '',
            'lastName': googleUser.displayName?.split(' ')[1] ?? '',
            'email': googleUser.email,
            'createdAt': Timestamp.now(),
          });
        }

        // Fetch updated user data
        userDoc = await _firestore.collection('users').doc(user.uid).get();
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        emit(AuthAuthenticated(user: user, userData: userData));
      }
    } catch (e) {
      emit(AuthFailure(message: "Google Sign-In failed: ${e.toString()}"));
    }
  }

  /// ✅ LOGOUT
  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      emit(AuthInitial());
    } catch (e) {
      emit(AuthFailure(message: "Logout failed: ${e.toString()}"));
    }
  }
}
