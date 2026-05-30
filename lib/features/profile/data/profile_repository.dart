import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/patient_profile.dart';

class ProfileRepository {
  const ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<PatientProfile?> fetchMyProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return PatientProfile.fromJson(data);
  }

  Future<PatientProfile> updateMyProfile({
    required String fullName,
    required String phoneNumber,
    required String gender,
    DateTime? birthDate,
  }) async {
    final user = _client.auth.currentUser;
    final userId = user?.id;
    if (userId == null) {
      throw const AuthException('Sesi login tidak ditemukan.');
    }

    final payload = {
      'p_full_name': fullName.trim(),
      'p_phone_number': phoneNumber.trim(),
      'p_gender': gender,
      'p_birth_date': birthDate == null
          ? null
          : DateFormat('yyyy-MM-dd').format(birthDate),
      'p_avatar_url': null,
    };

    try {
      final data = await _client.rpc<Map<String, dynamic>>(
        'upsert_my_profile',
        params: payload,
      );
      return PatientProfile.fromJson(data);
    } on PostgrestException catch (error) {
      final isRpcMissing =
          error.code == 'PGRST202' ||
          error.message.toLowerCase().contains('upsert_my_profile');
      if (!isRpcMissing) rethrow;
    }

    final data = await _client
        .from('profiles')
        .upsert({
          'id': userId,
          'full_name': payload['p_full_name'],
          'phone_number': payload['p_phone_number'],
          'gender': payload['p_gender'],
          'birth_date': payload['p_birth_date'],
        })
        .select()
        .single();

    return PatientProfile.fromJson(data);
  }

  Future<PatientProfile> removeMyAvatar() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Sesi login tidak ditemukan.');
    }

    final data = await _client
        .from('profiles')
        .update({'avatar_url': null})
        .eq('id', userId)
        .select()
        .single();

    return PatientProfile.fromJson(data);
  }

  Future<PatientProfile> updateMyAvatarUrl(String avatarUrl) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Sesi login tidak ditemukan.');
    }

    final data = await _client
        .from('profiles')
        .update({'avatar_url': avatarUrl.trim()})
        .eq('id', userId)
        .select()
        .single();

    return PatientProfile.fromJson(data);
  }

  Future<PatientProfile> uploadAvatar({
    required Uint8List bytes,
    required String extension,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('Sesi login tidak ditemukan.');
    }

    final normalizedExtension = _normalizeExtension(extension);
    final path =
        '$userId/avatar-${DateTime.now().millisecondsSinceEpoch}.$normalizedExtension';
    await _client.storage
        .from('avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _contentTypeFor(normalizedExtension),
          ),
        );

    final publicUrl = _client.storage.from('avatars').getPublicUrl(path);
    return updateMyAvatarUrl(publicUrl);
  }

  String _normalizeExtension(String extension) {
    final lower = extension.toLowerCase().replaceAll('.', '');
    if (lower == 'jpeg') return 'jpg';
    if (lower == 'png' || lower == 'webp' || lower == 'jpg') return lower;
    return 'jpg';
  }

  String _contentTypeFor(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }
}
