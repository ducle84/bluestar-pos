class Appointment {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String technicianId;
  final String technicianName;
  final List<String> serviceIds;
  final List<String> serviceNames;
  final DateTime appointmentDate;
  final String timeSlot; // e.g., "9:00 AM", "10:30 AM"
  final double estimatedDuration; // in minutes
  final double estimatedPrice;
  final AppointmentStatus status;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? confirmationCode;

  Appointment({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail = '',
    required this.technicianId,
    required this.technicianName,
    required this.serviceIds,
    required this.serviceNames,
    required this.appointmentDate,
    required this.timeSlot,
    required this.estimatedDuration,
    required this.estimatedPrice,
    required this.status,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
    this.confirmationCode,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] ?? '',
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'] ?? '',
      customerEmail: json['customerEmail'] ?? '',
      technicianId: json['technicianId'] ?? '',
      technicianName: json['technicianName'] ?? '',
      serviceIds: List<String>.from(json['serviceIds'] ?? []),
      serviceNames: List<String>.from(json['serviceNames'] ?? []),
      appointmentDate: DateTime.parse(json['appointmentDate']),
      timeSlot: json['timeSlot'] ?? '',
      estimatedDuration: (json['estimatedDuration'] ?? 0).toDouble(),
      estimatedPrice: (json['estimatedPrice'] ?? 0).toDouble(),
      status: AppointmentStatus.values.firstWhere(
        (e) => e.toString() == 'AppointmentStatus.${json['status']}',
        orElse: () => AppointmentStatus.scheduled,
      ),
      notes: json['notes'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      confirmationCode: json['confirmationCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'technicianId': technicianId,
      'technicianName': technicianName,
      'serviceIds': serviceIds,
      'serviceNames': serviceNames,
      'appointmentDate': appointmentDate.toIso8601String(),
      'timeSlot': timeSlot,
      'estimatedDuration': estimatedDuration,
      'estimatedPrice': estimatedPrice,
      'status': status.toString().split('.').last,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'confirmationCode': confirmationCode,
    };
  }

  Appointment copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? technicianId,
    String? technicianName,
    List<String>? serviceIds,
    List<String>? serviceNames,
    DateTime? appointmentDate,
    String? timeSlot,
    double? estimatedDuration,
    double? estimatedPrice,
    AppointmentStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? confirmationCode,
  }) {
    return Appointment(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      technicianId: technicianId ?? this.technicianId,
      technicianName: technicianName ?? this.technicianName,
      serviceIds: serviceIds ?? this.serviceIds,
      serviceNames: serviceNames ?? this.serviceNames,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      timeSlot: timeSlot ?? this.timeSlot,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      confirmationCode: confirmationCode ?? this.confirmationCode,
    );
  }

  String get formattedDate {
    return '${appointmentDate.month}/${appointmentDate.day}/${appointmentDate.year}';
  }

  String get formattedDateTime {
    return '$formattedDate at $timeSlot';
  }

  String get statusDisplayName {
    switch (status) {
      case AppointmentStatus.scheduled:
        return 'Scheduled';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.inProgress:
        return 'In Progress';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.noShow:
        return 'No Show';
    }
  }
}

enum AppointmentStatus {
  scheduled,
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow,
}
