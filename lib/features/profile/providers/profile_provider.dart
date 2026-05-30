import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/patient_profile.dart';
import '../data/profile_repository.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider(this._repository);

  final ProfileRepository _repository;

  PatientProfile? _profile;
  String? _loadedUserId;
  bool _hasLoaded = false;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isAvatarSaving = false;
  String? _error;

  PatientProfile? get profile => _profile;
  String? get loadedUserId => _loadedUserId;
  bool get hasLoaded => _hasLoaded;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isAvatarSaving => _isAvatarSaving;
  String? get error => _error;
  bool get needsCompletion => _profile == null || !_profile!.isComplete;

  Future<void> load(String userId) async {
    _profile = null;
    _loadedUserId = null;
    _hasLoaded = false;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _profile = await _repository.fetchMyProfile();
      _loadedUserId = userId;
      _hasLoaded = true;
    } catch (_) {
      _error = 'Gagal memuat profil pasien.';
      _loadedUserId = userId;
      _hasLoaded = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    required String phoneNumber,
    required String gender,
    DateTime? birthDate,
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      _profile = await _repository.updateMyProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
        gender: gender,
        birthDate: birthDate,
      );
      _loadedUserId = _profile?.id;
      _hasLoaded = true;
      return true;
    } on PostgrestException catch (error) {
      final message = error.message.toLowerCase();
      if (message.contains('row-level security') ||
          message.contains('violates row-level')) {
        _error =
            'Profil belum bisa dibuat ulang karena policy Supabase belum aktif. Jalankan patch profile self-recovery di SQL Editor.';
      } else {
        _error = error.message;
      }
      return false;
    } catch (_) {
      _error = 'Gagal menyimpan profil pasien.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateAvatarUrl(String avatarUrl) async {
    _isAvatarSaving = true;
    _error = null;
    notifyListeners();
    try {
      _profile = await _repository.updateMyAvatarUrl(avatarUrl);
      _loadedUserId = _profile?.id;
      _hasLoaded = true;
      return true;
    } on PostgrestException catch (error) {
      _error = error.message;
      return false;
    } catch (_) {
      _error = 'Gagal menyimpan avatar pasien.';
      return false;
    } finally {
      _isAvatarSaving = false;
      notifyListeners();
    }
  }

  Future<bool> uploadAvatar({
    required Uint8List bytes,
    required String extension,
  }) async {
    _isAvatarSaving = true;
    _error = null;
    notifyListeners();
    try {
      _profile = await _repository.uploadAvatar(
        bytes: bytes,
        extension: extension,
      );
      _loadedUserId = _profile?.id;
      _hasLoaded = true;
      return true;
    } on StorageException catch (error) {
      _error = error.message;
      return false;
    } catch (_) {
      _error = 'Gagal mengunggah avatar pasien.';
      return false;
    } finally {
      _isAvatarSaving = false;
      notifyListeners();
    }
  }

  Future<bool> removeAvatar() async {
    _isAvatarSaving = true;
    _error = null;
    notifyListeners();
    try {
      _profile = await _repository.removeMyAvatar();
      _loadedUserId = _profile?.id;
      _hasLoaded = true;
      return true;
    } on PostgrestException catch (error) {
      _error = error.message;
      return false;
    } catch (_) {
      _error = 'Gagal menghapus avatar pasien.';
      return false;
    } finally {
      _isAvatarSaving = false;
      notifyListeners();
    }
  }

  void clear() {
    _profile = null;
    _loadedUserId = null;
    _hasLoaded = false;
    _error = null;
    _isLoading = false;
    _isSaving = false;
    _isAvatarSaving = false;
    notifyListeners();
  }
}
