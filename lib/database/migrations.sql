-- ============================================================
-- KRISHOK APP — COMPLETE DATABASE MIGRATIONS
-- Run this entire file in the Supabase SQL editor in one go.
-- Tables are numbered in dependency order.
-- ============================================================


-- ============================================================
-- 001 profiles
-- Extends Supabase auth.users with app-specific profile data.
-- Both email and phone are nullable at DB level.
-- App-side registration enforces that at least one is provided.
-- ============================================================

CREATE TABLE profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email       TEXT,
  phone       TEXT,
  name        TEXT NOT NULL DEFAULT 'New User',
  role        TEXT NOT NULL DEFAULT 'farmer'
                CHECK (role IN ('farmer', 'customer')),
  division    TEXT,
  district    TEXT,
  lang_pref   TEXT NOT NULL DEFAULT 'bn'
                CHECK (lang_pref IN ('bn', 'en')),
  avatar_url  TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT phone_unique UNIQUE (phone)
);

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, email, phone, name)
  VALUES (
    NEW.id,
    NULLIF(NEW.email, ''),
    NULLIF(NEW.phone, ''),
    COALESCE(
      NEW.raw_user_meta_data->>'name',
      NULLIF(NEW.phone, ''),
      NULLIF(NEW.email, ''),
      'New User'
    )
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();



-- ============================================================
-- 004 marketplace — products + orders + cart
-- ============================================================

CREATE TABLE products (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  description TEXT,
  category    TEXT NOT NULL
                CHECK (category IN (
                  'crop', 'fertilizer', 'insecticide', 'tool', 'other'
                )),
  price       NUMERIC(12, 2) NOT NULL,
  unit        TEXT NOT NULL,
  stock       INTEGER NOT NULL DEFAULT 0,
  images      TEXT[],
  division    TEXT,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_products_seller_id ON products(seller_id);
CREATE INDEX idx_products_category  ON products(category);
CREATE INDEX idx_products_division  ON products(division);
CREATE INDEX idx_products_is_active ON products(is_active);

CREATE TABLE orders (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  seller_id        UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  product_id       UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  quantity         INTEGER NOT NULL,
  total            NUMERIC(12, 2) NOT NULL,
  status           TEXT NOT NULL DEFAULT 'pending'
                     CHECK (status IN (
                       'pending', 'confirmed', 'shipped', 'delivered', 'cancelled'
                     )),
  payment_method   TEXT
                     CHECK (payment_method IN ('bkash', 'sslcommerz', 'cash')),
  delivery_address TEXT,
  notes            TEXT,
  paid_at          TIMESTAMPTZ,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_orders_buyer_id   ON orders(buyer_id);
CREATE INDEX idx_orders_seller_id  ON orders(seller_id);
CREATE INDEX idx_orders_product_id ON orders(product_id);
CREATE INDEX idx_orders_status     ON orders(status);

CREATE TABLE cart_items (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  quantity   INTEGER NOT NULL DEFAULT 1,
  added_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, product_id)
);

CREATE INDEX idx_cart_user_id ON cart_items(user_id);


-- ============================================================
-- 005 rentals — equipment + bookings
-- ============================================================

CREATE TABLE equipment (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id         UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name             TEXT NOT NULL,
  description      TEXT,
  type             TEXT NOT NULL
                     CHECK (type IN ('tractor', 'truck', 'pump', 'other')),
  images           TEXT[],
  rate_per_day     NUMERIC(10, 2) NOT NULL,
  division         TEXT,
  location_text    TEXT,
  min_booking_days INTEGER NOT NULL DEFAULT 1,
  available        BOOLEAN NOT NULL DEFAULT TRUE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_equipment_owner_id ON equipment(owner_id);
CREATE INDEX idx_equipment_division ON equipment(division);
CREATE INDEX idx_equipment_type     ON equipment(type);

CREATE TABLE bookings (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  renter_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  equipment_id    UUID NOT NULL REFERENCES equipment(id) ON DELETE CASCADE,
  start_date      DATE NOT NULL,
  end_date        DATE NOT NULL,
  status          TEXT NOT NULL DEFAULT 'pending'
                    CHECK (status IN (
                      'pending', 'confirmed', 'active', 'completed', 'cancelled'
                    )),
  payment_status  TEXT NOT NULL DEFAULT 'pending'
                    CHECK (payment_status IN ('pending', 'paid', 'refunded')),
  payment_method  TEXT
                    CHECK (payment_method IN ('bkash', 'sslcommerz', 'cash')),
  total_cost      NUMERIC(12, 2) NOT NULL,
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (end_date >= start_date)
);

CREATE INDEX idx_bookings_renter_id    ON bookings(renter_id);
CREATE INDEX idx_bookings_equipment_id ON bookings(equipment_id);
CREATE INDEX idx_bookings_status       ON bookings(status);


-- ============================================================
-- 006 locations — nearby nurseries and buyers
-- ============================================================

CREATE TABLE locations (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  type        TEXT NOT NULL
                CHECK (type IN ('nursery', 'buyer')),
  lat         NUMERIC(10, 7) NOT NULL,
  lng         NUMERIC(10, 7) NOT NULL,
  phone       TEXT,
  division    TEXT,
  is_verified BOOLEAN NOT NULL DEFAULT FALSE,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_locations_type     ON locations(type);
CREATE INDEX idx_locations_division ON locations(division);


-- ============================================================
-- 007 doctors
-- ============================================================

CREATE TABLE doctors (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            TEXT NOT NULL,
  phone           TEXT NOT NULL,
  email           TEXT,
  specialization  TEXT,
  district        TEXT,
  division        TEXT,
  available_days  TEXT[],
  available_hours TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_doctors_division ON doctors(division);
CREATE INDEX idx_doctors_district ON doctors(district);


-- ============================================================
-- 008 crop_calendar
-- ============================================================

CREATE TABLE crop_calendar (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  crop_name_en   TEXT NOT NULL,
  crop_name_bn   TEXT NOT NULL,
  division       TEXT,
  sow_months     INTEGER[],
  harvest_months INTEGER[],
  avg_yield      TEXT,
  notes_en       TEXT,
  notes_bn       TEXT,
  image_url      TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_crop_calendar_division ON crop_calendar(division);


-- ============================================================
-- 009 soil_lookup
-- ============================================================

CREATE TABLE soil_lookup (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  division          TEXT NOT NULL,
  soil_type         TEXT NOT NULL,
  recommended_crops TEXT[],
  tips_en           TEXT,
  tips_bn           TEXT,
  ph_range          TEXT,
  water_retention   TEXT
                      CHECK (water_retention IN ('high', 'medium', 'low')),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_soil_division  ON soil_lookup(division);
CREATE INDEX idx_soil_soil_type ON soil_lookup(soil_type);


-- ============================================================
-- 010 guidelines
-- ============================================================

CREATE TABLE guidelines (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  topic        TEXT NOT NULL,
  category     TEXT NOT NULL
                 CHECK (category IN (
                   'sowing', 'irrigation', 'fertilizer',
                   'pest_control', 'harvesting', 'storage'
                 )),
  body_en      TEXT,
  body_bn      TEXT,
  image_url    TEXT,
  is_published BOOLEAN NOT NULL DEFAULT FALSE,
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_guidelines_category     ON guidelines(category);
CREATE INDEX idx_guidelines_is_published ON guidelines(is_published);


-- ============================================================
-- 012 notifications
-- ============================================================

CREATE TABLE notifications (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title      TEXT NOT NULL,
  body       TEXT NOT NULL,
  type       TEXT NOT NULL
               CHECK (type IN ('weather', 'booking', 'order', 'system')),
  is_read    BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);


-- ============================================================
-- 013 weather_alerts
-- ============================================================

CREATE TABLE weather_alerts (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  division   TEXT NOT NULL,
  alert_type TEXT NOT NULL,
  message    TEXT NOT NULL,
  severity   TEXT NOT NULL
               CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  issued_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_weather_alerts_division  ON weather_alerts(division);
CREATE INDEX idx_weather_alerts_issued_at ON weather_alerts(issued_at);

ALTER TABLE orders ADD COLUMN transaction_id TEXT;
ALTER TABLE bookings ADD COLUMN transaction_id TEXT;