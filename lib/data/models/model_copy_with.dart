import 'more_models.dart';
import 'project_model.dart';
import 'service_model.dart';

/// Copy helpers for the immutable content models.
///
/// The models themselves stay plain data holders; these extensions exist so
/// admin screens can flip a single flag (`isPublished`, `isFeatured`) or bump
/// `sortOrder` without re-listing every field at each call site.
///
/// Note on nullable fields: passing `null` leaves the existing value untouched,
/// so these helpers cannot clear an optional field back to null. Full-form
/// editors construct a new model from their text controllers instead, which is
/// why no clearing sentinel is needed here.
extension ProjectModelCopyWith on ProjectModel {
  ProjectModel copyWith({
    String? title,
    String? shortDescription,
    String? fullDescription,
    String? category,
    List<String>? technologies,
    List<String>? platforms,
    String? coverImage,
    List<String>? images,
    List<String>? videos,
    List<String>? features,
    bool? isFeatured,
    bool? isPublished,
    int? viewsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectModel(
      id: id,
      title: title ?? this.title,
      shortDescription: shortDescription ?? this.shortDescription,
      fullDescription: fullDescription ?? this.fullDescription,
      category: category ?? this.category,
      technologies: technologies ?? this.technologies,
      platforms: platforms ?? this.platforms,
      coverImage: coverImage ?? this.coverImage,
      images: images ?? this.images,
      videos: videos ?? this.videos,
      projectUrl: projectUrl,
      githubUrl: githubUrl,
      appStoreUrl: appStoreUrl,
      playStoreUrl: playStoreUrl,
      features: features ?? this.features,
      challenge: challenge,
      solution: solution,
      result: result,
      isFeatured: isFeatured ?? this.isFeatured,
      isPublished: isPublished ?? this.isPublished,
      viewsCount: viewsCount ?? this.viewsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

extension ServiceModelCopyWith on ServiceModel {
  ServiceModel copyWith({
    String? title,
    String? shortDescription,
    String? fullDescription,
    String? iconName,
    String? coverImage,
    List<String>? technologies,
    List<String>? features,
    List<String>? process,
    List<String>? benefits,
    bool? isPublished,
    bool? isFeatured,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceModel(
      id: id,
      title: title ?? this.title,
      shortDescription: shortDescription ?? this.shortDescription,
      fullDescription: fullDescription ?? this.fullDescription,
      iconName: iconName ?? this.iconName,
      coverImage: coverImage ?? this.coverImage,
      technologies: technologies ?? this.technologies,
      features: features ?? this.features,
      process: process ?? this.process,
      benefits: benefits ?? this.benefits,
      isPublished: isPublished ?? this.isPublished,
      isFeatured: isFeatured ?? this.isFeatured,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

extension CertificateModelCopyWith on CertificateModel {
  CertificateModel copyWith({
    String? title,
    String? issuer,
    String? description,
    String? imageUrl,
    List<String>? skills,
    bool? isFeatured,
    bool? isPublished,
  }) {
    return CertificateModel(
      id: id,
      title: title ?? this.title,
      issuer: issuer ?? this.issuer,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      credentialUrl: credentialUrl,
      credentialId: credentialId,
      issueDate: issueDate,
      skills: skills ?? this.skills,
      isFeatured: isFeatured ?? this.isFeatured,
      isPublished: isPublished ?? this.isPublished,
    );
  }
}

extension AchievementModelCopyWith on AchievementModel {
  AchievementModel copyWith({
    String? title,
    String? description,
    String? category,
    DateTime? date,
    bool? isFeatured,
    bool? isPublished,
  }) {
    return AchievementModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      date: date ?? this.date,
      imageUrl: imageUrl,
      externalUrl: externalUrl,
      isFeatured: isFeatured ?? this.isFeatured,
      isPublished: isPublished ?? this.isPublished,
    );
  }
}

extension SkillModelCopyWith on SkillModel {
  SkillModel copyWith({
    String? name,
    String? category,
    int? proficiency,
    String? icon,
    bool? isFeatured,
    int? sortOrder,
    bool? isPublished,
  }) {
    return SkillModel(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      proficiency: proficiency ?? this.proficiency,
      icon: icon ?? this.icon,
      isFeatured: isFeatured ?? this.isFeatured,
      sortOrder: sortOrder ?? this.sortOrder,
      isPublished: isPublished ?? this.isPublished,
    );
  }
}

extension ExperienceModelCopyWith on ExperienceModel {
  ExperienceModel copyWith({
    String? organization,
    String? position,
    String? description,
    DateTime? startDate,
    bool? isCurrent,
    List<String>? technologies,
    List<String>? responsibilities,
    bool? isPublished,
  }) {
    return ExperienceModel(
      id: id,
      organization: organization ?? this.organization,
      position: position ?? this.position,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate,
      isCurrent: isCurrent ?? this.isCurrent,
      technologies: technologies ?? this.technologies,
      responsibilities: responsibilities ?? this.responsibilities,
      isPublished: isPublished ?? this.isPublished,
    );
  }
}