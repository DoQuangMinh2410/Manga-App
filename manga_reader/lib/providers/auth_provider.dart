// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../services/firebase_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;

  AppUser? _user;
  AuthState _state = AuthState.initial;
  String _errorMessage = '';

  AuthProvider(this._firebaseService) {
    _init();
  }

  AppUser? get user => _user;
  AuthState get authState => _state;
  String get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _state == AuthState.loading;
  bool get isAdmin => _user?.isAdmin ?? false;

  // ─── Khởi tạo — lắng nghe auth state changes ────────────────────────────
  void _init() {
    _firebaseService.authStateStream.listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        _state = AuthState.loading;
        notifyListeners();
        try {
          _user = await _firebaseService.getUserProfile(firebaseUser.uid);
          _user ??= AppUser.fromFirebaseUser(firebaseUser);
          _state = AuthState.authenticated;
        } catch (_) {
          _user = AppUser.fromFirebaseUser(firebaseUser);
          _state = AuthState.authenticated;
        }
      } else {
        _user = null;
        _state = AuthState.unauthenticated;
      }
      notifyListeners();
    });
  }

  // ─── Đăng ký ─────────────────────────────────────────────────────────────
  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _state = AuthState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      _user = await _firebaseService.registerWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e.code);
      _state = AuthState.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Đăng ký thất bại. Vui lòng thử lại.';
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  // ─── Đăng nhập ───────────────────────────────────────────────────────────
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _state = AuthState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      _user = await _firebaseService.loginWithEmail(
        email: email,
        password: password,
      );
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e.code);
      _state = AuthState.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Đăng nhập thất bại. Vui lòng thử lại.';
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  // ─── Đăng xuất ───────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _firebaseService.signOut();
    _user = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  // ─── Gửi email reset mật khẩu ────────────────────────────────────────────
  Future<bool> sendPasswordReset(String email) async {
    try {
      await _firebaseService.sendPasswordReset(email);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Map Firebase error codes → Vietnamese messages ──────────────────────
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này';
      case 'wrong-password':
        return 'Mật khẩu không đúng';
      case 'email-already-in-use':
        return 'Email này đã được sử dụng';
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'weak-password':
        return 'Mật khẩu quá yếu (tối thiểu 6 ký tự)';
      case 'too-many-requests':
        return 'Quá nhiều lần thử. Vui lòng đợi một lúc';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Kiểm tra internet của bạn';
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không đúng';
      default:
        return 'Có lỗi xảy ra ($code). Thử lại sau.';
    }
  }

  void clearError() {
    _errorMessage = '';
    if (_state == AuthState.error) {
      _state = _user != null
          ? AuthState.authenticated
          : AuthState.unauthenticated;
    }
    notifyListeners();
  }
}
