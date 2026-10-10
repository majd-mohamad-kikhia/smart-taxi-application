import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/localization/app_strings.dart';
import 'package:mshoar/core/services/photo_picker_service.dart';
import 'package:mshoar/driver_features/driver_auth/data/models/driver_signup_request_model.dart';
import 'package:mshoar/driver_features/driver_auth/data/repositories/driver_repository.dart';
import 'package:mshoar/driver_features/driver_auth/presentation/cubit/driver_signup_cubit.dart';
import 'package:mshoar/driver_features/driver_auth/presentation/cubit/driver_signup_state.dart';

class _FakeRepository extends Fake implements DriverRepository {
  final sent = <DriverSignupRequestModel>[];
  DriverSignupException? failure;
  List<SignupVehicleType> types = const [];
  DriverSignupException? typesFailure;

  @override
  Future<List<SignupVehicleType>> signupVehicleTypes() async {
    final error = typesFailure;
    if (error != null) throw error;
    return types;
  }

  @override
  Future<void> signup(DriverSignupRequestModel request) async {
    sent.add(request);
    final error = failure;
    if (error != null) throw error;
  }
}

class _FakePhotos extends Fake implements PhotoPickerService {
  PickedPhoto? next;

  @override
  Future<PickedPhoto?> pick(PhotoSource source) async => next;
}

const _texts = (
  firstName: 'Ahmad',
  lastName: 'Khaled',
  phone: '0997654321',
  password: 'Passw0rd',
  address: '',
  brand: 'Kia',
  model: 'Cerato',
  color: 'White',
  plateNumber: '123456',
);

void main() {
  late _FakeRepository repository;
  late _FakePhotos photos;
  late DriverSignupCubit cubit;

  setUp(() {
    repository = _FakeRepository();
    photos = _FakePhotos();
    cubit = DriverSignupCubit(repository, photos);
  });

  tearDown(() => cubit.close());

  Future<void> fillChoices() async {
    cubit.selectVehicleType(2);
    photos.next = const PickedPhoto('/tmp/me.jpg');
    await cubit.pickPhoto(PhotoSource.gallery);
    photos.next = const PickedPhoto('/tmp/car.jpg');
    await cubit.pickVehiclePhoto(PhotoSource.camera);
  }

  test('the request carries the text, the car and both photos', () async {
    await fillChoices();
    cubit.selectOwnership(VehicleOwnership.company);
    await cubit.submit(_texts);

    final request = repository.sent.single;
    expect(request.toFields(), {
      'first_name': 'Ahmad',
      'last_name': 'Khaled',
      'phone_number': '0997654321',
      'password': 'Passw0rd',
      'vehicle_type_id': '2',
      'brand': 'Kia',
      'model': 'Cerato',
      'color': 'White',
      'plate_number': '123456',
      'vehicle_ownership': 'company',
    });
    expect(
      (request.photoPath, request.vehiclePhotoPath),
      ('/tmp/me.jpg', '/tmp/car.jpg'),
    );
    expect(cubit.state.status, DriverSignupStatus.success);
  });

  test('an address is sent only when typed', () {
    final request = DriverSignupRequestModel(
      firstName: 'A',
      lastName: 'B',
      phone: '0',
      password: 'x',
      address: 'Damascus',
      vehicleTypeId: 1,
      brand: 'k',
      model: 'm',
      color: 'c',
      plateNumber: 'p',
      ownership: VehicleOwnership.owner,
      photoPath: 'a',
      vehiclePhotoPath: 'b',
    );
    expect(request.toFields()['address'], 'Damascus');
  });

  test(
    'without a car type or photos nothing is sent and the gaps show',
    () async {
      await cubit.submit(_texts);

      expect(repository.sent, isEmpty);
      expect(cubit.state.vehicleTypeMissing, isTrue);
      expect(cubit.state.photoMissing, isTrue);
      expect(cubit.state.vehiclePhotoMissing, isTrue);
      expect(cubit.state.status, DriverSignupStatus.editing);
    },
  );

  test('a photo over 5 MB is refused with a message and not kept', () async {
    photos.next = const PickedPhoto('/tmp/big.jpg', tooLarge: true);
    await cubit.pickPhoto(PhotoSource.gallery);

    expect(cubit.state.photoPath, isNull);
    expect(
      cubit.state.photoError,
      AppStrings.current.driverSignupPhotoTooLarge,
    );
  });

  test('backing out of the picker changes nothing', () async {
    photos.next = null;
    await cubit.pickPhoto(PhotoSource.camera);
    expect(cubit.state.photoPath, isNull);
    expect(cubit.state.photoError, isNull);
  });

  test('409 phone already registered shows under the phone field', () async {
    await fillChoices();
    repository.failure = const DriverSignupException(
      'exists',
      statusCode: 409,
      rawErrors: {'phone_number': 'phone_number is already registered'},
    );
    await cubit.submit(_texts);

    expect(cubit.state.phoneError, AppStrings.current.errPhoneRegistered);
    expect(cubit.state.plateError, isNull);
    expect(cubit.state.errorMessage, isNull);
    expect(cubit.state.status, DriverSignupStatus.editing);
  });

  test('409 plate already registered shows under the plate field', () async {
    await fillChoices();
    repository.failure = const DriverSignupException(
      'exists',
      statusCode: 409,
      rawErrors: {'plate_number': 'plate_number is already registered'},
    );
    await cubit.submit(_texts);

    expect(
      cubit.state.plateError,
      AppStrings.current.driverSignupPlateRegistered,
    );
    expect(cubit.state.phoneError, isNull);
  });

  test(
    'another refusal keeps the form and shows the message; the driver can resend',
    () async {
      await fillChoices();
      repository.failure = const DriverSignupException(
        'Check your input',
        statusCode: 422,
      );
      await cubit.submit(_texts);
      expect(cubit.state.errorMessage, 'Check your input');
      expect(cubit.state.photoPath, '/tmp/me.jpg');

      repository.failure = null;
      await cubit.submit(_texts);
      expect(cubit.state.status, DriverSignupStatus.success);
      expect(cubit.state.errorMessage, isNull);
      expect(repository.sent, hasLength(2));
    },
  );

  test('a second tap while sending is ignored', () async {
    await fillChoices();
    final first = cubit.submit(_texts);
    await cubit.submit(_texts);
    await first;
    expect(repository.sent, hasLength(1));
  });

  group('car types from the server', () {
    test(
      'loads the active types and shows them as the manager named them',
      () async {
        repository.types = const [
          SignupVehicleType(id: 3, name: 'van', maxPassengers: 11),
          SignupVehicleType(id: 6, name: 'خاصة'),
        ];
        await cubit.loadVehicleTypes();

        expect(cubit.state.isLoadingTypes, isFalse);
        expect(cubit.state.vehicleTypes.map((t) => (t.id, t.name)), [
          (3, 'van'),
          (6, 'خاصة'),
        ]);
        expect(cubit.state.typesError, isNull);
      },
    );

    test('the chosen type\'s id is what is sent', () async {
      repository.types = const [SignupVehicleType(id: 6, name: 'خاصة')];
      await cubit.loadVehicleTypes();
      cubit.selectVehicleType(6);
      photos.next = const PickedPhoto('/tmp/me.jpg');
      await cubit.pickPhoto(PhotoSource.gallery);
      await cubit.pickVehiclePhoto(PhotoSource.gallery);
      await cubit.submit(_texts);

      expect(repository.sent.single.vehicleTypeId, 6);
    });

    test(
      'a failure shows the message, with no fixed list to fall back to; Retry loads',
      () async {
        repository.typesFailure = const DriverSignupException('No connection');
        await cubit.loadVehicleTypes();
        expect(cubit.state.typesError, 'No connection');
        expect(cubit.state.vehicleTypes, isEmpty);

        repository.typesFailure = null;
        repository.types = const [SignupVehicleType(id: 4, name: 'VIP')];
        await cubit.loadVehicleTypes();
        expect(cubit.state.typesError, isNull);
        expect(cubit.state.vehicleTypes, hasLength(1));
      },
    );

    test(
      'a type the server no longer offers is dropped from the choice',
      () async {
        repository.types = const [SignupVehicleType(id: 3, name: 'van')];
        await cubit.loadVehicleTypes();
        cubit.selectVehicleType(3);

        repository.types = const [SignupVehicleType(id: 4, name: 'VIP')];
        await cubit.loadVehicleTypes();

        expect(cubit.state.vehicleTypeId, isNull);
      },
    );

    test('reads the server\'s JSON', () {
      final type = SignupVehicleType.fromJson({
        'id': 7,
        'name': 'عامة',
        'description': null,
        'max_passengers': 4,
      });
      expect(
        (type.id, type.name, type.description, type.maxPassengers),
        (7, 'عامة', null, 4),
      );
    });
  });
}
