cat > /mnt/user-data/outputs/test_data.sql << 'ENDSQL'
-- ============================================================
-- KRISHOK APP — TEST / SEED DATA
-- Run this in the Supabase SQL editor after migrations.sql
-- and policies.sql have been applied.
--
-- Seed seller UUID (test@test.com, role: farmer):
-- dad12c10-b0d0-49a1-bfa2-17e3496d3346
-- ============================================================

-- ============================================================
-- PRODUCTS (30 total)
-- Categories: crop, fertilizer, insecticide, other
-- Divisions: Rajshahi, Rangpur, Mymensingh, Sylhet, Dhaka
-- No tools — kept in schema but unused here.
-- Images: placeholders — replace after uploading to Supabase Storage.
-- ============================================================

INSERT INTO products (seller_id, title, description, category, price, unit, stock, images, division, is_active) VALUES

-- CROPS (12)
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'ব্রি ধান-২৯ (BRRI Dhan-29)',
  'উচ্চ ফলনশীল বোরো মৌসুমের ধান। প্রতি বিঘায় গড় ফলন ২০-২২ মণ। সেচ নির্ভর চাষের জন্য উপযুক্ত।',
  'crop', 1200.00, 'কেজি', 500,
  ARRAY['https://placehold.co/600x400?text=BRRI+Dhan-29'],
  'Rajshahi', TRUE
),
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'ব্রি ধান-৪৯ (BRRI Dhan-49)',
  'আমন মৌসুমের জনপ্রিয় উফশী জাত। খরা সহনশীল এবং কম সেচে ভালো ফলন দেয়।',
  'crop', 1100.00, 'কেজি', 350,
  ARRAY['https://placehold.co/600x400?text=BRRI+Dhan-49'],
  'Mymensingh', TRUE
),
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'তোষা পাট বীজ (Tossa Jute Seed)',
  'O-9897 জাতের তোষা পাট বীজ। উচ্চমানের আঁশ উৎপাদনের জন্য পরিচিত। রাজশাহী ও রংপুর অঞ্চলে বহুল চাষ হয়।',
  'crop', 850.00, 'কেজি', 200,
  ARRAY['https://placehold.co/600x400?text=Tossa+Jute'],
  'Rangpur', TRUE
),
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'দেশি আলু বীজ — ডায়মন্ড (Diamond Potato Seed)',
  'শীতকালীন আলু চাষের জন্য সার্টিফাইড ডায়মন্ড জাত। ভালো গুদামজাত ক্ষমতা সম্পন্ন।',
  'crop', 2200.00, 'কেজি', 300,
  ARRAY['https://placehold.co/600x400?text=Diamond+Potato'],
  'Rangpur', TRUE
),
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'হাইব্রিড টমেটো বীজ — রাজা (Raja Hybrid Tomato)',
  'গ্রীষ্মকালীন ও শীতকালীন উভয় মৌসুমে চাষযোগ্য। রোগ প্রতিরোধী এবং বাজারে চাহিদা বেশি।',
  'crop', 450.00, 'গ্রাম', 150,
  ARRAY['https://placehold.co/600x400?text=Raja+Tomato'],
  'Dhaka', TRUE
),
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'সরিষা বীজ — বারি সরিষা-১৪',
  'স্বল্প মেয়াদী রবি ফসল। তেলের পরিমাণ বেশি, ৭৫-৮০ দিনে পরিপক্ব হয়।',
  'crop', 320.00, 'কেজি', 400,
  ARRAY['https://placehold.co/600x400?text=Bari+Mustard-14'],
  'Rajshahi', TRUE
),
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'পেঁয়াজ বীজ — তাহেরপুরি (Taherpuri Onion)',
  'বাংলাদেশের সবচেয়ে জনপ্রিয় দেশি পেঁয়াজ জাত। ঝাঁঝালো গন্ধ ও দীর্ঘস্থায়িত্বের জন্য বিখ্যাত।',
  'crop', 680.00, 'কেজি', 180,
  ARRAY['https://placehold.co/600x400?text=Taherpuri+Onion'],
  'Rajshahi', TRUE
),
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'মসুর ডাল বীজ — বারি মসুর-৭',
  'রবি মৌসুমের ডাল ফসল। খরা সহিষ্ণু এবং উচ্চ প্রোটিনসমৃদ্ধ জাত।',
  'crop', 520.00, 'কেজি', 250,
  ARRAY['https://placehold.co/600x400?text=Bari+Lentil-7'],
  'Mymensingh', TRUE
),
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'গম বীজ — বারি গম-৩৩',
  'উচ্চ ফলনশীল রবি মৌসুমের গম। তাপ সহিষ্ণু জাত, দেরিতে বপনের জন্য উপযুক্ত।',
  'crop', 480.00, 'কেজি', 600,
  ARRAY['https://placehold.co/600x400?text=Bari+Wheat-33'],
  'Rangpur', TRUE
),
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'মরিচ বীজ — হাইব্রিড বাংলা কিং',
  'ঝাল বেশি, ফলন বেশি। সারা বছর চাষযোগ্য হাইব্রিড মরিচ বীজ।',
  'crop', 380.00, 'গ্রাম', 120,
  ARRAY['https://placehold.co/600x400?text=Bangla+King+Chili'],
  'Sylhet', TRUE
),
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'রসুন বীজ — দেশি রসুন (Local Garlic)',
  'বাংলাদেশি দেশি জাতের রসুন বীজ কোয়া। তীব্র সুগন্ধ ও ঔষধি গুণসম্পন্ন।',
  'crop', 900.00, 'কেজি', 100,
  ARRAY['https://placehold.co/600x400?text=Local+Garlic'],
  'Mymensingh', TRUE
),
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'হাইব্রিড বেগুন বীজ — উত্তরা',
  'দ্রুত বর্ধনশীল, রোগ প্রতিরোধী বেগুনের জাত। সারা বছর চাষ করা যায়।',
  'crop', 290.00, 'গ্রাম', 200,
  ARRAY['https://placehold.co/600x400?text=Uttara+Brinjal'],
  'Dhaka', TRUE
),

-- FERTILIZERS (10)
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'ইউরিয়া সার (Urea Fertilizer)',
  'নাইট্রোজেনসমৃদ্ধ সার। ধান, গম, ভুট্টাসহ সব ধরনের ফসলে ব্যবহারযোগ্য। ৪৬% নাইট্রোজেন।',
  'fertilizer', 28.00, 'কেজি', 2000,
  ARRAY['https://placehold.co/600x400?text=Urea+Fertilizer'],
  'Dhaka', TRUE
),
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'ডিএপি সার (DAP Fertilizer)',
  'ডাই-অ্যামোনিয়াম ফসফেট। ফসলের শিকড় বৃদ্ধি ও ফুল-ফল ধারণে কার্যকর। ১৮% নাইট্রোজেন ও ৪৬% ফসফরাস।',
  'fertilizer', 75.00, 'কেজি', 1500,
  ARRAY['https://placehold.co/600x400?text=DAP+Fertilizer'],
  'Rajshahi', TRUE
),
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'টিএসপি সার (TSP Fertilizer)',
  'ট্রিপল সুপার ফসফেট। ফসফরাসের ভালো উৎস। ডালজাতীয় ফসল ও সবজিতে বিশেষ কার্যকর।',
  'fertilizer', 65.00, 'কেজি', 1200,
  ARRAY['https://placehold.co/600x400?text=TSP+Fertilizer'],
  'Mymensingh', TRUE
),
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'এমওপি সার (MOP / Potash)',
  'মিউরেট অব পটাশ। ফসলের রোগ প্রতিরোধ ক্ষমতা বাড়ায় ও ফলের মান উন্নত করে।',
  'fertilizer', 55.00, 'কেজি', 1000,
  ARRAY['https://placehold.co/600x400?text=MOP+Potash'],
  'Rangpur', TRUE
),
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'জিপসাম সার (Gypsum Fertilizer)',
  'ক্যালসিয়াম ও সালফারের উৎস। চিনাবাদাম, সরিষা ও সবজি চাষে বিশেষ উপকারী।',
  'fertilizer', 22.00, 'কেজি', 800,
  ARRAY['https://placehold.co/600x400?text=Gypsum+Fertilizer'],
  'Rajshahi', TRUE
),
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'জৈব সার — ভার্মিকম্পোস্ট (Vermicompost)',
  'কেঁচো সার। মাটির জৈব পদার্থ বৃদ্ধি করে, পানি ধারণ ক্ষমতা বাড়ায়। সব ফসলে নিরাপদ।',
  'fertilizer', 18.00, 'কেজি', 3000,
  ARRAY['https://placehold.co/600x400?text=Vermicompost'],
  'Mymensingh', TRUE
),
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'বোরন সার (Boron Fertilizer)',
  'অণু সার। ফুল ঝরা ও ফল ফেটে যাওয়া রোধ করে। সবজি ও ফল বাগানে অপরিহার্য।',
  'fertilizer', 180.00, 'কেজি', 500,
  ARRAY['https://placehold.co/600x400?text=Boron+Fertilizer'],
  'Sylhet', TRUE
),
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'জিংক সালফেট (Zinc Sulphate)',
  'দস্তা সার। ধানের খাটো রোগ (Khaira) প্রতিরোধে কার্যকর। মাটির জিংকের ঘাটতি পূরণ করে।',
  'fertilizer', 95.00, 'কেজি', 700,
  ARRAY['https://placehold.co/600x400?text=Zinc+Sulphate'],
  'Rangpur', TRUE
),
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'কম্পোস্ট সার — গোবর সার (Cow Dung Compost)',
  'প্রাকৃতিক জৈব সার। মাটির গঠন উন্নত করে এবং দীর্ঘমেয়াদী পুষ্টি সরবরাহ করে।',
  'fertilizer', 8.00, 'কেজি', 5000,
  ARRAY['https://placehold.co/600x400?text=Cow+Dung+Compost'],
  'Dhaka', TRUE
),
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'এনপিকে সার ১৫-১৫-১৫ (NPK Compound)',
  'সম অনুপাতে নাইট্রোজেন, ফসফরাস ও পটাশ। সব ধরনের ফসলে সুষম পুষ্টি নিশ্চিত করে।',
  'fertilizer', 88.00, 'কেজি', 900,
  ARRAY['https://placehold.co/600x400?text=NPK+15-15-15'],
  'Mymensingh', TRUE
),

-- INSECTICIDES (5)
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'রিপকর্ড ১০ ইসি (Ripcord 10 EC)',
  'সাইপারমেথ্রিন গ্রুপের কীটনাশক। ধানের মাজরা পোকা, পামরি পোকা দমনে কার্যকর।',
  'insecticide', 320.00, 'লিটার', 200,
  ARRAY['https://placehold.co/600x400?text=Ripcord+10EC'],
  'Rajshahi', TRUE
),
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'ডার্সবান ২০ ইসি (Dursban 20 EC)',
  'ক্লোরপাইরিফস গ্রুপের কীটনাশক। মাটি ও পাতার পোকামাকড় দমনে ব্যাপকভাবে ব্যবহৃত।',
  'insecticide', 280.00, 'লিটার', 150,
  ARRAY['https://placehold.co/600x400?text=Dursban+20EC'],
  'Rangpur', TRUE
),
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'ব্লাস্টিসিডিন (Blasticidin Fungicide)',
  'ধানের ব্লাস্ট রোগ দমনের জন্য কার্যকর ছত্রাকনাশক। রোগ দেখা দেওয়ার সাথে সাথে প্রয়োগ করুন।',
  'insecticide', 420.00, 'লিটার', 120,
  ARRAY['https://placehold.co/600x400?text=Blasticidin'],
  'Mymensingh', TRUE
),
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'ভার্টিমেক ১.৮ ইসি (Vertimec 1.8 EC)',
  'অ্যাবামেকটিন গ্রুপের কীটনাশক। মাকড় ও থ্রিপস দমনে অত্যন্ত কার্যকর।',
  'insecticide', 550.00, '১০০ মিলি', 100,
  ARRAY['https://placehold.co/600x400?text=Vertimec+1.8EC'],
  'Sylhet', TRUE
),
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'বায়োনিম প্লাস (Bionim Plus — Neem Extract)',
  'নিম নির্যাস থেকে তৈরি জৈব কীটনাশক। পরিবেশবান্ধব, মানব স্বাস্থ্যের জন্য নিরাপদ।',
  'insecticide', 190.00, '৫০০ মিলি', 300,
  ARRAY['https://placehold.co/600x400?text=Bionim+Plus'],
  'Dhaka', TRUE
),

-- OTHER (3) — seedlings, saplings, organic inputs
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'আম চারা — আম্রপালি (Amrapali Mango Sapling)',
  'কলম করা আম্রপালি আমের চারা। দ্রুত ফলদানকারী, ৩-৪ বছরেই ফল দেয়। উচ্চতা ১-১.৫ ফুট।',
  'other', 250.00, 'পিস', 80,
  ARRAY['https://placehold.co/600x400?text=Amrapali+Mango'],
  'Rajshahi', TRUE
),
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'পেঁপে চারা — শাহী পেঁপে (Shahi Papaya Seedling)',
  'হাইব্রিড শাহী পেঁপের চারা। মাত্র ৬-৭ মাসে ফল ধরে। বাড়ির আঙিনা ও বাণিজ্যিক চাষের জন্য উপযুক্ত।',
  'other', 60.00, 'পিস', 200,
  ARRAY['https://placehold.co/600x400?text=Shahi+Papaya'],
  'Dhaka', TRUE
),
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'নারকেল চারা — উফশী নারকেল (Hybrid Coconut Sapling)',
  'বামন জাতের নারকেল চারা। ৩-৪ বছরে ফল দেয়, সাধারণ নারকেলের চেয়ে দ্রুত। উচ্চতা কম থাকায় সংগ্রহ সহজ।',
  'other', 180.00, 'পিস', 60,
  ARRAY['https://placehold.co/600x400?text=Hybrid+Coconut'],
  'Sylhet', TRUE
);


-- ============================================================
-- DOCTORS (8)
-- Agricultural extension officers and veterinary doctors
-- spread across agricultural divisions.
-- ============================================================

INSERT INTO doctors (name, phone, email, specialization, district, division, available_days, available_hours) VALUES
(
  'ড. মোহাম্মদ আবদুল করিম',
  '01711-234567',
  'dr.karim@dae.gov.bd',
  'ফসল রোগ ও কীটতত্ত্ব',
  'Rajshahi', 'Rajshahi',
  ARRAY['শনিবার', 'রবিবার', 'সোমবার', 'মঙ্গলবার'],
  'সকাল ৯টা — বিকাল ৪টা'
),
(
  'ড. ফারহানা বেগম',
  '01812-345678',
  'dr.farhana@dae.gov.bd',
  'মাটি বিজ্ঞান ও সার ব্যবস্থাপনা',
  'Bogura', 'Rajshahi',
  ARRAY['রবিবার', 'সোমবার', 'বুধবার', 'বৃহস্পতিবার'],
  'সকাল ১০টা — বিকাল ৫টা'
),
(
  'ড. মোঃ রফিকুল ইসলাম',
  '01911-456789',
  'dr.rafiqul@dae.gov.bd',
  'ধান গবেষণা ও উৎপাদন প্রযুক্তি',
  'Mymensingh', 'Mymensingh',
  ARRAY['শনিবার', 'মঙ্গলবার', 'বুধবার', 'বৃহস্পতিবার'],
  'সকাল ৮টা — বিকাল ৩টা'
),
(
  'ড. সালমা আক্তার',
  '01611-567890',
  'dr.salma@dae.gov.bd',
  'উদ্যানতত্ত্ব ও সবজি চাষ',
  'Gazipur', 'Dhaka',
  ARRAY['রবিবার', 'সোমবার', 'মঙ্গলবার', 'বৃহস্পতিবার'],
  'সকাল ৯টা — বিকাল ৪টা'
),
(
  'ড. মোহাম্মদ হাসান',
  '01511-678901',
  'dr.hasan@dae.gov.bd',
  'পাট ও আঁশ ফসল বিশেষজ্ঞ',
  'Rangpur', 'Rangpur',
  ARRAY['শনিবার', 'রবিবার', 'সোমবার', 'বুধবার'],
  'সকাল ৯টা — বিকাল ৫টা'
),
(
  'ড. নাসরিন সুলতানা',
  '01711-789012',
  'dr.nasrin@dae.gov.bd',
  'কৃষি প্রকৌশল ও সেচ ব্যবস্থাপনা',
  'Dinajpur', 'Rangpur',
  ARRAY['রবিবার', 'মঙ্গলবার', 'বুধবার', 'বৃহস্পতিবার'],
  'সকাল ১০টা — বিকাল ৪টা'
),
(
  'ড. কামরুল হাসান',
  '01811-890123',
  'dr.kamrul@dae.gov.bd',
  'চা ও মসলা ফসল বিশেষজ্ঞ',
  'Moulvibazar', 'Sylhet',
  ARRAY['শনিবার', 'সোমবার', 'মঙ্গলবার', 'বৃহস্পতিবার'],
  'সকাল ৯টা — বিকাল ৩টা'
),
(
  'ড. রেহানা পারভীন',
  '01911-901234',
  'dr.rehana@dae.gov.bd',
  'উদ্ভিদ রোগতত্ত্ব ও জৈব কৃষি',
  'Netrokona', 'Mymensingh',
  ARRAY['শনিবার', 'রবিবার', 'বুধবার', 'বৃহস্পতিবার'],
  'সকাল ৯টা — বিকাল ৫টা'
),

-- ============================================================
-- LOCATIONS (nurseries and buyers)
-- ============================================================

INSERT INTO locations (name, type, lat, lng, phone, division, is_verified) VALUES
('রাজশাহী কৃষি নার্সারি', 'nursery', 24.3745, 88.6042, '01711-111001', 'Rajshahi', TRUE),
('বরেন্দ্র নার্সারি সেন্টার', 'nursery', 24.4333, 88.7167, '01812-111002', 'Rajshahi', TRUE),
('ময়মনসিংহ সরকারি নার্সারি', 'nursery', 24.7471, 90.4203, '01911-111003', 'Mymensingh', TRUE),
('সিলেট কৃষি নার্সারি', 'nursery', 24.8949, 91.8687, '01611-111004', 'Sylhet', TRUE),
('রংপুর আধুনিক নার্সারি', 'nursery', 25.7439, 89.2752, '01511-111005', 'Rangpur', TRUE),
('গাজীপুর ফুল ও ফলের নার্সারি', 'nursery', 23.9999, 90.4203, '01711-111006', 'Dhaka', TRUE),
('রাজশাহী কৃষিপণ্য ক্রেতা সমিতি', 'buyer', 24.3636, 88.6241, '01812-222001', 'Rajshahi', TRUE),
('রংপুর আলু ক্রয় কেন্দ্র', 'buyer', 25.7460, 89.2510, '01911-222002', 'Rangpur', TRUE),
('ময়মনসিংহ ধান ক্রয় কেন্দ্র', 'buyer', 24.7500, 90.4100, '01611-222003', 'Mymensingh', TRUE),
('সিলেট চা পাতা ক্রয় কেন্দ্র', 'buyer', 24.8800, 91.8800, '01511-222004', 'Sylhet', TRUE);


-- ============================================================
-- CROP CALENDAR (10 crops)
-- sow_months and harvest_months use integer arrays (1=Jan … 12=Dec)
-- ============================================================

INSERT INTO crop_calendar (crop_name_en, crop_name_bn, division, sow_months, harvest_months, avg_yield, notes_en, notes_bn, image_url) VALUES
(
  'Boro Rice', 'বোরো ধান', 'Rajshahi',
  ARRAY[11, 12, 1], ARRAY[4, 5],
  'প্রতি হেক্টরে ৫-৬ টন',
  'Irrigated rice grown in dry season. Requires consistent water supply.',
  'শুষ্ক মৌসুমে সেচের মাধ্যমে চাষ হয়। নিয়মিত পানি সরবরাহ নিশ্চিত করতে হবে।',
  'https://placehold.co/600x400?text=Boro+Rice'
),
(
  'Aman Rice', 'আমন ধান', 'Mymensingh',
  ARRAY[6, 7], ARRAY[11, 12],
  'প্রতি হেক্টরে ৩-৪ টন',
  'Rain-fed rice. Planted with the monsoon and harvested in late autumn.',
  'বৃষ্টিনির্ভর ধান। বর্ষায় রোপণ করা হয় এবং শরতের শেষে কাটা হয়।',
  'https://placehold.co/600x400?text=Aman+Rice'
),
(
  'Tossa Jute', 'তোষা পাট', 'Rangpur',
  ARRAY[3, 4], ARRAY[7, 8],
  'প্রতি হেক্টরে ২.৫-৩ টন আঁশ',
  'Major cash crop. Requires warm humid climate and well-drained loam soil.',
  'প্রধান অর্থকরী ফসল। উষ্ণ আর্দ্র আবহাওয়া ও সুনিষ্কাশিত দোআঁশ মাটিতে ভালো হয়।',
  'https://placehold.co/600x400?text=Tossa+Jute'
),
(
  'Mustard', 'সরিষা', 'Rajshahi',
  ARRAY[10, 11], ARRAY[1, 2],
  'প্রতি হেক্টরে ১-১.৫ টন',
  'Short duration oil crop. Grows well in cool dry weather.',
  'স্বল্পমেয়াদী তেল ফসল। ঠান্ডা শুষ্ক আবহাওয়ায় ভালো জন্মায়।',
  'https://placehold.co/600x400?text=Mustard'
),
(
  'Potato', 'আলু', 'Rangpur',
  ARRAY[10, 11], ARRAY[1, 2],
  'প্রতি হেক্টরে ২০-২৫ টন',
  'Most important vegetable crop. Requires cool weather and well-drained fertile soil.',
  'সবচেয়ে গুরুত্বপূর্ণ সবজি ফসল। ঠান্ডা আবহাওয়া ও উর্বর সুনিষ্কাশিত মাটি প্রয়োজন।',
  'https://placehold.co/600x400?text=Potato'
),
(
  'Wheat', 'গম', 'Rangpur',
  ARRAY[11, 12], ARRAY[3, 4],
  'প্রতি হেক্টরে ৩-৪ টন',
  'Second most important cereal after rice. Needs cool dry weather.',
  'ধানের পরে দ্বিতীয় গুরুত্বপূর্ণ শস্য। ঠান্ডা ও শুষ্ক আবহাওয়া প্রয়োজন।',
  'https://placehold.co/600x400?text=Wheat'
),
(
  'Tomato', 'টমেটো', 'Dhaka',
  ARRAY[9, 10], ARRAY[12, 1, 2],
  'প্রতি হেক্টরে ৩০-৪০ টন',
  'High value vegetable. Requires staking and regular pest management.',
  'উচ্চমূল্যের সবজি। খুঁটি দেওয়া ও নিয়মিত পোকামাকড় ব্যবস্থাপনা প্রয়োজন।',
  'https://placehold.co/600x400?text=Tomato'
),
(
  'Lentil', 'মসুর', 'Mymensingh',
  ARRAY[10, 11], ARRAY[2, 3],
  'প্রতি হেক্টরে ০.৮-১.২ টন',
  'Cool season pulse crop. Fixes atmospheric nitrogen and improves soil health.',
  'শীতকালীন ডাল ফসল। বায়ুমণ্ডলীয় নাইট্রোজেন স্থিরকরণে সহায়তা করে।',
  'https://placehold.co/600x400?text=Lentil'
),
(
  'Tea', 'চা', 'Sylhet',
  ARRAY[3, 4], ARRAY[4, 5, 6, 7, 8, 9, 10, 11],
  'প্রতি হেক্টরে ১.৫-২ টন শুকনো পাতা',
  'Perennial plantation crop. Requires hilly acidic soil and high rainfall.',
  'বহুবর্ষজীবী বাগান ফসল। পাহাড়ি অম্লীয় মাটি ও প্রচুর বৃষ্টিপাত প্রয়োজন।',
  'https://placehold.co/600x400?text=Tea'
),
(
  'Onion', 'পেঁয়াজ', 'Rajshahi',
  ARRAY[10, 11], ARRAY[2, 3],
  'প্রতি হেক্টরে ১০-১৫ টন',
  'Major spice crop. Rajshahi and Faridpur are main producing areas.',
  'প্রধান মসলা ফসল। রাজশাহী ও ফরিদপুর প্রধান উৎপাদন এলাকা।',
  'https://placehold.co/600x400?text=Onion'
);


-- ============================================================
-- SOIL LOOKUP (8 entries covering major soil types per division)
-- ============================================================

INSERT INTO soil_lookup (division, soil_type, recommended_crops, tips_en, tips_bn, ph_range, water_retention) VALUES
(
  'Rajshahi', 'দোআঁশ মাটি (Loam)',
  ARRAY['ধান', 'গম', 'সরিষা', 'পেঁয়াজ', 'রসুন'],
  'Ideal for most crops. Maintain organic matter by adding compost annually.',
  'অধিকাংশ ফসলের জন্য আদর্শ। প্রতি বছর কম্পোস্ট যোগ করে জৈব পদার্থ বজায় রাখুন।',
  '6.0 - 7.0', 'medium'
),
(
  'Rajshahi', 'বেলে দোআঁশ মাটি (Sandy Loam)',
  ARRAY['আলু', 'সরিষা', 'চিনাবাদাম', 'তরমুজ'],
  'Good drainage. Add compost to improve water retention. Suitable for root crops.',
  'ভালো নিষ্কাশন ক্ষমতা। পানি ধারণ উন্নত করতে কম্পোস্ট যোগ করুন। কন্দ ফসলের জন্য উপযুক্ত।',
  '5.5 - 6.5', 'low'
),
(
  'Rangpur', 'এঁটেল দোআঁশ মাটি (Clay Loam)',
  ARRAY['ধান', 'পাট', 'গম', 'ডাল ফসল'],
  'High water retention. Avoid waterlogging. Add gypsum to improve structure.',
  'পানি ধারণ ক্ষমতা বেশি। জলাবদ্ধতা এড়িয়ে চলুন। গঠন উন্নত করতে জিপসাম ব্যবহার করুন।',
  '6.0 - 7.5', 'high'
),
(
  'Mymensingh', 'পলি মাটি (Alluvial / Silt)',
  ARRAY['ধান', 'পাট', 'গম', 'সবজি', 'কলা'],
  'Very fertile due to river deposits. Excellent for rice and jute.',
  'নদীর পলি সমৃদ্ধ মাটি। ধান ও পাট চাষের জন্য চমৎকার।',
  '6.5 - 7.5', 'medium'
),
(
  'Sylhet', 'লাল মাটি (Red / Laterite)',
  ARRAY['চা', 'আনারস', 'রাবার', 'কাজুবাদাম'],
  'Acidic and iron-rich. Ideal for tea and pineapple. Avoid lime-sensitive crops.',
  'অম্লীয় ও লৌহসমৃদ্ধ মাটি। চা ও আনারসের জন্য আদর্শ। চুনকামী ফসল এড়িয়ে চলুন।',
  '4.5 - 5.5', 'low'
),
(
  'Dhaka', 'দোআঁশ মাটি (Loam)',
  ARRAY['সবজি', 'ধান', 'পেঁপে', 'কলা', 'টমেটো'],
  'Suitable for intensive vegetable farming. Ensure proper drainage during monsoon.',
  'নিবিড় সবজি চাষের জন্য উপযুক্ত। বর্ষায় সঠিক নিষ্কাশন নিশ্চিত করুন।',
  '6.0 - 7.0', 'medium'
),
(
  'Rangpur', 'বেলে মাটি (Sandy)',
  ARRAY['তরমুজ', 'বাদাম', 'মিষ্টি আলু', 'গাজর'],
  'Low fertility and water retention. Heavy composting needed. Good for root vegetables.',
  'উর্বরতা ও পানি ধারণ ক্ষমতা কম। প্রচুর কম্পোস্ট প্রয়োজন। কন্দ সবজির জন্য ভালো।',
  '5.5 - 6.5', 'low'
),
(
  'Mymensingh', 'জৈব মাটি (Organic / Peaty)',
  ARRAY['ধান', 'পাট', 'শাকসবজি'],
  'High in organic matter. Can be waterlogged — ensure drainage. Very productive for rice.',
  'জৈব পদার্থ বেশি। জলাবদ্ধতার সম্ভাবনা — নিষ্কাশন নিশ্চিত করুন। ধান চাষে অত্যন্ত উৎপাদনশীল।',
  '5.0 - 6.0', 'high'
);


-- ============================================================
-- GUIDELINES (6 published articles)
-- ============================================================

INSERT INTO guidelines (topic, category, body_en, body_bn, image_url, is_published) VALUES
(
  'ধানের সঠিক বপন সময় ও পদ্ধতি',
  'sowing',
  'Rice sowing should be done when soil temperature is above 20°C. For Boro season, sow seeds in November-December in seedbeds. Maintain a seed rate of 30-40 kg per hectare for transplanted rice. Ensure seedbed is well-prepared with fine tilth and proper drainage.',
  'মাটির তাপমাত্রা ২০°C এর উপরে থাকলে ধানের বীজ বপন করা উচিত। বোরো মৌসুমে নভেম্বর-ডিসেম্বরে বীজতলায় বীজ বপন করুন। রোপণ ধানের জন্য প্রতি হেক্টরে ৩০-৪০ কেজি বীজ হার বজায় রাখুন।',
  'https://placehold.co/600x400?text=Rice+Sowing',
  TRUE
),
(
  'সেচ ব্যবস্থাপনা — পানির সঠিক ব্যবহার',
  'irrigation',
  'Efficient irrigation is critical for Bangladeshi agriculture. For rice, maintain 2-5 cm standing water during vegetative stage. Use alternate wetting and drying (AWD) technique to save 30% water. For vegetables, drip irrigation is most efficient. Always irrigate in early morning or evening to reduce evaporation.',
  'বাংলাদেশের কৃষিতে দক্ষ সেচ অত্যন্ত গুরুত্বপূর্ণ। ধানের বৃদ্ধির পর্যায়ে ২-৫ সেমি পানি রাখুন। ৩০% পানি সাশ্রয়ের জন্য পর্যায়ক্রমে ভেজানো ও শুকানো পদ্ধতি ব্যবহার করুন।',
  'https://placehold.co/600x400?text=Irrigation+Guide',
  TRUE
),
(
  'জৈব ও রাসায়নিক সারের সঠিক ব্যবহার',
  'fertilizer',
  'A balanced fertilization program is essential for high yields. Apply organic matter (compost/vermicompost) at 5-10 tonnes per hectare before land preparation. For rice, apply urea in 3 splits: at basal, tillering and panicle initiation stages. Always do soil testing before deciding fertilizer doses.',
  'উচ্চ ফলনের জন্য সুষম সার প্রয়োগ পরিকল্পনা অপরিহার্য। জমি প্রস্তুতির আগে প্রতি হেক্টরে ৫-১০ টন জৈব পদার্থ প্রয়োগ করুন। ধানে ইউরিয়া তিনটি ভাগে প্রয়োগ করুন।',
  'https://placehold.co/600x400?text=Fertilizer+Guide',
  TRUE
),
(
  'ধানের মাজরা পোকা দমন',
  'pest_control',
  'Stem borer is one of the most damaging pests of rice in Bangladesh. Monitor fields regularly from transplanting. Use pheromone traps to detect adult moths early. Apply cartap hydrochloride or chlorpyrifos at economic threshold level (1 egg mass per hill or 5% dead hearts). Remove and destroy egg masses manually when population is low.',
  'মাজরা পোকা বাংলাদেশে ধানের সবচেয়ে ক্ষতিকর পোকাগুলোর একটি। রোপণের পর থেকে নিয়মিত মাঠ পর্যবেক্ষণ করুন। প্রাপ্তবয়স্ক মথ শনাক্তে ফেরোমন ফাঁদ ব্যবহার করুন।',
  'https://placehold.co/600x400?text=Pest+Control',
  TRUE
),
(
  'ধান কাটার সঠিক সময় ও পদ্ধতি',
  'harvesting',
  'Harvest rice when 80-85% of grains are golden yellow and grain moisture is 20-25%. Delayed harvesting causes shattering losses and quality deterioration. Cut at 15-20 cm above ground level. Thresh immediately after harvest to prevent fungal infection. Dry grains to 14% moisture for safe storage.',
  'যখন ৮০-৮৫% দানা সোনালি হলুদ হয় এবং দানার আর্দ্রতা ২০-২৫% থাকে তখন ধান কাটুন। দেরিতে কাটলে ঝরে পড়া ক্ষতি ও গুণমান নষ্ট হয়। মাটি থেকে ১৫-২০ সেমি উপরে কাটুন।',
  'https://placehold.co/600x400?text=Harvesting+Guide',
  TRUE
),
(
  'ধান সংরক্ষণের সঠিক পদ্ধতি',
  'storage',
  'Proper storage prevents 10-15% post-harvest losses. Dry grains to 12-14% moisture content before storage. Use hermetic storage bags or metal silos for small farmers. Clean and fumigate storage structures before use. Monitor for insects and rodents regularly. Never store wet or damaged grains with healthy ones.',
  'সঠিক সংরক্ষণ ১০-১৫% কাটার পরের ক্ষতি রোধ করে। সংরক্ষণের আগে দানার আর্দ্রতা ১২-১৪% এ শুকিয়ে নিন। ছোট কৃষকদের জন্য হার্মেটিক ব্যাগ বা ধাতব সাইলো ব্যবহার করুন।',
  'https://placehold.co/600x400?text=Storage+Guide',
  TRUE
);


-- ============================================================
-- EQUIPMENT (5 rentals — one per type + extra)
-- owner_id uses the same seed farmer profile
-- ============================================================

INSERT INTO equipment (owner_id, name, description, type, images, rate_per_day, division, location_text, min_booking_days, available) VALUES
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'মাহিন্দ্রা ট্র্যাক্টর ৪৭৫ DI',
  '৪৭ হর্সপাওয়ার ট্র্যাক্টর। জমি চাষ, মই দেওয়া ও মালামাল পরিবহনে উপযুক্ত। চালক সহ ভাড়া পাওয়া যায়।',
  'tractor',
  ARRAY['https://placehold.co/600x400?text=Mahindra+Tractor'],
  3500.00, 'Rajshahi', 'রাজশাহী সদর', 1, TRUE
),
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'পাওয়ার টিলার — কুবোটা',
  'ছোট জমির জন্য পাওয়ার টিলার। সরু আইলের মধ্যে সহজে চলাচল করতে পারে।',
  'tractor',
  ARRAY['https://placehold.co/600x400?text=Power+Tiller'],
  1200.00, 'Mymensingh', 'ময়মনসিংহ সদর', 1, TRUE
),
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'সেচ পাম্প — ৫ কিউসেক',
  '৫ কিউসেক ক্ষমতার শ্যালো টিউবওয়েল পাম্প। ধান ও সবজি মাঠের সেচের জন্য উপযুক্ত।',
  'pump',
  ARRAY['https://placehold.co/600x400?text=Irrigation+Pump'],
  800.00, 'Rangpur', 'রংপুর সদর', 2, TRUE
),
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'পিকআপ ট্রাক — ফসল পরিবহন',
  '১ টন বহন ক্ষমতার পিকআপ ট্রাক। কৃষিপণ্য বাজারে নিয়ে যাওয়ার জন্য উপযুক্ত।',
  'truck',
  ARRAY['https://placehold.co/600x400?text=Pickup+Truck'],
  2500.00, 'Sylhet', 'সিলেট সদর', 1, TRUE
),
(
  'dad12c10-b0d0-49a1-bfa2-17e3496d3346',
  'কম্বাইন হার্ভেস্টার',
  'ধান কাটা, মাড়াই ও পরিষ্কার একসাথে করে। শ্রম ও সময় উভয়ই সাশ্রয় করে।',
  'other',
  ARRAY['https://placehold.co/600x400?text=Combine+Harvester'],
  8000.00, 'Mymensingh', 'ময়মনসিংহ', 1, TRUE
);

-- ============================================================
-- END OF SEED DATA
-- ============================================================
ENDSQL
echo "Done"
Output
Done


Done

