import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/clinic_branch_info.dart';

class ClinicRepository {
  const ClinicRepository(this._client);

  final SupabaseClient _client;

  Future<ClinicBranchInfo?> fetchPrimaryBranch() async {
    final data = await _client
        .from('clinic_branches')
        .select(
          'name, address, city, province, phone_number, open_time, close_time',
        )
        .eq('is_active', true)
        .order('created_at', ascending: true)
        .limit(1)
        .maybeSingle();

    if (data == null) return null;
    return ClinicBranchInfo.fromJson(data);
  }
}
