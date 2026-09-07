import 'package:flutter_test/flutter_test.dart';

import 'package:sca_fuel/config/app_config.dart';
import 'package:sca_fuel/services/direct_database/auth_service.dart';

void main() {
  test('converts the legacy username to the Supabase Auth email', () {
    expect(AppConfig.usernameEmailDomain, 'sca.local');
    expect(
      DirectDatabaseAuthService.emailForLogin('ayman'),
      'ayman@sca.local',
    );
  });

  test('keeps an explicit email unchanged', () {
    expect(
      DirectDatabaseAuthService.emailForLogin('ayman@sca.local'),
      'ayman@sca.local',
    );
  });
}