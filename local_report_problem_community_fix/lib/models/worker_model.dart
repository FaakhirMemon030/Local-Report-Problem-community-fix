import 'package:cloud_firestore/cloud_firestore.dart';

enum WorkerCategory { electrician, plumber, road, drainage, garbage, election }
enum WorkerStatus { pending, approved, rejected }

class WorkerModel {
  final String workerId;
  final String name;
  final String email;
  final String phone;
  final String cnic;
  final WorkerCategory category;
  final String city;
  final String address;
  final String profilePicUrl;
  final String cnicPicUrl;
  final String electricityBillUrl;
  final String gasBillUrl;
  final WorkerStatus status;
  final bool isBanned;
  final DateTime createdAt;
  final int jobsDone;

  WorkerModel({
    required this.workerId,
    required this.name,
    required this.email,
    required this.phone,
    required this.cnic,
    required this.category,
    required this.city,
    required this.address,
    this.profilePicUrl = '',
    this.cnicPicUrl = '',
    this.electricityBillUrl = '',
    this.gasBillUrl = '',
    this.status = WorkerStatus.pending,
    this.isBanned = false,
    required this.createdAt,
    this.jobsDone = 0,
  });

  factory WorkerModel.fromMap(Map<String, dynamic>? data, String id) {
    final map = data ?? {};
    WorkerCategory cat = WorkerCategory.electrician;
    try { cat = WorkerCategory.values.byName(map['category'] ?? 'electrician'); } catch (_) {}
    WorkerStatus st = WorkerStatus.pending;
    try { st = WorkerStatus.values.byName(map['status'] ?? 'pending'); } catch (_) {}

    return WorkerModel(
      workerId: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      cnic: map['cnic'] ?? '',
      category: cat,
      city: map['city'] ?? '',
      address: map['address'] ?? '',
      profilePicUrl: map['profilePicUrl'] ?? '',
      cnicPicUrl: map['cnicPicUrl'] ?? '',
      electricityBillUrl: map['electricityBillUrl'] ?? '',
      gasBillUrl: map['gasBillUrl'] ?? '',
      status: st,
      isBanned: map['isBanned'] ?? false,
      createdAt: map['createdAt'] != null && map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      jobsDone: map['jobsDone'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'phone': phone,
    'cnic': cnic,
    'category': category.name,
    'city': city,
    'address': address,
    'profilePicUrl': profilePicUrl,
    'cnicPicUrl': cnicPicUrl,
    'electricityBillUrl': electricityBillUrl,
    'gasBillUrl': gasBillUrl,
    'status': status.name,
    'isBanned': isBanned,
    'createdAt': Timestamp.fromDate(createdAt),
    'jobsDone': jobsDone,
  };
}
