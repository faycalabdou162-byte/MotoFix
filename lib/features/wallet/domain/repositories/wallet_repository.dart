abstract class WalletRepository {
  Future<int> fetchBalance(String userId);

  Stream<int> watchBalance(String userId);
}
