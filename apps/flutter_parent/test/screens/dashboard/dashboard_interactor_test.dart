// Copyright (C) 2019 - present Instructure, Inc.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, version 3 of the License.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import 'dart:math';

import 'package:flutter_parent/models/enrollment.dart';
import 'package:flutter_parent/models/login.dart';
import 'package:flutter_parent/models/user.dart';
import 'package:flutter_parent/network/api/enrollments_api.dart';
import 'package:flutter_parent/network/api/user_api.dart';
import 'package:flutter_parent/screens/dashboard/dashboard_interactor.dart';
import 'package:flutter_parent/screens/dashboard/inbox_notifier.dart';
import 'package:flutter_parent/utils/old_app_migration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../utils/canvas_model_utils.dart';
import '../../utils/platform_config.dart';
import '../../utils/test_app.dart';
import '../../utils/test_helpers/mock_helpers.dart';

void main() {
  test('getStudents calls getObserveeEnrollments from EnrollmentsApi', () {
    var api = MockUserApi();
    setupTestLocator((l) => l.registerLazySingleton<UserApi>(() => api));
    when(api.getObservees(forceRefresh: anyNamed('forceRefresh')))
        .thenAnswer((_) => Future.value(<User>[]));

    var interactor = DashboardInteractor();
    interactor.getStudents();
    verify(api.getObservees(forceRefresh: anyNamed('forceRefresh'))).called(1);
  });

  test('getSelf calls UserApi', () async {
    var api = MockUserApi();
    final initialUser = CanvasModelTestUtils.mockUser();
    final updatedUser = CanvasModelTestUtils.mockUser(name: 'Inst Panda');
    final permittedUser = updatedUser.rebuild((b) {
      return b..permissions = UserPermission((p) => p..limitParentAppWebAccess = true).toBuilder();
    });

    setupTestLocator((l) => l.registerLazySingleton<UserApi>(() => api));
    when(api.getSelf()).thenAnswer((_) => Future.value(updatedUser));
    when(api.getSelfPermissions()).thenAnswer((_) => Future.value(permittedUser.permissions));

    // Setup ApiPrefs
    final login = Login((b) => b..user = initialUser.toBuilder());
    await setupPlatformChannels(config: PlatformConfig(initLoggedInUser: login));

    var interactor = DashboardInteractor();
    final actual = await interactor.getSelf();

    expect(actual, permittedUser);
    verify(api.getSelf()).called(1);
    verify(api.getSelfPermissions()).called(1);
  });

  test('getSelf calls UserApi and handles no permissions', () async {
    var api = MockUserApi();
    final initialUser = CanvasModelTestUtils.mockUser();
    final updatedUser = CanvasModelTestUtils.mockUser(name: 'Inst Panda');

    setupTestLocator((l) => l.registerLazySingleton<UserApi>(() => api));
    when(api.getSelf()).thenAnswer((_) => Future.value(updatedUser));
    when(api.getSelfPermissions()).thenAnswer((_) => Future.error('No permissions for this user'));

    // Setup ApiPrefs
    final login = Login((b) => b..user = initialUser.toBuilder());
    await setupPlatformChannels(config: PlatformConfig(initLoggedInUser: login));

    var interactor = DashboardInteractor();
    final actual = await interactor.getSelf();

    expect(actual, updatedUser);
    verify(api.getSelf()).called(1);
    verify(api.getSelfPermissions()).called(1);
  });

  test('Sort users in descending order', () {
    // Create lists
    var startingList = [_mockStudent('Zed'), _mockStudent('Alex'), _mockStudent('Billy')];
    var expectedSortedList = [_mockStudent('Alex'), _mockStudent('Billy'), _mockStudent('Zed')];

    // Run the logic
    var interactor = DashboardInteractor();
    interactor.sortUsers(startingList);

    expect(startingList, expectedSortedList);
  });

  test('Returns InboxCountNotifier from locator', () {
    var notifier = InboxCountNotifier();
    setupTestLocator((locator) {
      locator.registerLazySingleton<InboxCountNotifier>(() => notifier);
    });

    var interactor = DashboardInteractor();
    expect(interactor.getInboxCountNotifier(), notifier);
  });

  test('shouldShowOldReminderMessage calls OldAppMigration.hasOldReminders', () {
    var migration = _MockMigration();
    setupTestLocator((locator) {
      locator.registerLazySingleton<OldAppMigration>(() => migration);
    });

    DashboardInteractor().shouldShowOldReminderMessage();
    verify(migration.hasOldReminders());
  });
}

User _mockStudent(String name) => User((b) => b
  ..id = Random(name.hashCode).nextInt(100000).toString()
  ..sortableName = name
  ..build());

Enrollment _mockEnrollment(UserBuilder observedUser) => Enrollment((b) => b
  ..enrollmentState = ''
  ..observedUser = observedUser
  ..build());

class _MockMigration extends Mock implements OldAppMigration {}

class MockUserApi extends Mock implements UserApi {}
