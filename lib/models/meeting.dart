class Meeting {
  /// Google Sheet row number (from Glide)
  final int? rowNumber;

  /// Glide "🔒 Row ID" (native row id in Glide)
  final String? rowId;

  /// Meeting heading
  final String heading;

  /// Whether meeting was created using current location
  final bool useCurrentLocation;

  /// Primary client
  final String client1Name;
  final String client1Email;

  /// Optional additional clients
  final String? client2Name;
  final String? client2Email;
  final String? client3Name;
  final String? client3Email;

  /// Meeting start time (from "Meeting Start Time" column in Glide)
  final DateTime? createdAt; // you can rename to meetingStartTime later if you want

  /// Creator user ID (Glide user ID)
  final String creatorId;

  /// Creator name
  final String creatorName;

  /// Creator email
  final String creatorEmail;

  /// Coordinates parsed from "Location" column ("lat,long")
  final double? latitude;
  final double? longitude;

  /// Optional description text
  final String? description;

  /// Recording URL / id. From "Recording" column.
  final String? recordingId;

  /// Optional status ("Status" column)
  final String? status;

  /// AI-generated meeting minutes (from "final" column)
  final String? finalMinutes;

  /// Bullet 1 – from "Agreed Actions"
  final String? agreedActions;

  /// Bullet 2 – from "Responsibilities"
  final String? responsibilities;

  /// Bullet 3 – from "Next Steps"
  final String? nextSteps;

  Meeting({
    this.rowNumber,
    this.rowId,
    required this.heading,
    required this.useCurrentLocation,
    required this.client1Name,
    required this.client1Email,
    this.client2Name,
    this.client2Email,
    this.client3Name,
    this.client3Email,
    this.createdAt,
    required this.creatorId,
    required this.creatorName,
    required this.creatorEmail,
    this.latitude,
    this.longitude,
    this.description,
    this.recordingId,
    this.status,
    this.finalMinutes,
    this.agreedActions,
    this.responsibilities,
    this.nextSteps,
  });

  /// Used when updating recording / minutes
  Meeting createCopyWith({
    String? recordingId,
    String? finalMinutes,
    String? agreedActions,
    String? responsibilities,
    String? nextSteps,
  }) {
    return Meeting(
      rowNumber: rowNumber,
      rowId: rowId,
      heading: heading,
      useCurrentLocation: useCurrentLocation,
      client1Name: client1Name,
      client1Email: client1Email,
      client2Name: client2Name,
      client2Email: client2Email,
      client3Name: client3Name,
      client3Email: client3Email,
      createdAt: createdAt,
      creatorId: creatorId,
      creatorName: creatorName,
      creatorEmail: creatorEmail,
      latitude: latitude,
      longitude: longitude,
      description: description,
      recordingId: recordingId ?? this.recordingId,
      status: status,
      finalMinutes: finalMinutes ?? this.finalMinutes,
      agreedActions: agreedActions ?? this.agreedActions,
      responsibilities: responsibilities ?? this.responsibilities,
      nextSteps: nextSteps ?? this.nextSteps,
    );
  }

  factory Meeting.fromSheetJson(Map<String, dynamic> row) {
    // Helper for cleaning null / "null" / "" values
    String? normalizeNullable(dynamic value) {
      if (value == null) return null;
      final s = value.toString().trim();
      if (s.isEmpty || s.toLowerCase() == 'null') return null;
      return s;
    }

    // 1) Row number – supports "row_number" and "rowNumber"
    final int? rowNumber = () {
      final raw = row['row_number'] ?? row['rowNumber'];
      if (raw is int) return raw;
      if (raw is String) return int.tryParse(raw);
      return null;
    }();

    // 2) Glide Row ID – supports "🔒 Row ID" and "rowId"
    final String? rowId =
        row['🔒 Row ID']?.toString() ?? row['rowId']?.toString();

    // 3) Heading – supports "heading" and legacy "Heading"
    final String heading =
        (row['heading'] ?? row['Heading'] ?? '').toString().trim();

    // 4) Client 1 – supports sheet keys + slim keys
    final String client1Name =
        (row['Client Name'] ?? row['clientName'] ?? '')
            .toString()
            .trim();

    final String client1Email =
        (row['Client Email'] ?? row['clientEmail'] ?? '')
            .toString()
            .trim();

    // 5) Extra clients – handle null / "null"
    final String? client2Name = normalizeNullable(
      row['2nd Client Name'] ??
          row['2nd CLient Name '] ??
          row['client2Name'],
    );

    final String? client2Email = normalizeNullable(
      row['2nd Client Email'] ?? row['client2Email'],
    );

    final String? client3Name = normalizeNullable(
      row['3rd Client Name'] ?? row['client3Name'],
    );

    final String? client3Email = normalizeNullable(
      row['3rd Client Email'] ??
          row['3rd Client Email copy'] ?? // in case sheet uses this
          row['client3Email'],
    );

    // 6) Creator info – supports sheet + slim keys
    final String creatorId =
        (row['Creator'] ?? row['creatorId'] ?? '')
            .toString()
            .trim();

    final String creatorEmail =
        (row["Creator's Email"] ??
                row['Creators Email'] ??
                row['creatorEmail'] ??
                '')
            .toString()
            .trim();

    final String creatorName =
        (row["Creator's Name"] ?? row['creatorName'] ?? '')
            .toString()
            .trim();

    // 7) Description
    final String? description =
        normalizeNullable(row['Description'] ?? row['description']);

    // 8) Status
    final String? status =
        normalizeNullable(row['Status'] ?? row['status']);

    // 9) Recording (if present)
    final String? recordingId = normalizeNullable(
      row['Recording'] ?? row['recordingId'] ?? row['recordingUrl'],
    );

    // 10) Location "lat,long"
    double? latitude;
    double? longitude;
    final locRaw = row['Location']?.toString().trim();
    if (locRaw != null && locRaw.contains(',')) {
      final parts = locRaw.split(',');
      if (parts.length >= 2) {
        latitude = double.tryParse(parts[0].trim());
        longitude = double.tryParse(parts[1].trim());
      }
    }

    // 11) Meeting start time – support all possible keys
    DateTime? createdAt;
    final createdRaw =
        row['Meeting Start Time'] ??   // main Glide column
        row['meetingStartTime'] ??     // column key
        row['Created At'] ??           // older name
        row['createdAt'];              // older key

    if (createdRaw != null) {
      final s = createdRaw.toString().trim();
      if (s.isNotEmpty) {
        try {
          createdAt = DateTime.parse(s);
        } catch (_) {
          // ignore if not ISO
        }
      }
    }

    // 12) useCurrentLocation – default true if we have coords
    final bool useCurrentLocation =
        (row['useCurrentLocation'] == true) ||
            (latitude != null && longitude != null);

    // 13) AI minutes + bullet points
    final String? finalMinutes =
        normalizeNullable(row['final'] ?? row['Final']);

    final String? agreedActions = normalizeNullable(
      row['Point 1'] ?? row['Agreed Actions'] ?? row['agreedActions'],
    );

    final String? responsibilities = normalizeNullable(
      row['Point 2'] ?? row['Responsibilities'] ?? row['responsibilities'],
    );

    final String? nextSteps = normalizeNullable(
      row['Point 3'] ?? row['Next Steps'] ?? row['nextSteps'],
    );

    return Meeting(
      rowNumber: rowNumber,
      rowId: rowId,
      heading: heading,
      useCurrentLocation: useCurrentLocation,
      client1Name: client1Name,
      client1Email: client1Email,
      client2Name: client2Name,
      client2Email: client2Email,
      client3Name: client3Name,
      client3Email: client3Email,
      createdAt: createdAt,
      creatorId: creatorId,
      creatorName: creatorName,
      creatorEmail: creatorEmail,
      latitude: latitude,
      longitude: longitude,
      description: description,
      recordingId: recordingId,
      status: status,
      finalMinutes: finalMinutes,
      agreedActions: agreedActions,
      responsibilities: responsibilities,
      nextSteps: nextSteps,
    );
  }

  /// Used by MeetingBottomSheet when creating via Glide mutateTables
  ///
  /// This returns exactly the `columnValues` object for the mutation:
  /// {
  ///   "Meeting Start Time": "...",
  ///   "Client Name": "...",
  ///   ...
  /// }
  Map<String, dynamic> toJsonForCreate() {
  final Map<String, dynamic> values = {
    // ✅ These MUST match Glide column names exactly (as in your CURL)
    'heading': heading,
    'Client Name': client1Name,
    'Client Email': client1Email,

    // Creator
    'Creator': creatorId,
    "Creator's Email": creatorEmail,
    // Only include this if you really have a column called "Creator's Name"
    // "Creator's Name": creatorName,
  };

  // ✅ Meeting Start Time (Glide date-time)
  if (createdAt != null) {
    values['Meeting Start Time'] = createdAt!.toUtc().toIso8601String();
  }

  // ✅ Optional extra clients (ONLY if not empty)
  if (client2Name != null && client2Name!.trim().isNotEmpty) {
    values['2nd Client Name'] = client2Name!.trim();
  }
  if (client2Email != null && client2Email!.trim().isNotEmpty) {
    values['2nd Client Email'] = client2Email!.trim();
  }
  if (client3Name != null && client3Name!.trim().isNotEmpty) {
    values['3rd Client Name'] = client3Name!.trim();
  }
  if (client3Email != null && client3Email!.trim().isNotEmpty) {
    values['3rd Client Email copy'] = client3Email!.trim();
  }

  // ✅ Location
  if (latitude != null && longitude != null) {
    values['Location'] = '$latitude,$longitude';
  }

  // ✅ Optional text fields if you want (only if filled)
  if (description != null && description!.trim().isNotEmpty) {
    values['Description'] = description!.trim();
  }

  // ✅ Key points
  if (agreedActions != null && agreedActions!.trim().isNotEmpty) {
    values['Agreed Actions'] = agreedActions!.trim();
  }
  if (responsibilities != null && responsibilities!.trim().isNotEmpty) {
    values['Responsibilities'] = responsibilities!.trim();
  }
  if (nextSteps != null && nextSteps!.trim().isNotEmpty) {
    values['Next Steps'] = nextSteps!.trim();
  }

  // ✅ If you want a default Status on create, uncomment:
  // values['Status'] = 'Open';

  return values;
}

}
