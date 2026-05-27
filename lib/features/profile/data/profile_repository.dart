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
      'p_avatar_url':
          user?.userMetadata?['avatar_url'] as String? ??
          user?.userMetadata?['picture'] as String?,
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
          'avatar_url': payload['p_avatar_url'],
        })
        .select()
        .single();

    return PatientProfile.fromJson(data);
  }
}
