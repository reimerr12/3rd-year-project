import 'package:supabase_flutter/supabase_flutter.dart';

class CropGuideline {
  final String id;
  final String nameEn;
  final String nameBn;
  final String category;
  final String? descriptionEn;
  final String? descriptionBn;
  final String? coverImage;
  final List<LifecycleStep> steps;
  final List<CropInfection> infections;

  CropGuideline({
    required this.id,
    required this.nameEn,
    required this.nameBn,
    required this.category,
    this.descriptionEn,
    this.descriptionBn,
    this.coverImage,
    required this.steps,
    required this.infections,
  });

  factory CropGuideline.fromJson(Map<String, dynamic> json) {
    final stepsList = (json['crop_lifecycle_steps'] as List? ?? [])
        .map((e) => LifecycleStep.fromJson(e))
        .toList();
    final infectionsList = (json['crop_infections'] as List? ?? [])
        .map((e) => CropInfection.fromJson(e))
        .toList();

    String? resolvedCoverImage = json['cover_image'];
    if (resolvedCoverImage != null && resolvedCoverImage.isNotEmpty) {
      final fileName = resolvedCoverImage.split('/').last;
      resolvedCoverImage = Supabase.instance.client.storage
          .from('crop-images')
          .getPublicUrl('covers/$fileName');
    }

    return CropGuideline(
      id: json['id'] ?? '',
      nameEn: json['crop_name_en'] ?? '',
      nameBn: json['crop_name_bn'] ?? '',
      category: json['category'] ?? 'other',
      descriptionEn: json['description_en'],
      descriptionBn: json['description_bn'],
      coverImage: resolvedCoverImage,
      steps: stepsList,
      infections: infectionsList,
    );
  }
}

class LifecycleStep {
  final String id;
  final String stageType;
  final int stepOrder;
  final String titleEn;
  final String titleBn;
  final String instructionsEn;
  final String instructionsBn;
  final String? blogContentEn;
  final String? blogContentBn;
  final String? imageUrl;
  final String? videoYoutubeId;

  LifecycleStep({
    required this.id,
    required this.stageType,
    required this.stepOrder,
    required this.titleEn,
    required this.titleBn,
    required this.instructionsEn,
    required this.instructionsBn,
    this.blogContentEn,
    this.blogContentBn,
    this.imageUrl,
    this.videoYoutubeId,
  });

  factory LifecycleStep.fromJson(Map<String, dynamic> json) {
    return LifecycleStep(
      id: json['id'] ?? '',
      stageType: json['stage_type'] ?? '',
      stepOrder: json['step_order'] ?? 1,
      titleEn: json['title_en'] ?? '',
      titleBn: json['title_bn'] ?? '',
      instructionsEn: json['instructions_en'] ?? '',
      instructionsBn: json['instructions_bn'] ?? '',
      blogContentEn: json['blog_content_en'],
      blogContentBn: json['blog_content_bn'],
      imageUrl: json['image_url'],
      videoYoutubeId: json['video_youtube_id'],
    );
  }
}

class CropInfection {
  final String id;
  final String nameEn;
  final String nameBn;
  final String symptomsEn;
  final String symptomsBn;
  final String remedyEn;
  final String remedyBn;
  final String? remedyDetailsEn;
  final String? remedyDetailsBn;
  final String? imageUrl;
  final String? videoYoutubeId;

  CropInfection({
    required this.id,
    required this.nameEn,
    required this.nameBn,
    required this.symptomsEn,
    required this.symptomsBn,
    required this.remedyEn,
    required this.remedyBn,
    this.remedyDetailsEn,
    this.remedyDetailsBn,
    this.imageUrl,
    this.videoYoutubeId,
  });

  factory CropInfection.fromJson(Map<String, dynamic> json) {
    final rawRemedyEn = json['remedy_en'] ?? '';
    final rawRemedyBn = json['remedy_bn'] ?? '';

    return CropInfection(
      id: json['id'] ?? '',
      nameEn: json['name_en'] ?? '',
      nameBn: json['name_bn'] ?? '',
      symptomsEn: json['symptoms_en'] ?? '',
      symptomsBn: json['symptoms_bn'] ?? '',
      remedyEn: rawRemedyEn,
      remedyBn: rawRemedyBn,
      remedyDetailsEn: json['remedy_details_en'] ?? rawRemedyEn,
      remedyDetailsBn: json['remedy_details_bn'] ?? rawRemedyBn,
    );
  }
}
