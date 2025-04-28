// lib/services/mock_profile_service.dart

import 'dart:async';
import 'profile_service.dart';

class MockProfileService implements ProfileService {
  Profile _profile = Profile(
    name: 'João da Silva',
    email: 'joao.silva@example.com',
    contractId: '123456',
    planName: 'Fibra 200Mbps',
    status: 'Ativo',
    registrationDate: '01/02/2021',
    address: 'Rua das Flores, 123, Centro',
    phone: '+55 31 99999-0000',
  );

  @override
  Future<Profile> fetchProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _profile;
  }

  @override
  Future<void> updateProfile({
    required String address,
    required String phone,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _profile = _profile.copyWith(address: address, phone: phone);
  }
}
