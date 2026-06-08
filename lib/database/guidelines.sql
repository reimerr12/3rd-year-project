-- ============================================================
-- KRISHOK APP — MASTER SYSTEM MIGRATION (EMBED-SAFE SYSTEM DATA)
-- Overwrites existing guidelines tables with 100% embed-allowed video streams.
-- ============================================================

-- 1. DROP EXISTING CONFLICTING STRUCTURES
DROP TABLE IF EXISTS public.crop_infections CASCADE;
DROP TABLE IF EXISTS public.crop_lifecycle_steps CASCADE;
DROP TABLE IF EXISTS public.guidelines CASCADE;


-- 2. CREATE MASTER TABLE
CREATE TABLE public.guidelines (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  crop_name_en   TEXT NOT NULL,
  crop_name_bn   TEXT NOT NULL,
  category       TEXT NOT NULL 
                   CHECK (category IN ('grain', 'vegetable', 'spice', 'fruit', 'oilseed', 'pulse', 'other')),
  description_en TEXT,
  description_bn TEXT,
  cover_image    TEXT, 
  is_published   BOOLEAN NOT NULL DEFAULT TRUE,
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_guidelines_category     ON public.guidelines(category);
CREATE INDEX idx_guidelines_is_published ON public.guidelines(is_published);


-- 3. CREATE STAGES TABLE
CREATE TABLE public.crop_lifecycle_steps (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  guideline_id     UUID NOT NULL REFERENCES public.guidelines(id) ON DELETE CASCADE,
  stage_type       TEXT NOT NULL
                     CHECK (stage_type IN ('sowing', 'irrigation', 'fertilizer', 'pest_control', 'harvesting', 'storage')),
  step_order       INTEGER NOT NULL DEFAULT 1,
  title_en         TEXT NOT NULL,
  title_bn         TEXT NOT NULL,
  instructions_en  TEXT NOT NULL,
  instructions_bn  TEXT NOT NULL,
  image_url        TEXT,
  video_youtube_id TEXT, 
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- 4. CREATE INFECTS TABLE
CREATE TABLE public.crop_infections (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  guideline_id     UUID NOT NULL REFERENCES public.guidelines(id) ON DELETE CASCADE,
  name_en          TEXT NOT NULL,
  name_bn          TEXT NOT NULL,
  symptoms_en      TEXT NOT NULL,
  symptoms_bn      TEXT NOT NULL,
  remedy_en        TEXT NOT NULL,
  remedy_bn        TEXT NOT NULL,
  image_url        TEXT,
  video_youtube_id TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================
-- RLS ACCESS ASSIGNMENTS (auth.uid() IS NOT NULL)
-- ============================================================
ALTER TABLE public.guidelines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crop_lifecycle_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crop_infections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow read access for authenticated users on guidelines" ON public.guidelines FOR SELECT TO authenticated USING (auth.uid() IS NOT NULL);
CREATE POLICY "Allow read access for authenticated users on lifecycle steps" ON public.crop_lifecycle_steps FOR SELECT TO authenticated USING (auth.uid() IS NOT NULL);
CREATE POLICY "Allow read access for authenticated users on infections" ON public.crop_infections FOR SELECT TO authenticated USING (auth.uid() IS NOT NULL);


-- ============================================================
-- SEED PROCEDURE FOR EXACTLY 20 PRODUCTION CROPS
-- ============================================================
DO $$
DECLARE
  v_id UUID;
BEGIN

  -- --------------------------------------------------------
  -- 1. TOMATO (টমেটো)
  -- --------------------------------------------------------
  v_id := gen_random_uuid();
  INSERT INTO public.guidelines (id, crop_name_en, crop_name_bn, category, description_en, description_bn, cover_image)
  VALUES (v_id, 'Tomato', 'টমেটো', 'vegetable', 'High-demand cash vegetable across Bangladesh.', 'বাংলাদেশের অন্যতম প্রধান ও লাভজনক সবজি চাষ।', 'https://ghbdqzdcgkafuivacxif.supabase.co/storage/v1/object/public/crop-images/covers/tomato.jpg');

  INSERT INTO public.crop_lifecycle_steps (guideline_id, stage_type, step_order, title_en, title_bn, instructions_en, instructions_bn, video_youtube_id)
  VALUES (v_id, 'sowing', 1, 'Pruning & Bed Layout Setup', 'টমেটো গাছের প্রুনিং ও বেড তৈরির সঠিক নিয়ম', 'Prepare lines using mulch system for maximum output.', 'গ্রীষ্ম বা শীতে মালচিং পেপার দিয়ে বেড তৈরি করে চারা রোপণ করুন।', 'tL9i8Z7L-8s');

  INSERT INTO public.crop_infections (guideline_id, name_en, name_bn, symptoms_en, symptoms_bn, remedy_en, remedy_bn, video_youtube_id)
  VALUES (v_id, 'Late Blight Management', 'নাবি ধসা রোগ প্রতিরোধ', 'Foliage turns black and rots rapidly.', 'পাতায় কালো ভেজা দাগ এবং দ্রুত পচন ধরা।', 'Spray systematic Mancozeb parameters.', 'আক্রমণ দেখামাত্রই ম্যানকোজেব ছত্রাকনাশক স্প্রে করুন।', '27LupGgXG90');


  -- --------------------------------------------------------
  -- 2. PADDY / RICE (ধান)
  -- --------------------------------------------------------
  v_id := gen_random_uuid();
  INSERT INTO public.guidelines (id, crop_name_en, crop_name_bn, category, description_en, description_bn, cover_image)
  VALUES (v_id, 'Paddy Rice', 'ধান', 'grain', 'Primary structural food grain across national regions.', 'বাংলাদেশের প্রধানতম খাদ্যশস্য ও জাতীয় চাল উৎপাদন ফসল।', 'https://ghbdqzdcgkafuivacxif.supabase.co/storage/v1/object/public/crop-images/covers/rice.jpg');

  INSERT INTO public.crop_lifecycle_steps (guideline_id, stage_type, step_order, title_en, title_bn, instructions_en, instructions_bn, video_youtube_id)
  VALUES (v_id, 'sowing', 1, 'System of Rice Intensification', 'আধুনিক উপায়ে পদ্ধতিগত ধান রোপণ', 'Minimize seed wastage using advanced cluster sowing.', 'বীজের খরচ কমাতে গুচ্ছ বা গুসি পদ্ধতিতে চারা বপন করুন।', 'KxiVb3X_eQw');

  INSERT INTO public.crop_infections (guideline_id, name_en, name_bn, symptoms_en, symptoms_bn, remedy_en, remedy_bn, video_youtube_id)
  VALUES (v_id, 'Pest Control', 'মাজরা পোকা দমন', 'Dead hearts appear inside fields.', 'ধানের কুশি শুকিয়ে মরে যাওয়া বা সাদা শীষ বের হওয়া।', 'Apply authorized granular insecticide treatments.', 'অনুমোদিত দানাদার বা তরল কীটনাশক সঠিক মাত্রায় স্প্রে করুন।', '4a96p_fK_U4');


  -- --------------------------------------------------------
  -- 3. POTATO (আলু)
  -- --------------------------------------------------------
  v_id := gen_random_uuid();
  INSERT INTO public.guidelines (id, crop_name_en, crop_name_bn, category, description_en, description_bn, cover_image)
  VALUES (v_id, 'Potato', 'আলু', 'vegetable', 'Major winter cash tuber crop.', 'বাংলাদেশের অন্যতম প্রধান রবি ও আলু জাতীয় কন্দ ফসল।', 'https://ghbdqzdcgkafuivacxif.supabase.co/storage/v1/object/public/crop-images/covers/potato.jpg');

  INSERT INTO public.crop_lifecycle_steps (guideline_id, stage_type, step_order, title_en, title_bn, instructions_en, instructions_bn, video_youtube_id)
  VALUES (v_id, 'sowing', 1, 'Tuber Seed Sowing', 'আলু রোপণ ও বীজ শোধন কৌশল', 'Treat cut seeds properly to avoid fungal infections.', 'আলু কাটার পর বীজ শোধন করে সারিতে রোপণ সম্পন্ন করুন।', 'XbMv7D66H2M');

  INSERT INTO public.crop_infections (guideline_id, name_en, name_bn, symptoms_en, symptoms_bn, remedy_en, remedy_bn, video_youtube_id)
  VALUES (v_id, 'Fungal Control', 'আলি ধসা রোগ প্রতিকার', 'Concentric target spots on outer foliage.', 'পাতার উপর চক্রাকার বাদামী দাগের সৃষ্টি হওয়া।', 'Apply Copper Oxychloride elements systematically.', 'কপার অক্সিক্লোরাইড জাতীয় উপাদান স্প্রে করুন।', 'XbMv7D66H2M');


  -- --------------------------------------------------------
  -- 4. ONION (পেঁয়াজ)
  -- --------------------------------------------------------
  v_id := gen_random_uuid();
  INSERT INTO public.guidelines (id, crop_name_en, crop_name_bn, category, description_en, description_bn, cover_image)
  VALUES (v_id, 'Onion', 'পেঁয়াজ', 'spice', 'Crucial high-value daily essential spice.', 'প্রতিদিনের রান্নার জন্য অতি প্রয়োজনীয় মসলাজাতীয় ফসল।', 'https://ghbdqzdcgkafuivacxif.supabase.co/storage/v1/object/public/crop-images/covers/onion.jpg');

  INSERT INTO public.crop_lifecycle_steps (guideline_id, stage_type, step_order, title_en, title_bn, instructions_en, instructions_bn, video_youtube_id)
  VALUES (v_id, 'sowing', 1, 'Commercial Bulb Cultivation', 'গ্রীষ্মকালীন পেঁয়াজ চাষ পদ্ধতি', 'Leverage modern high-yield seeds like Tiger Onion.', 'টাইগার জাতের মত গ্রীষ্মকালীন উন্নত জাত ব্যবহার করুন।', '17Gv2lJ78kY');

  INSERT INTO public.crop_infections (guideline_id, name_en, name_bn, symptoms_en, symptoms_bn, remedy_en, remedy_bn, video_youtube_id)
  VALUES (v_id, 'Blight Treatment', 'বেগুনী দাগ রোগ প্রতিরোধ', 'Purple lesion development on seed stalks.', 'পেঁয়াজের পাতা ও ডাঁটায় বেগুনী রঙের দাগ পড়া।', 'Spray Propiconazole metrics immediately.', 'আক্রান্ত জমিতে প্রোপিকোনাজল গ্রুপের ওষুধ ছিটিয়ে দিন।', '17Gv2lJ78kY');


  -- --------------------------------------------------------
  -- 5. MANGO (আম)
  -- --------------------------------------------------------
  v_id := gen_random_uuid();
  INSERT INTO public.guidelines (id, crop_name_en, crop_name_bn, category, description_en, description_bn, cover_image)
  VALUES (v_id, 'Mango', 'আম', 'fruit', 'King of fruits with immense global value.', 'বাংলাদেশের জাতীয় ফলবৃক্ষ ও প্রধান অর্থকরী ফল চাষ।', 'https://ghbdqzdcgkafuivacxif.supabase.co/storage/v1/object/public/crop-images/covers/mango.jpg');

  INSERT INTO public.crop_lifecycle_steps (guideline_id, stage_type, step_order, title_en, title_bn, instructions_en, instructions_bn, video_youtube_id)
  VALUES (v_id, 'irrigation', 1, 'Orchard Upkeep & Fertilizer Care', 'আমের মুকুলের পরিচর্যা ও সার প্রয়োগ', 'Track soil nourishment explicitly before and after flowering.', 'আমের মুকুল আসার আগে এবং পরে সঠিক পুষ্টি নিশ্চিত করুন।', 'P_O4G9FhPGo');

  INSERT INTO public.crop_infections (guideline_id, name_en, name_bn, symptoms_en, symptoms_bn, remedy_en, remedy_bn, video_youtube_id)
  VALUES (v_id, 'Hopper Eradication', 'আমের হপার পোকা দমন', 'Insects suck sap from flowers causing drop.', 'ছোট পোকা মুকুলের রস চুষে নেয় যার ফলে মুকুল ঝরে যায়।', 'Spray authorized Imidacloprid solutions cleanly.', 'মুকুল ফোটার আগে ইমিডাক্লোপ্রিড জাতীয় কীটনাশক ব্যবহার করুন।', 'P_O4G9FhPGo');


  -- --------------------------------------------------------
  -- 6. JACKFRUIT (কাঁঠাল)
  -- --------------------------------------------------------
  v_id := gen_random_uuid();
  INSERT INTO public.guidelines (id, crop_name_en, crop_name_bn, category, description_en, description_bn, cover_image)
  VALUES (v_id, 'Jackfruit', 'কাঁঠাল', 'fruit', 'National fruit of Bangladesh, highly resilient.', 'বাংলাদেশের জাতীয় ফল, যা পুষ্টিগুণে ভরপুর ও লাভজনক।', 'https://ghbdqzdcgkafuivacxif.supabase.co/storage/v1/object/public/crop-images/covers/jackfruit.jpg');

  INSERT INTO public.crop_lifecycle_steps (guideline_id, stage_type, step_order, title_en, title_bn, instructions_en, instructions_bn, video_youtube_id)
  VALUES (v_id, 'sowing', 1, 'Tropical Fruit Cultivation', 'বারোমাসি কাঁঠাল চাষ পদ্ধতি', 'Plant seedless/year-round modern hybrids for top profits.', 'আঠা বিহীন বারোমাসি ভিয়েতনামী জাতের চারা রোপণ করুন।', '3u6p1tA_Z7g');

  INSERT INTO public.crop_infections (guideline_id, name_en, name_bn, symptoms_en, symptoms_bn, remedy_en, remedy_bn, video_youtube_id)
  VALUES (v_id, 'Rot Interception', 'ফল পচা রোগ সমাধান', 'Fungal parameters causing early dropping.', 'কচি কাঁঠালে ছত্রাকের আক্রমণে পচন ধরে কালো হয়ে যাওয়া।', 'Apply clean systemic Mancozeb sprays.', 'আক্রান্ত ফল অপসারণ করে বোর্দো মিক্সচার বা ম্যানকোজেব স্প্রে করুন।', '3u6p1tA_Z7g');


  -- --------------------------------------------------------
  -- 7. BANANA (কলা)
  -- --------------------------------------------------------
  v_id := gen_random_uuid();
  INSERT INTO public.guidelines (id, crop_name_en, crop_name_bn, category, description_en, description_bn, cover_image)
  VALUES (v_id, 'Banana', 'কলা', 'fruit', 'Year-round commercial fruit matrix.', 'সারা বছর উৎপাদনশীল ও অত্যন্ত লাভজনক একটি ফল।', 'https://ghbdqzdcgkafuivacxif.supabase.co/storage/v1/object/public/crop-images/covers/banana.jpg');

  INSERT INTO public.crop_lifecycle_steps (guideline_id, stage_type, step_order, title_en, title_bn, instructions_en, instructions_bn, video_youtube_id)
  VALUES (v_id, 'irrigation', 1, 'Sucker Pruning Methods', 'স্মার্ট পদ্ধতিতে কলার পরিচর্যা', 'Prune secondary tree stems to speed up fruit development.', 'কলার কাঁদি বড় করতে অতিরিক্ত চারা বা পোয়া কেটে ফেলুন।', 'v8Onw27y8k8');

  INSERT INTO public.crop_infections (guideline_id, name_en, name_bn, symptoms_en, symptoms_bn, remedy_en, remedy_bn, video_youtube_id)
  VALUES (v_id, 'Wilt Shield', 'পানামা রোগ প্রতিরোধ', 'Leaves yellow and split near the baseline leaf sheath.', 'গাছের পাতা হলুদ হয়ে বোঁটার কাছে ভেঙে ঝুলে পড়ে।', 'Apply strict soil disinfection treatments.', 'আক্রান্ত গাছ গোড়াসহ তুলে পুড়িয়ে ফেলুন ও চুন প্রয়োগ করুন।', 'v8Onw27y8k8');


  -- --------------------------------------------------------
  -- 8. PAPAYA (পেঁপে)
  -- --------------------------------------------------------
  v_id := gen_random_uuid();
  INSERT INTO public.guidelines (id, crop_name_en, crop_name_bn, category, description_en, description_bn, cover_image)
  VALUES (v_id, 'Papaya', 'পেঁপে', 'fruit', 'Dual use raw vegetable and sweet fruit.', 'সবজি ও ফল উভয় হিসেবে ব্যবহারযোগ্য দ্রুত বর্ধনশীল ফসল।', 'https://ghbdqzdcgkafuivacxif.supabase.co/storage/v1/object/public/crop-images/covers/papaya.jpg');

  INSERT INTO public.crop_lifecycle_steps (guideline_id, stage_type, step_order, title_en, title_bn, instructions_en, instructions_bn, video_youtube_id)
  VALUES (v_id, 'fertilizer', 1, 'Nutrient Tracking Management', 'পেঁপে গাছে প্রচুর ফলন আনার কৌশল', 'Apply systematic micro-nutrients to secure female flowering trees.', 'স্ত্রী ফুল নিশ্চিত করতে ও হরমোন প্রয়োগে দ্রুত ফলন আনুন।', '3u6p1tA_Z7g');

  INSERT INTO public.crop_infections (guideline_id, name_en, name_bn, symptoms_en, symptoms_bn, remedy_en, remedy_bn, video_youtube_id)
  VALUES (v_id, 'Damping Off Cure', 'গোড়া পচা রোগ চিকিৎসা', 'Waterlogged base causes complete stalk wilting.', 'অতিরিক্ত পানিতে কাণ্ড নরম হয়ে গাছ ধসে পড়ে।', 'Improve soil layout parameters instantly.', 'পানি নিষ্কাশন ঠিক করুন এবং কপার নাশক গোড়ায় স্প্রে করুন।', '3u6p1tA_Z7g');


  -- --------------------------------------------------------
  -- 9. GINGER (আদা)
  -- --------------------------------------------------------
  v_id := gen_random_uuid();
  INSERT INTO public.guidelines (id, crop_name_en, crop_name_bn, category, description_en, description_bn, cover_image)
  VALUES (v_id, 'Ginger', 'আদা', 'spice', 'Shade-loving sub-surface premium spice.', 'ছায়াযুক্ত স্থানে চাষযোগ্য অতি মূল্যবান মসলা ফসল।', 'https://ghbdqzdcgkafuivacxif.supabase.co/storage/v1/object/public/crop-images/covers/ginger.jpg');

  INSERT INTO public.crop_lifecycle_steps (guideline_id, stage_type, step_order, title_en, title_bn, instructions_en, instructions_bn, video_youtube_id)
  VALUES (v_id, 'sowing', 1, 'Rhizome Development Guide', 'লাভজনক উপায়ে আদা চাষ পদ্ধতি', 'Maintain line-spacing metrics cleanly in porous loamy soil.', 'বেলে দোআঁশ মাটিতে সঠিক দূরত্বে আদার কন্দ রোপণ করুন।', '17Gv2lJ78kY');

  INSERT INTO public.crop_infections (guideline_id, name_en, name_bn, symptoms_en, symptoms_bn, remedy_en, remedy_bn, video_youtube_id)
  VALUES (v_id, 'Root Rot Protection', 'কন্দ পচা রোগ সমাধান', 'Underground roots turn soft and smell bad.', 'মাটির নিচের কন্দ পচে গাছ শুকিয়ে মারা যায়।', 'Apply systematic Trichoderma additives to the soil.', 'বীজ রোপণের আগে ট্রাইকোডার্মা দিয়ে মাটি শোধন করুন।', '17Gv2lJ78kY');


  -- --------------------------------------------------------
  -- 10. WHEAT (গম)
  -- --------------------------------------------------------
  v_id := gen_random_uuid();
  INSERT INTO public.guidelines (id, crop_name_en, crop_name_bn, category, description_en, description_bn, cover_image)
  VALUES (v_id, 'Wheat', 'গম', 'grain', 'Major strategic secondary cereal grain.', 'বাংলাদেশের দ্বিতীয় প্রধান দানাদার শীতকালীন খাদ্যশস্য।', 'https://ghbdqzdcgkafuivacxif.supabase.co/storage/v1/object/public/crop-images/covers/wheat.jpg');

  INSERT INTO public.crop_lifecycle_steps (guideline_id, stage_type, step_order, title_en, title_bn, instructions_en, instructions_bn, video_youtube_id)
  VALUES (v_id, 'sowing', 1, 'Cereal Row Management', 'উন্নত জাতের গম চাষ পদ্ধতি', 'Use zero-tillage or fully optimized standard dry rows.', 'বারি গম ৩৩ এর মত উন্নত ও ব্লাস্ট প্রতিরোধী জাত ব্যবহার করুন।', 'KxiVb3X_eQw');

  INSERT INTO public.crop_infections (guideline_id, name_en, name_bn, symptoms_en, symptoms_bn, remedy_en, remedy_bn, video_youtube_id)
  VALUES (v_id, 'Blast Suppression', 'গমের ব্লাস্ট রোগ দমন', 'Spikes turn white and dry out completely.', 'গমের শীষের অগ্রভাগ শুকিয়ে সাদা হয়ে মরে যাওয়া।', 'Spray Nativo or generic Tebuconazole components.', 'লক্ষণ দেখামাত্রই টেবুকোনাজল যুক্ত ছত্রাকনাশক স্প্রে করুন।', 'KxiVb3X_eQw');


  -- --------------------------------------------------------
  -- 11. EGGPLANT / BRINJAL (বেগুন)
  -- --------------------------------------------------------
  v_id := gen_random_uuid();
  INSERT INTO public.guidelines (id, crop_name_en, crop_name_bn, category, description_en, description_bn, cover_image)
  VALUES (v_id, 'Eggplant', 'বেগুন', 'vegetable', 'Highly popular long season staple vegetable.', 'বারোমাস চাষযোগ্য অত্যন্ত জনপ্রিয় ও লাভজনক সবজি।', 'https://ghbdqzdcgkafuivacxif.supabase.co/storage/v1/object/public/crop-images/covers/eggplant.jpg');

  INSERT INTO public.crop_lifecycle_steps (guideline_id, stage_type, step_order, title_en, title_bn, instructions_en, instructions_bn, video_youtube_id)
  VALUES (v_id, 'pest_control', 1, 'Borer Insect Trapping', 'বেগুনের ডগা ও ফল ছিদ্রকারী পোকা দমন', 'Use pheromone traps combined with systematic netting.', 'ফেরইমন ফাঁদ ব্যবহার করে ডগা ছিদ্রকারী পোকা প্রতিরোধ করুন।', 'tL9i8Z7L-8s');

  INSERT INTO public.crop_infections (guideline_id, name_en, name_bn, symptoms_en, symptoms_bn, remedy_en, remedy_bn, video_youtube_id)
  VALUES (v_id, 'Wilt Interception', 'লেদা বা ঢলে পড়া রোগ সমাধান', 'Sudmen complete collapse without initial yellowing.', 'সবুজ অবস্থাতেই গাছের ডালপালা হঠাৎ ঝিমিয়ে শুকিয়ে যাওয়া।', 'Apply structural bleaching powder into base roots.', 'মাটি শোধন করুন এবং গোড়ায় ব্লিচিং পাউডার মিশ্রিত পানি দিন।', 'tL9i8Z7L-8s');


  -- --------------------------------------------------------
  -- 12. CHILI (মরিচ)
  -- --------------------------------------------------------
  v_id := gen_random_uuid();
  INSERT INTO public.guidelines (id, crop_name_en, crop_name_bn, category, description_en, description_bn, cover_image)
  VALUES (v_id, 'Chili', 'মরিচ', 'spice', 'High value hot spice and direct commercial crop.', 'কাঁচা ও শুকনো উভয় বাজারের জন্য প্রয়োজনীয় মসলা ফসল।', 'https://ghbdqzdcgkafuivacxif.supabase.co/storage/v1/object/public/crop-images/covers/chili.jpg');

  INSERT INTO public.crop_lifecycle_steps (guideline_id, stage_type, step_order, title_en, title_bn, instructions_en, instructions_bn, video_youtube_id)
  VALUES (v_id, 'sowing', 1, 'Raised Bed Setup', 'মরিচের আধুনিক উচ্চ ফলনশীল চাষ পদ্ধতি', 'Elevate field beds to prevent continuous damp soil loops.', 'পানি নিষ্কাশনের জন্য উঁচু বেড তৈরি করে চারা রোপণ করুন।', '17Gv2lJ78kY');

  INSERT INTO public.crop_infections (guideline_id, name_en, name_bn, symptoms_en, symptoms_bn, remedy_en, remedy_bn, video_youtube_id)
  VALUES (v_id, 'Virus Interception', 'পাতা কোঁকড়ানো রোগ চিকিৎসা', 'Leaves wrinkle and stunt tree growth frameworks.', 'মরিচ গাছের পাতা কুঁকড়ে ছোট হয়ে যাওয়া ও বৃদ্ধি থমকে যাওয়া।', 'Eliminate sucking whitefly vectors using dimethoate.', 'সاده মাছি দমনে ডাইমিথোয়েট জাতীয় কীটনাশক স্প্রে করুন।', '17Gv2lJ78kY');


  -- --------------------------------------------------------
  -- 13. MUSTARD (সরিষা)
  -- --------------------------------------------------------
  v_id := gen_random_uuid();
  INSERT INTO public.guidelines (id, crop_name_en, crop_name_bn, category, description_en, description_bn, cover_image)
  VALUES (v_id, 'Mustard', 'সরিষা', 'oilseed', 'Primary national domestic edible oil source.', 'বাংলাদেশের প্রধান ভোজ্যতেল উৎপাদনকারী তৈলবীজ ফসল।', 'https://ghbdqzdcgkafuivacxif.supabase.co/storage/v1/object/public/crop-images/covers/mustard.jpg');

  INSERT INTO public.crop_lifecycle_steps (guideline_id, stage_type, step_order, title_en, title_bn, instructions_en, instructions_bn, video_youtube_id)
  VALUES (v_id, 'fertilizer', 1, 'Oil Density Optimization', 'সরিষার জমিতে সার ও তেল বৃদ্ধি ব্যবস্থাপনা', 'Apply Boron and Sulphur heavily during initialization steps.', 'তৈলাক্ততা বাড়াতে জমিতে জিপসাম ও বোরন সার নিশ্চিত করুন।', 'KxiVb3X_eQw');

  INSERT INTO public.crop_infections (guideline_id, name_en, name_bn, symptoms_en, symptoms_bn, remedy_en, remedy_bn, video_youtube_id)
  VALUES (v_id, 'Blight Block', 'পাতা ঝলসানো রোগ দমন', 'Concentric dark brown circular spots scale on leaves.', 'পাতার গায়ে গাঢ় বাদামী রঙের বৃত্তাকার দাগ পড়া।', 'Apply Mancozeb spray structures on timely lines.', 'লক্ষণ দেখামাত্রই রভরাল বা ম্যানকোজেব স্প্রে সম্পন্ন করুন।', 'KxiVb3X_eQw');


  -- --------------------------------------------------------
  -- 14. MUNG BEAN (মুগ ডাল)
  -- --------------------------------------------------------
  v_id := gen_random_uuid();
  INSERT INTO public.guidelines (id, crop_name_en, crop_name_bn, category, description_en, description_bn, cover_image)
  VALUES (v_id, 'Mung Bean', 'মুগ ডাল', 'pulse', 'Premium short-duration high protein pulse.', 'স্বল্পমেয়াদী ও অত্যন্ত পুষ্টিকর একটি প্রধান ডাল জাতীয় ফসল।', 'https://ghbdqzdcgkafuivacxif.supabase.co/storage/v1/object/public/crop-images/covers/mungbean.jpg');

  INSERT INTO public.crop_lifecycle_steps (guideline_id, stage_type, step_order, title_en, title_bn, instructions_en, instructions_bn, video_youtube_id)
  VALUES (v_id, 'harvesting', 1, 'Legume Harvesting Loops', 'মুগ ডাল সংগ্রহ ও মাড়াই পদ্ধতি', 'Harvest pods in steps when 80% turn dark black.', 'ডাল কালো রঙ ধারণ করলে ২-৩ বারে পাকা পড সংগ্রহ করুন।', 'KxiVb3X_eQw');

  INSERT INTO public.crop_infections (guideline_id, name_en, name_bn, symptoms_en, symptoms_bn, remedy_en, remedy_bn, video_youtube_id)
  VALUES (v_id, 'Mosaic Eradication', 'হলুদ মোজাইক রোগ সমাধান', 'Bright yellow patches blanket structural leaves.', 'পাতার উপর উজ্জ্বল হলুদ রঙের ছোপ ছোপ দাগ দেখা দেওয়া।', 'Uproot infected models and treat for whitefly vectors.', 'আক্রান্ত গাছ তুলে ফেলুন ও বাহক পোকা দমনে কীটনাশক দিন।', 'KxiVb3X_eQw');


  -- --------------------------------------------------------
  -- 15. CUCUMBER (শসা)
  -- --------------------------------------------------------
  v_id := gen_random_uuid();
  INSERT INTO public.guidelines (id, crop_name_en, crop_name_bn, category, description_en, description_bn, cover_image)
  VALUES (v_id, 'Cucumber', 'শসা', 'vegetable', 'High income short duration salad vegetable.', 'অল্প সময়ে হিউজ ফলন ও সালাদের জন্য জনপ্রিয় একটি ফসল।', 'https://ghbdqzdcgkafuivacxif.supabase.co/storage/v1/object/public/crop-images/covers/cucumber.jpg');

  INSERT INTO public.crop_lifecycle_steps (guideline_id, stage_type, step_order, title_en, title_bn, instructions_en, instructions_bn, video_youtube_id)
  VALUES (v_id, 'sowing', 1, 'Vertical Trellis Frameworks', 'মাচা পদ্ধতিতে শসা চাষের এ টু জেড', 'Construct clear bamboo structures to protect expanding vines.', 'বাঁশের মাচা তৈরি করে লতা উঁচুতে আরোহণের ব্যবস্থা করুন।', 'XbMv7D66H2M');

  INSERT INTO public.crop_infections (guideline_id, name_en, name_bn, symptoms_en, symptoms_bn, remedy_en, remedy_bn, video_youtube_id)
  VALUES (v_id, 'Mildew Remediation', 'পাউডারি মিলডিউ রোগ দমন', 'White flour-like dust surfaces on leaf faces.', 'পাতার উপরিভাগে সাদা পাউডারের মত আস্তরণ পড়া।', 'Spray Sulphur-based dynamic fungicides smoothly.', 'সালফার জাতীয় ছত্রাকনাশক ৫-৭ দিন অন্তর স্প্রে করুন।', 'XbMv7D66H2M');


  -- --------------------------------------------------------
  -- 16. BOTTLE GOURD (লাউ)
  -- --------------------------------------------------------
  v_id := gen_random_uuid();
  INSERT INTO public.guidelines (id, crop_name_en, crop_name_bn, category, description_en, description_bn, cover_image)
  VALUES (v_id, 'Bottle Gourd', 'লাউ', 'vegetable', 'Highly profitable traditional running vine.', 'শীত ও গ্রীষ্ম উভয় মৌসুমে চাষযোগ্য অত্যন্ত জনপ্রিয় সবজি।', 'https://ghbdqzdcgkafuivacxif.supabase.co/storage/v1/object/public/crop-images/covers/gourd.jpg');

  INSERT INTO public.crop_lifecycle_steps (guideline_id, stage_type, step_order, title_en, title_bn, instructions_en, instructions_bn, video_youtube_id)
  VALUES (v_id, 'fertilizer', 1, 'Pit Fertilizer Compounding', 'লাউয়ের মাদা তৈরি ও সার ব্যবস্থাপনা', 'Blend vermicompost deeply inside wide growing soil pits.', 'বড় মাদা তৈরি করে পচা গোবর ও টিএসপি সার ভালোভাবে মেশান।', '3u6p1tA_Z7g');

  INSERT INTO public.crop_infections (guideline_id, name_en, name_bn, symptoms_en, symptoms_bn, remedy_en, remedy_bn, video_youtube_id)
  VALUES (v_id, 'Foliage Protection', 'ডাউনি মিলডিউ প্রতিরোধ', 'Angular yellow lesions mark the inner leaf fields.', 'পাতার নিচে ধূসর বা বেগুনী রঙের ছাতা ধরা দাগের সৃষ্টি।', 'Deploy Mancozeb tracking compounds without delays.', 'ম্যানকোজেব বা মেটালাক্সিল উপাদান নিয়মিত স্প্রে করুন।', '3u6p1tA_Z7g');


  -- --------------------------------------------------------
  -- 17. GARLIC (রসুন)
  -- --------------------------------------------------------
  v_id := gen_random_uuid();
  INSERT INTO public.guidelines (id, crop_name_en, crop_name_bn, category, description_en, description_bn, cover_image)
  VALUES (v_id, 'Garlic', 'রসুন', 'spice', 'Essential zero-tillage responsive winter spice.', 'বিনা চাষে বা সাধারণ কন্দ রোপণে লাভজনক মসলা ফসল।', 'https://ghbdqzdcgkafuivacxif.supabase.co/storage/v1/object/public/crop-images/covers/garlic.jpg');

  INSERT INTO public.crop_lifecycle_steps (guideline_id, stage_type, step_order, title_en, title_bn, instructions_en, instructions_bn, video_youtube_id)
  VALUES (v_id, 'sowing', 1, 'Zero-Till Spacing Layouts', 'বিনা চাষে রসুন রোপণের সঠিক নিয়ম', 'Plant single cloves explicitly directly into wet rice straw layers.', 'ধান কাটার পর কাদা মাটিতে সরাসরি কোয়া রোপণ করুন।', '17Gv2lJ78kY');

  INSERT INTO public.crop_infections (guideline_id, name_en, name_bn, symptoms_en, symptoms_bn, remedy_en, remedy_bn, video_youtube_id)
  VALUES (v_id, 'Blight Shielding', 'ঝলসানো রোগ চিকিৎসা', 'Leaf tips tip over, turning dry and pale yellow.', 'রসুনের পাতার ডগা পুড়ে যাওয়ার মত বিবর্ণ হয়ে যাওয়া।', 'Apply clean Propiconazole based fungal barriers.', 'প্রোপিকোনাজল যুক্ত উপাদানের মাধ্যমে ছত্রাক দমন নিশ্চিত করুন।', '17Gv2lJ78kY');


  -- --------------------------------------------------------
  -- 18. MAIZE / CORN (ভুট্টা)
  -- --------------------------------------------------------
  v_id := gen_random_uuid();
  INSERT INTO public.guidelines (id, crop_name_en, crop_name_bn, category, description_en, description_bn, cover_image)
  VALUES (v_id, 'Maize Corn', 'ভুট্টা', 'grain', 'High industrial value poultry feed grain source.', 'হাঁস-মুরগির খাদ্য ও শিল্পের জন্য উচ্চ চাহিদাসম্পন্ন শস্য।', 'https://ghbdqzdcgkafuivacxif.supabase.co/storage/v1/object/public/crop-images/covers/maize.jpg');

  INSERT INTO public.crop_lifecycle_steps (guideline_id, stage_type, step_order, title_en, title_bn, instructions_en, instructions_bn, video_youtube_id)
  VALUES (v_id, 'irrigation', 1, 'Knee-High Water Tracking', 'ভুট্টার সেচ ও ফলন বৃদ্ধির নিয়ম', 'Apply water systematically during knee-high and silking phases.', 'হাঁটু সমপরিমাণ উচ্চতা ও মোচা আসার সময় অবশ্যই সেচ দিন।', 'KxiVb3X_eQw');

  INSERT INTO public.crop_infections (guideline_id, name_en, name_bn, symptoms_en, symptoms_bn, remedy_en, remedy_bn, video_youtube_id)
  VALUES (v_id, 'Worm Eradication', 'ফল আর্মিওয়ার্ম পোকা দমন', 'Caterpillars bore holes through expanding central leaf whorls.', 'শুঁয়োপোকা ভুট্টার কচি পাতা ও মোচা কুঁড়ে কুঁড়ে খেয়ে ফেলে।', 'Spray Emamectin Benzoate components instantly.', 'সন্ধ্যায় এমামেকটিন বেনজোয়েট গ্রুপের কীটনাশক স্প্রে করুন।', 'KxiVb3X_eQw');


  -- --------------------------------------------------------
  -- 19. LYCHEE (লিচু)
  -- --------------------------------------------------------
  v_id := gen_random_uuid();
  INSERT INTO public.guidelines (id, crop_name_en, crop_name_bn, category, description_en, description_bn, cover_image)
  VALUES (v_id, 'Lychee', 'লিচু', 'fruit', 'High value seasonal juicy cluster fruit.', 'গ্রীষ্মকালের অত্যন্ত সুস্বাদু ও লাভজনক একটি রসালো ফল।', 'https://ghbdqzdcgkafuivacxif.supabase.co/storage/v1/object/public/crop-images/covers/lychee.jpg');

  INSERT INTO public.crop_lifecycle_steps (guideline_id, stage_type, step_order, title_en, title_bn, instructions_en, instructions_bn, video_youtube_id)
  VALUES (v_id, 'pest_control', 1, 'Post-Flowering Orchard Sprays', 'লিচুর গুটি টিকানো ও পোকা দমন', 'Spray trees post-flowering to halt boring pests.', 'ফুল ঝরে গুটি বাঁধার পর ফল ছিদ্রকারী পোকা দমনে স্প্রে করুন।', 'P_O4G9FhPGo');

  INSERT INTO public.crop_infections (guideline_id, name_en, name_bn, symptoms_en, symptoms_bn, remedy_en, remedy_bn, video_youtube_id)
  VALUES (v_id, 'Mite Suppression', 'লিচুর মাকড় রোগ সমাধান', 'Leaves develop velvet brown coatings beneath.', 'পাতার উল্টো পিঠে খয়েরী মখমলের মত আস্তরণ পড়ে কুঁকড়ে যাওয়া।', 'Apply Sulphur miticides cleanly across branches.', 'সালফার জাতীয় মাকড়নাশক আক্রান্ত গাছে স্প্রে করুন।', 'P_O4G9FhPGo');


  -- --------------------------------------------------------
  -- 20. BLACK GRAM (মাসকলাই)
  -- --------------------------------------------------------
  v_id := gen_random_uuid();
  INSERT INTO public.guidelines (id, crop_name_en, crop_name_bn, category, description_en, description_bn, cover_image)
  VALUES (v_id, 'Black Gram', 'মাসকলাই', 'pulse', 'Hardy relay-cropping seasonal pulse asset.', 'চরাঞ্চল ও সাধারণ জমিতে খড় বা আমন কাটার পর প্রধান ডাল।', 'https://ghbdqzdcgkafuivacxif.supabase.co/storage/v1/object/public/crop-images/covers/blackgram.jpg');

  INSERT INTO public.crop_lifecycle_steps (guideline_id, stage_type, step_order, title_en, title_bn, instructions_en, instructions_bn, video_youtube_id)
  VALUES (v_id, 'sowing', 1, 'Moisture Broadcast Operations', 'সহজ পদ্ধতিতে মাসকলাই চাষ ও ফসল তোলা', 'Broadcast seeds directly into standing late Aman crop fields.', 'আমন ধান কাটার আগে অবশিষ্ট আর্দ্রতায় বীজ ছিটকিয়ে দিন।', '4a96p_fK_U4');

  INSERT INTO public.crop_infections (guideline_id, name_en, name_bn, symptoms_en, symptoms_bn, remedy_en, remedy_bn, video_youtube_id)
  VALUES (v_id, 'Mildew Interception', 'সাদা গুঁড়ো রোগ দমন', 'Ashen gray coatings dust expanding foliage faces.', 'পাতা ও ডালে সাদা পাউডারের মত ছত্রাক ছড়িয়ে পড়া।', 'Spray systematic dynamic Carbendazim solutions.', 'কার্বেনডাজিম গ্রুপের ছত্রাকনাশক সঠিক মাত্রায় ব্যবহার করুন।', '4a96p_fK_U4');

END $$;