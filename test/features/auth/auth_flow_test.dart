import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:field_inventory_edge_ai/features/auth/data/supabase_auth_repository.dart';
import 'package:field_inventory_edge_ai/features/auth/domain/app_user.dart';
import 'package:field_inventory_edge_ai/features/auth/domain/auth_repository.dart';
import 'package:field_inventory_edge_ai/features/auth/presentation/account_sheet.dart';
import 'package:field_inventory_edge_ai/features/auth/presentation/auth_providers.dart';
import 'package:field_inventory_edge_ai/features/offline_audit/presentation/controllers/audit_records_provider.dart';
import 'package:field_inventory_edge_ai/main.dart';

import '../../helpers/auth_fakes.dart';

void main() {
  late FakeAuthRepository auth;

  Future<void> pumpApp(WidgetTester tester, {AppUser? user}) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    auth = FakeAuthRepository(signedInAs: user);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          auditRecordsProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.descendant(
    of: find
        .ancestor(of: find.text(label), matching: find.byType(Column))
        .first,
    matching: find.byType(TextField),
  );

  group('Bắt buộc đăng nhập', () {
    testWidgets('Chưa đăng nhập thì vào màn Đăng nhập', (tester) async {
      await pumpApp(tester);
      expect(find.text('Đăng nhập'), findsWidgets);
      expect(find.text('Quét thiết bị'), findsNothing);
    });

    testWidgets('Đã có phiên trên máy thì vào thẳng Tổng quan', (tester) async {
      await pumpApp(tester, user: testUser);
      expect(find.text('Quét thiết bị'), findsOneWidget);
    });

    testWidgets('Đăng nhập đúng thì chuyển vào Tổng quan', (tester) async {
      await pumpApp(tester);
      await tester.enterText(field('Email'), ' an@fieldline.vn ');
      await tester.enterText(field('Mật khẩu'), 'matkhau1');
      await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
      await tester.pumpAndSettle();

      expect(auth.lastPassword, 'matkhau1');
      expect(find.text('Quét thiết bị'), findsOneWidget);
    });

    testWidgets('Sai mật khẩu thì báo lỗi và ở lại màn đăng nhập', (
      tester,
    ) async {
      await pumpApp(tester);
      auth.nextFailure = const AuthFailure('Email hoặc mật khẩu không đúng.');
      await tester.enterText(field('Email'), 'an@fieldline.vn');
      await tester.enterText(field('Mật khẩu'), 'sai');
      await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
      await tester.pumpAndSettle();

      expect(find.text('Email hoặc mật khẩu không đúng.'), findsOneWidget);
      expect(find.text('Quét thiết bị'), findsNothing);
    });

    testWidgets('Bỏ trống thì không gửi yêu cầu', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
      await tester.pumpAndSettle();

      expect(find.text('Nhập email'), findsOneWidget);
      expect(find.text('Nhập mật khẩu'), findsOneWidget);
      expect(auth.lastEmail, isNull);
    });

    testWidgets('Đăng xuất từ ảnh đại diện thì về màn Đăng nhập', (
      tester,
    ) async {
      await pumpApp(tester, user: testUser);
      await tester.tap(find.byType(AccountAvatar));
      await tester.pumpAndSettle();
      expect(find.text('an@fieldline.vn'), findsOneWidget);

      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Đăng xuất'));
      await tester.pumpAndSettle();

      expect(auth.currentUser, isNull);
      expect(find.widgetWithText(FilledButton, 'Đăng nhập'), findsOneWidget);
    });
  });

  group('Đăng ký', () {
    Future<void> openRegister(WidgetTester tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
      await tester.pumpAndSettle();
    }

    Future<void> fill(
      WidgetTester tester, {
      String confirm = 'matkhau1',
    }) async {
      await tester.enterText(field('Họ và tên'), 'Trần Bình');
      await tester.enterText(field('Email'), 'binh@fieldline.vn');
      await tester.enterText(field('Mật khẩu'), 'matkhau1');
      await tester.enterText(field('Nhập lại mật khẩu'), confirm);
      await tester.tap(find.widgetWithText(FilledButton, 'Đăng ký'));
      await tester.pumpAndSettle();
    }

    testWidgets('Đăng ký xong (không cần xác nhận) thì vào app', (
      tester,
    ) async {
      await openRegister(tester);
      await fill(tester);

      expect(auth.lastFullName, 'Trần Bình');
      expect(find.text('Quét thiết bị'), findsOneWidget);
    });

    testWidgets('Cần xác nhận email thì báo đã gửi thư', (tester) async {
      await openRegister(tester);
      auth.signUpOutcome = SignUpOutcome.confirmEmail;
      await fill(tester);

      expect(
        find.text('Đã gửi thư xác nhận tới binh@fieldline.vn'),
        findsOneWidget,
      );
      await tester.tap(find.text('Về màn đăng nhập'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Đăng nhập'), findsOneWidget);
    });

    testWidgets('Mật khẩu nhập lại không khớp thì không gửi', (tester) async {
      await openRegister(tester);
      await fill(tester, confirm: 'khac123');

      expect(find.text('Mật khẩu nhập lại không khớp'), findsOneWidget);
      expect(auth.lastEmail, isNull);
    });
  });

  group('AppUser', () {
    test('chữ cái đầu và tên hiển thị', () {
      expect(testUser.initials, 'HA');
      const noName = AppUser(id: 'x', email: 'kiemke01@congty.vn');
      expect(noName.displayName, 'kiemke01');
      expect(noName.initials, 'K');
      expect(UserRole.fromCode('admin').label, 'Quản trị viên');
      expect(UserRole.fromCode(null), UserRole.auditor);
    });
  });

  group('describeAuthError', () {
    test('dịch lỗi thường gặp sang tiếng Việt', () {
      expect(
        describeAuthError(
          const AuthException(
            'Invalid login credentials',
            code: 'invalid_credentials',
          ),
        ),
        'Email hoặc mật khẩu không đúng.',
      );
      expect(
        describeAuthError(const AuthException('Email not confirmed')),
        contains('chưa được xác nhận'),
      );
      expect(
        describeAuthError(AuthRetryableFetchException()),
        contains('Cần có mạng'),
      );
    });
  });
}
