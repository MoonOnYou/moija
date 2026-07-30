import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moija/data/api/auth_api.dart';

http.Response _json(Map<String, dynamic> body, [int code = 200]) =>
    http.Response(jsonEncode(body), code,
        headers: {'content-type': 'application/json; charset=utf-8'});

void main() {
  group('checkPhone', () {
    test('가입 가능한 번호', () async {
      late http.Request request;
      final client = MockClient((req) async {
        request = req;
        return _json({'available': true, 'reason': null, 'detail': '가입할 수 있는 번호입니다.'});
      });

      final r = await checkPhone('01011112222', client: client);

      expect(request.url.path, '/api/auth/check-phone/');
      expect(jsonDecode(request.body), {'phone': '01011112222'});
      expect(r.available, isTrue);
      expect(r.isRegistered, isFalse);
    });

    test('이미 가입된 번호', () async {
      final client = MockClient((_) async => _json(
            {'available': false, 'reason': 'registered', 'detail': '이미 가입된 번호입니다.'},
          ));

      final r = await checkPhone('01011112222', client: client);

      expect(r.available, isFalse);
      expect(r.isRegistered, isTrue);
      expect(r.detail, '이미 가입된 번호입니다.');
    });

    test('탈퇴 쿨다운은 가입 불가지만 로그인 안내 대상은 아니다', () async {
      final client = MockClient((_) async => _json({
            'available': false,
            'reason': 'cooldown',
            'detail': '탈퇴 후 30일간 같은 번호로 재가입할 수 없습니다.',
          }));

      final r = await checkPhone('01011112222', client: client);

      expect(r.available, isFalse);
      expect(r.isRegistered, isFalse);
      expect(r.detail, contains('30일'));
    });

    test('오류 응답은 서버 detail을 담은 AuthException', () async {
      final client = MockClient((_) async => _json({'detail': '잘못된 요청입니다.'}, 400));

      await expectLater(
        checkPhone('010', client: client),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', '잘못된 요청입니다.')),
      );
    });
  });
}
