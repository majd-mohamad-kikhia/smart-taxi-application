import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mshoar/core/network/api_endpoints.dart';
import 'package:mshoar/core/network/api_error_handler.dart';
import 'package:mshoar/core/network/api_exception.dart';

void main() {
  const endpoints = ApiEndpoints();
  const handler = ApiErrorHandler(endpoints);

  DioException badResponse({
    required String path,
    required int statusCode,
    dynamic data,
  }) {
    final requestOptions = RequestOptions(path: path);
    return DioException(
      requestOptions: requestOptions,
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: requestOptions,
        statusCode: statusCode,
        data: data,
      ),
    );
  }

  ApiException handle({
    required String path,
    required int statusCode,
    dynamic data,
  }) {
    return handler.handle(
      badResponse(path: path, statusCode: statusCode, data: data),
    );
  }

  group('documented top-level messages (exact match)', () {
    const cases = <int, ({String message, String path, String expected})>{
      400: (
        message: 'Invalid JSON body',
        path: '/api/customer/auth/signup',
        expected: 'طلب غير صالح',
      ),
      409: (
        message: 'Account already exists',
        path: '/api/customer/auth/signup',
        expected: 'الحساب موجود بالفعل',
      ),
      500: (
        message: 'Internal server error',
        path: '/api/customer/auth/signup',
        expected: 'حدث خطأ في الخادم، حاول لاحقاً',
      ),
    };

    cases.forEach((statusCode, c) {
      test('status $statusCode -> "${c.message}"', () {
        final result = handle(
          path: c.path,
          statusCode: statusCode,
          data: {'success': false, 'message': c.message},
        );
        expect(result.message, c.expected);
      });
    });

    test('404 "Route not found"', () {
      final result = handle(
        path: '/api/unknown',
        statusCode: 404,
        data: {'success': false, 'message': 'Route not found'},
      );
      expect(result.message, 'الخدمة المطلوبة غير متوفرة');
    });

    test('403 "Customer access only"', () {
      final result = handle(
        path: '/api/customer/rides',
        statusCode: 403,
        data: {'success': false, 'message': 'Customer access only'},
      );
      expect(result.message, 'هذا الحساب غير مخصص لهذا التطبيق');
    });
  });

  group('driver login 403 — the bug being fixed', () {
    test('pending account', () {
      final result = handle(
        path: endpoints.driverLogin,
        statusCode: 403,
        data: {
          'success': false,
          'message': 'Your account is pending approval',
          'errors': {
            'status_id': 'current status is pending; must be active',
          },
        },
      );
      expect(result.message, 'حسابك قيد المراجعة، سيتم تفعيله بعد الموافقة');
    });

    test('suspended account', () {
      final result = handle(
        path: endpoints.driverLogin,
        statusCode: 403,
        data: {
          'success': false,
          'message': 'Your account is suspended',
          'errors': {
            'status_id': 'current status is suspended; must be active',
          },
        },
      );
      expect(result.message, 'تم إيقاف حسابك، يرجى التواصل مع الدعم');
    });

    test('rejected account (undocumented reason -> status-code fallback)',
        () {
      final result = handle(
        path: endpoints.driverLogin,
        statusCode: 403,
        data: {
          'success': false,
          'message': 'Your account is rejected',
          'errors': {
            'status_id': 'current status is rejected; must be active',
          },
        },
      );
      expect(result.message, 'لا يمكن تسجيل الدخول، حسابك غير نشط حالياً');
    });
  });

  group('documented field-error reasons (exact match)', () {
    test('first_name is required', () {
      final result = handle(
        path: endpoints.customerSignup,
        statusCode: 422,
        data: {
          'success': false,
          'message': 'Validation failed',
          'errors': {'first_name': 'first_name is required'},
        },
      );
      expect(result.message, 'هذا الحقل مطلوب');
      expect(result.fieldErrors, {'first_name': 'هذا الحقل مطلوب'});
    });

    test('phone_number is already registered', () {
      final result = handle(
        path: endpoints.customerSignup,
        statusCode: 409,
        data: {
          'success': false,
          'message': 'Account already exists',
          'errors': {
            'phone_number': 'phone_number is already registered',
          },
        },
      );
      expect(result.message, 'رقم الجوال مسجل مسبقاً');
    });

    test('password must be between 8 and 64 characters', () {
      final result = handle(
        path: endpoints.customerSignup,
        statusCode: 422,
        data: {
          'success': false,
          'message': 'Validation failed',
          'errors': {
            'password': 'password must be between 8 and 64 characters',
          },
        },
      );
      expect(result.message, 'كلمة المرور يجب أن تكون بين 8 و64 حرفاً');
    });

    test('password must contain at least one number', () {
      final result = handle(
        path: endpoints.customerSignup,
        statusCode: 422,
        data: {
          'success': false,
          'message': 'Validation failed',
          'errors': {
            'password': 'password must contain at least one number',
          },
        },
      );
      expect(
        result.message,
        'يجب أن تحتوي كلمة المرور على حرف ورقم على الأقل',
      );
    });

    test('phone_number is required', () {
      final result = handle(
        path: endpoints.customerSignup,
        statusCode: 422,
        data: {
          'success': false,
          'message': 'Validation failed',
          'errors': {'phone_number': 'phone_number is required'},
        },
      );
      expect(result.message, 'رقم الجوال مطلوب');
    });
  });

  group('negative cases — proves guessing is gone', () {
    test('undocumented reason containing "already" is NOT matched as '
        'phone_number-already-registered', () {
      final result = handle(
        path: endpoints.driverSignup,
        statusCode: 422,
        data: {
          'success': false,
          'message': 'Validation failed',
          'errors': {'plate_number': 'plate_number already in use'},
        },
      );
      expect(result.fieldErrors, {'plate_number': 'تحقق من هذا الحقل'});
      // Top-level `message` ("Validation failed") IS documented, so it
      // still resolves via the message table — the point of this case is
      // the *field* reason, asserted above, is never guessed at.
      expect(result.message, 'تحقق من البيانات المدخلة');
    });

    test('undocumented reason containing "number" is NOT matched as the '
        'password-strength message', () {
      final result = handle(
        path: endpoints.customerSignup,
        statusCode: 422,
        data: {
          'success': false,
          'message': 'Validation failed',
          'errors': {'password': 'password is too weak, add a number'},
        },
      );
      expect(result.fieldErrors, {'password': 'تحقق من هذا الحقل'});
    });

    test('undocumented reason falls through to the field-agnostic '
        'placeholder, not a field-specific guess', () {
      final result = handle(
        path: endpoints.customerSignup,
        statusCode: 422,
        data: {
          'success': false,
          'message': 'Validation failed',
          'errors': {'email': 'email domain not allowed'},
        },
      );
      expect(result.fieldErrors, {'email': 'تحقق من هذا الحقل'});
    });
  });

  group('401 — same status code, two different meanings', () {
    test('on the login endpoint -> credentials message', () {
      final result = handle(
        path: endpoints.customerLogin,
        statusCode: 401,
        data: {
          'success': false,
          'message': 'Invalid phone number or password',
        },
      );
      expect(result.message, 'رقم الجوال أو كلمة المرور غير صحيحة');
    });

    test('on any other endpoint -> session-expired message', () {
      final result = handle(
        path: endpoints.customerNotifications,
        statusCode: 401,
        data: {'success': false, 'message': 'Missing or invalid access token'},
      );
      expect(result.message, 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً');
    });
  });

  group('409 — signup conflict vs. ride-state conflict', () {
    test('signup path -> account-exists message', () {
      final result = handle(
        path: endpoints.driverSignup,
        statusCode: 409,
        data: {'success': false, 'message': 'Account already exists'},
      );
      expect(result.message, 'الحساب موجود بالفعل');
    });

    test('non-signup path (ride accept) -> generic conflict message', () {
      final result = handle(
        path: endpoints.driverRideAccept(1),
        statusCode: 409,
        data: {
          'success': false,
          'message': 'Already taken / driver has active ride',
        },
      );
      expect(result.message, 'لا يمكن تنفيذ هذا الإجراء في الوقت الحالي');
    });
  });

  group('malformed / unexpected bodies', () {
    test('errors present but is a List, not a Map -> ignored', () {
      final result = handle(
        path: endpoints.customerSignup,
        statusCode: 422,
        data: {
          'success': false,
          'message': 'Validation failed',
          'errors': ['first_name is required'],
        },
      );
      expect(result.fieldErrors, isNull);
      expect(result.message, 'تحقق من البيانات المدخلة');
    });

    test('errors values are non-string -> that field is skipped', () {
      final result = handle(
        path: endpoints.customerSignup,
        statusCode: 422,
        data: {
          'success': false,
          'message': 'Validation failed',
          'errors': {
            'first_name': 123,
            'phone_number': 'phone_number is required',
          },
        },
      );
      expect(result.fieldErrors, {'phone_number': 'رقم الجوال مطلوب'});
    });

    test('body is a plain String, not a Map -> status-code fallback', () {
      final result = handle(
        path: endpoints.customerSignup,
        statusCode: 422,
        data: 'Validation failed',
      );
      expect(result.message, 'تحقق من البيانات المدخلة');
      expect(result.fieldErrors, isNull);
    });

    test('body is null -> status-code fallback, no crash', () {
      final result = handle(
        path: endpoints.customerSignup,
        statusCode: 500,
        data: null,
      );
      expect(result.message, 'حدث خطأ في الخادم، حاول لاحقاً');
    });
  });

  group('non-badResponse exception types', () {
    test('connectionTimeout', () {
      final result = handler.handle(
        DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(result.message, 'انتهت مهلة الاتصال بالخادم');
    });

    test('connectionError', () {
      final result = handler.handle(
        DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.connectionError,
        ),
      );
      expect(result.message, 'تعذر الاتصال بالإنترنت، تحقق من اتصالك');
    });

    test('cancel', () {
      final result = handler.handle(
        DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.cancel,
        ),
      );
      expect(result.message, 'تم إلغاء الطلب');
    });
  });
}
