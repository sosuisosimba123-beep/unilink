import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class AttendanceQrHelper {
  static int getTimeBucket() {
    return DateTime.now().millisecondsSinceEpoch ~/ 10000; // 10-second window
  }

  static String generatePayload(String sessionId, String secretKey, int timeBucket) {
    final jwt = JWT({
      'sessionId': sessionId,
      'timeBucket': timeBucket,
    });
    // Sign JWT with session secretKey (valid for 20 seconds to prevent replay)
    return jwt.sign(SecretKey(secretKey), expiresIn: const Duration(seconds: 20));
  }

  static bool verifyPayload(String token, String secretKey) {
    try {
      final cleanedToken = token.trim();
      if (cleanedToken.isEmpty) return false;

      // Verify cryptographic signature and expiration offline using dart_jsonwebtoken
      final jwt = JWT.verify(cleanedToken, SecretKey(secretKey));
      final payload = jwt.payload as Map<String, dynamic>;
      final timeBucket = payload['timeBucket'] as int;

      final currentBucket = DateTime.now().millisecondsSinceEpoch ~/ 10000;
      // Allow current and +/- 1 bucket for clock skew (30 seconds total tolerance)
      if ((timeBucket - currentBucket).abs() > 1) {
        return false;
      }

      return true;
    } catch (e) {
      print('JWT Verification failed: $e');
      return false;
    }
  }
}
