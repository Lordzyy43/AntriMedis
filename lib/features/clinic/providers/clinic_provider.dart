import 'package:flutter/foundation.dart';

import '../data/clinic_repository.dart';
import '../data/models/clinic_branch_info.dart';

class ClinicProvider extends ChangeNotifier {
  ClinicProvider(this._repository);

  final ClinicRepository _repository;

  ClinicBranchInfo? _branch;
  bool _isLoading = false;

  ClinicBranchInfo? get branch => _branch;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _branch = await _repository.fetchPrimaryBranch();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
