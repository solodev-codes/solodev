import 'package:cloud_firestore/cloud_firestore.dart';

class CertificateModel {
  final String id;
  final String title;
  final String issuer;
  final String description;
  final String imageUrl;
  final String? credentialUrl;
  final String? credentialId;
  final DateTime issueDate;
  final List<String> skills;
  final bool isFeatured;
  final bool isPublished;

  CertificateModel({
    required this.id,
    required this.title,
    required this.issuer,
    required this.description,
    required this.imageUrl,
    this.credentialUrl,
    this.credentialId,
    required this.issueDate,
    this.skills = const [],
    this.isFeatured = false,
    this.isPublished = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'issuer': issuer,
      'description': description,
      'imageUrl': imageUrl,
      'credentialUrl': credentialUrl,
      'credentialId': credentialId,
      'issueDate': Timestamp.fromDate(issueDate),
      'skills': skills,
      'isFeatured': isFeatured,
      'isPublished': isPublished,
    };
  }

  factory CertificateModel.fromMap(Map<String, dynamic> map, String id) {
    return CertificateModel(
      id: id,
      title: map['title'] as String? ?? '',
      issuer: map['issuer'] as String? ?? '',
      description: map['description'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      credentialUrl: map['credentialUrl'] as String?,
      credentialId: map['credentialId'] as String?,
      issueDate: (map['issueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      skills: List<String>.from(map['skills'] ?? []),
      isFeatured: map['isFeatured'] as bool? ?? false,
      isPublished: map['isPublished'] as bool? ?? true,
    );
  }
}

class AchievementModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime date;
  final String? imageUrl;
  final String? externalUrl;
  final bool isFeatured;
  final bool isPublished;

  AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.date,
    this.imageUrl,
    this.externalUrl,
    this.isFeatured = false,
    this.isPublished = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'date': Timestamp.fromDate(date),
      'imageUrl': imageUrl,
      'externalUrl': externalUrl,
      'isFeatured': isFeatured,
      'isPublished': isPublished,
    };
  }

  factory AchievementModel.fromMap(Map<String, dynamic> map, String id) {
    return AchievementModel(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: map['imageUrl'] as String?,
      externalUrl: map['externalUrl'] as String?,
      isFeatured: map['isFeatured'] as bool? ?? false,
      isPublished: map['isPublished'] as bool? ?? true,
    );
  }
}

class ContactMessageModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? service;
  final String subject;
  final String message;
  final String status; // 'new', 'read', 'in_progress', 'replied', 'closed'
  final DateTime createdAt;

  ContactMessageModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.service,
    required this.subject,
    required this.message,
    this.status = 'new',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'service': service,
      'subject': subject,
      'message': message,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ContactMessageModel.fromMap(Map<String, dynamic> map, String id) {
    return ContactMessageModel(
      id: id,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String?,
      service: map['service'] as String?,
      subject: map['subject'] as String? ?? '',
      message: map['message'] as String? ?? '',
      status: map['status'] as String? ?? 'new',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class SkillModel {
  final String id;
  final String name;
  final String category; // 'Mobile Development', 'Backend', 'AI & Design', 'Web & Tools'
  final String? icon;
  final int proficiency; // 1-100
  final bool isFeatured;
  final bool isPublished;
  final int sortOrder;

  SkillModel({
    required this.id,
    required this.name,
    required this.category,
    this.icon,
    this.proficiency = 90,
    this.isFeatured = true,
    this.isPublished = true,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'icon': icon,
      'proficiency': proficiency,
      'isFeatured': isFeatured,
      'isPublished': isPublished,
      'sortOrder': sortOrder,
    };
  }

  factory SkillModel.fromMap(Map<String, dynamic> map, String id) {
    return SkillModel(
      id: id,
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? 'Mobile Development',
      icon: map['icon'] as String?,
      proficiency: map['proficiency'] as int? ?? 90,
      isFeatured: map['isFeatured'] as bool? ?? true,
      isPublished: map['isPublished'] as bool? ?? true,
      sortOrder: map['sortOrder'] as int? ?? 0,
    );
  }
}

class ExperienceModel {
  final String id;
  final String organization;
  final String position;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final List<String> technologies;
  final List<String> responsibilities;
  final bool isPublished;

  ExperienceModel({
    required this.id,
    required this.organization,
    required this.position,
    required this.description,
    required this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.technologies = const [],
    this.responsibilities = const [],
    this.isPublished = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'organization': organization,
      'position': position,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isCurrent': isCurrent,
      'technologies': technologies,
      'responsibilities': responsibilities,
      'isPublished': isPublished,
    };
  }

  factory ExperienceModel.fromMap(Map<String, dynamic> map, String id) {
    return ExperienceModel(
      id: id,
      organization: map['organization'] as String? ?? '',
      position: map['position'] as String? ?? '',
      description: map['description'] as String? ?? '',
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate(),
      isCurrent: map['isCurrent'] as bool? ?? false,
      technologies: List<String>.from(map['technologies'] ?? []),
      responsibilities: List<String>.from(map['responsibilities'] ?? []),
      isPublished: map['isPublished'] as bool? ?? true,
    );
  }
}

/// Site-wide configuration authored by the administrator.
///
/// Every content field defaults to an empty string so that an absent or
/// partially saved document can never be rendered as an invented biography,
/// job title, statistic or contact detail. Callers must render an empty state
/// while [isConfigured] is false rather than substituting placeholder copy.
/// Orderable homepage section ids (spec section 23). The admin can hide a
/// section by removing it from `homeSections` and reorder with up/down.
const kHomeSectionCatalog = <String>[
  'services',
  'projects',
  'certificates',
  'achievements',
  'testimonials',
  'cta',
];

/// Human labels for [kHomeSectionCatalog].
const kHomeSectionLabels = <String, String>{
  'services': 'Featured Services',
  'projects': 'Featured Projects',
  'certificates': 'Certificates',
  'achievements': 'Achievements',
  'testimonials': 'Testimonials',
  'cta': 'Contact call-to-action',
};

/// Default homepage order shown before the admin customises anything.
const kDefaultHomeSections = <String>[
  'services',
  'projects',
  'certificates',
  'achievements',
  'testimonials',
  'cta',
];

class PortfolioSettingsModel {
  final String id;
  final String heroTitle;
  final String heroSubtitle;
  final String aboutText;
  final String avatarUrl;
  final String githubUrl;
  final String linkedinUrl;
  final String xUrl;
  final String whatsappNumber;
  final String contactEmail;
  final bool availableForHire;

  /// Ordered ids of the visible homepage sections (spec section 23).
  final List<String> homeSections;

  PortfolioSettingsModel({
    this.id = 'default',
    this.heroTitle = '',
    this.heroSubtitle = '',
    this.aboutText = '',
    this.avatarUrl = '',
    this.githubUrl = '',
    this.linkedinUrl = '',
    this.xUrl = '',
    this.whatsappNumber = '',
    this.contactEmail = '',
    this.availableForHire = false,
    List<String>? homeSections,
  }) : homeSections = homeSections ?? List.of(kDefaultHomeSections);

  /// Whether the administrator has authored any public-facing copy yet.
  bool get isConfigured =>
      heroTitle.isNotEmpty ||
      heroSubtitle.isNotEmpty ||
      aboutText.isNotEmpty;

  /// Whether at least one genuine social or contact channel was provided.
  bool get hasContactChannels =>
      githubUrl.isNotEmpty ||
      linkedinUrl.isNotEmpty ||
      xUrl.isNotEmpty ||
      whatsappNumber.isNotEmpty ||
      contactEmail.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'heroTitle': heroTitle,
      'heroSubtitle': heroSubtitle,
      'aboutText': aboutText,
      'avatarUrl': avatarUrl,
      'githubUrl': githubUrl,
      'linkedinUrl': linkedinUrl,
      'xUrl': xUrl,
      'whatsappNumber': whatsappNumber,
      'contactEmail': contactEmail,
      'availableForHire': availableForHire,
      'homeSections': homeSections,
    };
  }

  factory PortfolioSettingsModel.fromMap(Map<String, dynamic> map, String id) {
    // Drop unknown ids and duplicates so a bad document can never break the
    // homepage. An absent field (or one where nothing survived the filter)
    // falls back to the default order; an intentionally emptied list is kept.
    final raw = map['homeSections'];
    final stored = (raw as List?)
            ?.whereType<String>()
            .where(kHomeSectionCatalog.contains)
            .toSet() ??
        <String>{};
    final ordered = kDefaultHomeSections.where(stored.contains).toList()
      ..addAll(stored.where((id) => !kDefaultHomeSections.contains(id)));
    final corrupt = raw != null && raw.isNotEmpty && stored.isEmpty;
    return PortfolioSettingsModel(
      id: id,
      heroTitle: map['heroTitle'] as String? ?? '',
      heroSubtitle: map['heroSubtitle'] as String? ?? '',
      aboutText: map['aboutText'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String? ?? '',
      githubUrl: map['githubUrl'] as String? ?? '',
      linkedinUrl: map['linkedinUrl'] as String? ?? '',
      xUrl: map['xUrl'] as String? ?? '',
      whatsappNumber: map['whatsappNumber'] as String? ?? '',
      contactEmail: map['contactEmail'] as String? ?? '',
      availableForHire: map['availableForHire'] as bool? ?? false,
      homeSections: (raw == null || corrupt)
          ? List.of(kDefaultHomeSections)
          : ordered,
    );
  }
}

