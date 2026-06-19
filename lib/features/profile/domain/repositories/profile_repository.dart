import '../../../../models/user_model.dart';

abstract class ProfileRepository {
  Stream<UserModel?> watchProfile(String uid);

  Future<void> updateProfile({
    required String uid,
    required String name,
    required String phone,
    required String defaultAddress,
  });

  Future<void> updateNotificationsEnabled({
    required String uid,
    required bool enabled,
  });

  Future<void> saveFcmToken({required String uid, required String token});

  Stream<List<Map<String, dynamic>>> watchAddresses(String uid);

  Future<void> addAddress({
    required String uid,
    required String label,
    required String address,
  });

  Future<void> deleteAddress({required String uid, required String addressId});
}
