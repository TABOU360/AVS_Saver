enum MissionStatus { pending, confirmed, done, cancelled }

class Mission {
  final String id;
  final String familyId;
  final String avsId;
  final String beneficiaryId;
  final DateTime start;
  final DateTime end;
  MissionStatus status;

  Mission({
    required this.id,
    required this.familyId,
    required this.avsId,
    required this.beneficiaryId,
    required this.start,
    required this.end,
    this.status = MissionStatus.pending
  });
}