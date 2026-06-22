import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/guidelines.dart';

final guidelinesLangProvider = StateProvider<bool>((ref) => true);

final fetchGuidelinesProvider =
    FutureProvider<List<CropGuideline>>((ref) async {
  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('guidelines')
      .select('*, crop_lifecycle_steps(*), crop_infections(*)')
      .eq('is_published', true);

  final list = response as List? ?? [];
  return list.map((item) => CropGuideline.fromJson(item)).toList();
});
