// lib/services/profile_service.dart

/// Modelo de dados do perfil
class Profile {
  final String name;
  final String email;
  final String contractId;
  final String planName;
  final String status;
  final String registrationDate;
  final String address;
  final String phone;

  Profile({
    required this.name,
    required this.email,
    required this.contractId,
    required this.planName,
    required this.status,
    required this.registrationDate,
    required this.address,
    required this.phone,
  });

  Profile copyWith({String? address, String? phone}) {
    return Profile(
      name: name,
      email: email,
      contractId: contractId,
      planName: planName,
      status: status,
      registrationDate: registrationDate,
      address: address ?? this.address,
      phone: phone ?? this.phone,
    );
  }
}

/// Interface para abstrair leitura/atualização do perfil
abstract class ProfileService {
  Future<Profile> fetchProfile();
  Future<void> updateProfile({required String address, required String phone});
}
