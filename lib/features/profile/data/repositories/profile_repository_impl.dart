import '../../../../models/user_model.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_firebase_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({ProfileFirebaseDataSource? dataSource})
      : _dataSource = dataSource ?? ProfileFirebaseDataSource();

  final ProfileFirebaseDataSource _dataSource;

  @override
  Stream<UserModel?> watchProfile(String uid) =>
      _dataSource.watchProfile(uid);

  @override
  Future<void> updateProfile({
    required String uid,
    required String name,
    required String phone,
    required String defaultAddress,
  }) {
    return _dataSource.updateProfile(
      uid: uid,
      name: name,
      phone: phone,
      defaultAddress: defaultAddress,
    );
  }

  @override
  Future<void> updateNotificationsEnabled({
    required String uid,
    required bool enabled,
  }) {
    return _dataSource.updateNotificationsEnabled(uid: uid, enabled: enabled);
  }

  @override
  Future<void> saveFcmToken({required String uid, required String token}) {
    return _dataSource.saveFcmToken(uid: uid, token: token);
  }

  @override
  Stream<List<Map<String, dynamic>>> watchAddresses(String uid) {
    return _dataSource.watchAddresses(uid);
  }

  @override
  Future<void> addAddress({
    required String uid,
    required String label,
    required String address,
  }) {
    return _dataSource.addAddress(uid: uid, label: label, address: address);
  }

  @override
  Future<void> deleteAddress({
    required String uid,
    required String addressId,
  }) {
    return _dataSource.deleteAddress(uid: uid, addressId: addressId);
  }
}
