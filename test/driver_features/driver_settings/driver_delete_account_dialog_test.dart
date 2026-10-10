import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/l10n/generated/app_localizations.dart';
import 'package:mshoar/core/localization/app_strings.dart';
import 'package:mshoar/core/network/api_endpoints.dart';
import 'package:mshoar/core/network/api_exception.dart';
import 'package:mshoar/driver_features/driver_settings/data/datasources/driver_account_deletion_remote_data_source.dart';
import 'package:mshoar/driver_features/driver_settings/data/models/driver_deletion_request_model.dart';
import 'package:mshoar/driver_features/driver_settings/data/repositories/driver_account_deletion_repository.dart';
import 'package:mshoar/driver_features/driver_settings/presentation/cubit/driver_account_deletion_cubit.dart';
import 'package:mshoar/driver_features/driver_settings/presentation/widgets/driver_delete_account_dialog_widget.dart';

class _FakeRemote extends DriverAccountDeletionRemoteDataSource {
  _FakeRemote() : super(Dio(), const ApiEndpoints());

  final passwords = <String>[];
  ApiException? failure;

  @override
  Future<DriverDeletionRequestModel> requestDeletion({
    required String password,
    String? reason,
  }) async {
    passwords.add(password);
    final error = failure;
    if (error != null) {
      throw DioException(requestOptions: RequestOptions(), error: error);
    }
    return const DriverDeletionRequestModel(
      id: 1,
      status: DriverDeletionStatus.pending,
    );
  }
}

void main() {
  late _FakeRemote remote;
  late DriverAccountDeletionCubit cubit;
  var requested = 0;

  setUp(() {
    remote = _FakeRemote();
    cubit = DriverAccountDeletionCubit(DriverAccountDeletionRepository(remote));
    requested = 0;
  });

  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
  });

  Future<void> openDialog(WidgetTester tester) async {
    // The form has two fields; the default 800x600 view would cut it off.
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showDriverDeleteAccountDialog(
                  context,
                  cubit: cubit,
                  onRequested: () => requested++,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    // The shared dialog's icon pulses forever, so settle by hand.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> sendRequest(WidgetTester tester, String password) async {
    await tester.enterText(find.byType(TextFormField).first, password);
    await tester.pump();
    await tester.tap(find.text('Delete account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('a sent request closes the form and calls onRequested once', (
    tester,
  ) async {
    await openDialog(tester);
    await sendRequest(tester, 'MyPassw0rd');

    expect(remote.passwords, ['MyPassw0rd']);
    expect(requested, 1);
    expect(find.text('Delete account'), findsNothing);
  });

  testWidgets('a wrong password keeps the form open and does not call it', (
    tester,
  ) async {
    remote.failure = const ApiException('raw', statusCode: 401);
    await openDialog(tester);
    await sendRequest(tester, 'nope');

    expect(requested, 0);
    expect(find.text('Delete account'), findsOneWidget);
    expect(find.text(AppStrings.current.errIncorrectPassword), findsOneWidget);
  });
}
