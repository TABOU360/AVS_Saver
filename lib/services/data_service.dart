import '../models/avs.dart';
import '../models/beneficiary.dart';
import '../models/mission.dart';

class DataService {
  // Mock data for prototyping
  final List<Avs> avs = [
    Avs(id:'a1', name:'Aïcha Diallo', rating:4.8, skills:['Géronto','Autisme'], hourlyRate:15, verified:true, bio:'5 ans d\'expérience, premiers secours.'),
    Avs(id:'a2', name:'Boris M.', rating:4.6, skills:['Parkinson','Alzheimer'], hourlyRate:12, verified:false, bio:'Calme et patient, mobilité.')
  ];

  final List<Beneficiary> beneficiaries = [
    Beneficiary(id:'b1', fullName:'Mme Nadia', age:72, condition:'Diabète type 2'),
    Beneficiary(id:'b2', fullName:'M. Benoît', age:65, condition:'Parkinson')
  ];

  final List<Mission> missions = [];

  Future<List<Avs>> searchAvs() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return avs;
    }

  Future<List<Beneficiary>> listBeneficiaries() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return beneficiaries;
  }
}
