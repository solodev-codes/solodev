import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/project_model.dart';
import '../models/service_model.dart';
import '../models/more_models.dart';
import '../models/testimonial_model.dart';
import '../../core/services/media_compressor_service.dart';

class PortfolioRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  PortfolioRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  // ================= PROJECTS =================
  Stream<List<ProjectModel>> streamPublishedProjects() {
    return _firestore
        .collection('projects')
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ProjectModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<ProjectModel>> streamAllProjects() {
    return _firestore.collection('projects').snapshots().map((snap) =>
        snap.docs.map((doc) => ProjectModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> saveProject(ProjectModel project) async {
    final col = _firestore.collection('projects');
    if (project.id.isEmpty) {
      await col.add(project.toMap());
    } else {
      await col.doc(project.id).set(project.toMap(), SetOptions(merge: true));
    }
  }

  Future<void> deleteProject(String id) async {
    await _firestore.collection('projects').doc(id).delete();
  }

  // ================= SERVICES =================
  Stream<List<ServiceModel>> streamPublishedServices() {
    return _firestore
        .collection('services')
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ServiceModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<ServiceModel>> streamAllServices() {
    return _firestore.collection('services').snapshots().map((snap) =>
        snap.docs.map((doc) => ServiceModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> saveService(ServiceModel service) async {
    final col = _firestore.collection('services');
    if (service.id.isEmpty) {
      await col.add(service.toMap());
    } else {
      await col.doc(service.id).set(service.toMap(), SetOptions(merge: true));
    }
  }

  Future<void> deleteService(String id) async {
    await _firestore.collection('services').doc(id).delete();
  }

  // ================= CERTIFICATES =================
  Stream<List<CertificateModel>> streamPublishedCertificates() {
    return _firestore
        .collection('certificates')
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => CertificateModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<CertificateModel>> streamAllCertificates() {
    return _firestore.collection('certificates').snapshots().map((snap) =>
        snap.docs
            .map((doc) => CertificateModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> saveCertificate(CertificateModel cert) async {
    final col = _firestore.collection('certificates');
    if (cert.id.isEmpty) {
      await col.add(cert.toMap());
    } else {
      await col.doc(cert.id).set(cert.toMap(), SetOptions(merge: true));
    }
  }

  Future<void> deleteCertificate(String id) async {
    await _firestore.collection('certificates').doc(id).delete();
  }

  // ================= CONTACT MESSAGES =================
  Future<void> submitContactMessage(ContactMessageModel message) async {
    await _firestore.collection('messages').add(message.toMap());
  }

  Stream<List<ContactMessageModel>> streamContactMessages() {
    return _firestore
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ContactMessageModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Applies a status transition to an enquiry.
  ///
  /// [updatedBy] is recorded so the `onMessageStatusChanged` Cloud Function can
  /// attribute the audit entry to a person rather than falling back to `system`.
  Future<void> updateMessageStatus(
    String id,
    String status, {
    String? updatedBy,
  }) async {
    await _firestore.collection('messages').doc(id).update({
      'status': status,
      if (updatedBy != null) 'updatedBy': updatedBy,
    });
  }

  Future<void> deleteMessage(String id) async {
    await _firestore.collection('messages').doc(id).delete();
  }

  // ================= ACHIEVEMENTS =================
  Stream<List<AchievementModel>> streamPublishedAchievements() {
    return _firestore
        .collection('achievements')
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AchievementModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<AchievementModel>> streamAllAchievements() {
    return _firestore.collection('achievements').snapshots().map((snap) =>
        snap.docs.map((doc) => AchievementModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> saveAchievement(AchievementModel achievement) async {
    final col = _firestore.collection('achievements');
    if (achievement.id.isEmpty) {
      await col.add(achievement.toMap());
    } else {
      await col.doc(achievement.id).set(achievement.toMap(), SetOptions(merge: true));
    }
  }

  Future<void> deleteAchievement(String id) async {
    await _firestore.collection('achievements').doc(id).delete();
  }

  // ================= TESTIMONIALS =================
  Stream<List<TestimonialModel>> streamPublishedTestimonials() {
    return _firestore
        .collection('testimonials')
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TestimonialModel.fromMap(doc.data(), doc.id))
            .toList()
          // Sorted client-side: an `orderBy` beside the `where` would demand
          // a composite index that `firestore.indexes.json` does not declare.
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)));
  }

  Stream<List<TestimonialModel>> streamAllTestimonials() {
    return _firestore.collection('testimonials').snapshots().map((snap) =>
        snap.docs.map((doc) => TestimonialModel.fromMap(doc.data(), doc.id)).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)));
  }

  Future<void> saveTestimonial(TestimonialModel testimonial) async {
    final col = _firestore.collection('testimonials');
    if (testimonial.id.isEmpty) {
      await col.add(testimonial.toMap());
    } else {
      await col.doc(testimonial.id).set(testimonial.toMap(), SetOptions(merge: true));
    }
  }

  Future<void> deleteTestimonial(String id) async {
    await _firestore.collection('testimonials').doc(id).delete();
  }

  // ================= EXPERIENCES =================
  Stream<List<ExperienceModel>> streamPublishedExperiences() {
    return _firestore
        .collection('experiences')
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ExperienceModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<ExperienceModel>> streamAllExperiences() {
    return _firestore.collection('experiences').snapshots().map((snap) =>
        snap.docs.map((doc) => ExperienceModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> saveExperience(ExperienceModel exp) async {
    final col = _firestore.collection('experiences');
    if (exp.id.isEmpty) {
      await col.add(exp.toMap());
    } else {
      await col.doc(exp.id).set(exp.toMap(), SetOptions(merge: true));
    }
  }

  Future<void> deleteExperience(String id) async {
    await _firestore.collection('experiences').doc(id).delete();
  }

  // ================= SKILLS =================

  /// Public read of published skills, ordered by the authored [sortOrder].
  ///
  /// Filtering on `isPublished` keeps this query consistent with the
  /// `skills` Firestore rule, which denies non-admins unpublished documents.
  Stream<List<SkillModel>> streamSkills() {
    return _firestore
        .collection('skills')
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => SkillModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return list;
    });
  }

  /// Admin read of every skill, including unpublished drafts.
  Stream<List<SkillModel>> streamAllSkills() {
    return _firestore.collection('skills').snapshots().map((snap) => snap.docs
        .map((doc) => SkillModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  Future<void> saveSkill(SkillModel skill) async {
    final col = _firestore.collection('skills');
    if (skill.id.isEmpty) {
      await col.add(skill.toMap());
    } else {
      await col.doc(skill.id).set(skill.toMap(), SetOptions(merge: true));
    }
  }

  Future<void> deleteSkill(String id) async {
    await _firestore.collection('skills').doc(id).delete();
  }

  // ================= PORTFOLIO SETTINGS =================
  Stream<PortfolioSettingsModel> streamSettings() {
    return _firestore.collection('settings').doc('default').snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return PortfolioSettingsModel();
      }
      return PortfolioSettingsModel.fromMap(doc.data()!, doc.id);
    });
  }

  Future<void> saveSettings(PortfolioSettingsModel settings) async {
    await _firestore
        .collection('settings')
        .doc('default')
        .set(settings.toMap(), SetOptions(merge: true));
  }

  // ================= COMPRESSED MEDIA UPLOAD =================
  Future<String> uploadCompressedImage({
    required Uint8List bytes,
    required String path,
    int maxDimension = 1920,
    void Function(double progress)? onProgress,
  }) async {
    final compressedBytes = await MediaCompressorService.compressImageBytes(
      bytes,
      maxDimension: maxDimension,
    );
    final ref = _storage.ref().child(path);
    final task = ref.putData(
      compressedBytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    await _reportProgress(task, onProgress);
    final saved = await task;
    return saved.ref.getDownloadURL();
  }


  /// Uploads a video without client-side transcoding.
  ///
  /// Spec section 16 warns that native video APIs do not behave identically on
  /// web, and no FFmpeg dependency exists, so the file is validated against the
  /// Storage rules instead of being re-encoded. Exceeding the cap fails here,
  /// before any bytes are sent.
  Future<String> uploadVideo({
    required Uint8List bytes,
    required String path,
    String contentType = 'video/mp4',
    void Function(double progress)? onProgress,
  }) async {
    const maxBytes = 25 * 1024 * 1024;
    if (bytes.lengthInBytes > maxBytes) {
      final actual = (bytes.lengthInBytes / (1024 * 1024)).toStringAsFixed(1);
      throw ArgumentError(
        'Video is $actual MB but the Storage limit is 25 MB. '
        'Compress it, or paste a link instead.',
      );
    }

    final ref = _storage.ref().child(path);
    final task = ref.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );
    await _reportProgress(task, onProgress);
    final saved = await task;
    return saved.ref.getDownloadURL();
  }
/// Relays Firebase upload progress to the UI without blocking the transfer.
  static Future<void> _reportProgress(
    UploadTask task,
    void Function(double progress)? onProgress,
  ) async {
    if (onProgress == null) return;
    await for (final snapshot in task.snapshotEvents) {
      if (snapshot.totalBytes > 0) {
        onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
      }
    }
  }
}
