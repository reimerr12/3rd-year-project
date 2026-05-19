-- ============================================================
-- KRISHOK APP — ROW LEVEL SECURITY POLICIES
-- Run this after migrations.sql has completed with no errors.
-- ============================================================

-- Enable RLS on every table
ALTER TABLE profiles        ENABLE ROW LEVEL SECURITY;
ALTER TABLE farms           ENABLE ROW LEVEL SECURITY;
ALTER TABLE farm_logs       ENABLE ROW LEVEL SECURITY;
ALTER TABLE products        ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders          ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items      ENABLE ROW LEVEL SECURITY;
ALTER TABLE equipment       ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings        ENABLE ROW LEVEL SECURITY;
ALTER TABLE locations       ENABLE ROW LEVEL SECURITY;
ALTER TABLE doctors         ENABLE ROW LEVEL SECURITY;
ALTER TABLE crop_calendar   ENABLE ROW LEVEL SECURITY;
ALTER TABLE soil_lookup     ENABLE ROW LEVEL SECURITY;
ALTER TABLE guidelines      ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_chat_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications   ENABLE ROW LEVEL SECURITY;
ALTER TABLE weather_alerts  ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- profiles
-- ============================================================

CREATE POLICY "profiles: read own"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "profiles: update own"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- ============================================================
-- farms
-- Farmers only — customers have no access to farm rows.
-- ============================================================

CREATE POLICY "farms: farmer full access"
  ON farms FOR ALL
  USING (
    auth.uid() = farmer_id
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role = 'farmer'
    )
  );

-- ============================================================
-- farm_logs
-- Farmers only — scoped to farms they own.
-- ============================================================

CREATE POLICY "farm_logs: farm owner full access"
  ON farm_logs FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM farms
      JOIN profiles ON profiles.id = auth.uid()
      WHERE farms.id = farm_logs.farm_id
        AND farms.farmer_id = auth.uid()
        AND profiles.role = 'farmer'
    )
  );

-- ============================================================
-- products
-- Any authenticated user can read active listings.
-- Only farmers can insert/update/delete their own products.
-- ============================================================

CREATE POLICY "products: anyone can read active"
  ON products FOR SELECT
  USING (is_active = TRUE AND auth.uid() IS NOT NULL);

CREATE POLICY "products: farmer full access own"
  ON products FOR ALL
  USING (
    auth.uid() = seller_id
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role = 'farmer'
    )
  );

-- ============================================================
-- orders
-- Buyers place and track orders.
-- Sellers see and update orders using orders.seller_id directly
-- (faster + survives product deletion).
-- Note: orders.seller_id must be populated at insert time from
-- the product's seller_id — enforce this in supabase_service.dart.
-- ============================================================

CREATE POLICY "orders: buyer sees own"
  ON orders FOR SELECT
  USING (auth.uid() = buyer_id);

CREATE POLICY "orders: buyer can insert"
  ON orders FOR INSERT
  WITH CHECK (auth.uid() = buyer_id);

CREATE POLICY "orders: buyer can update own"
  ON orders FOR UPDATE
  USING (auth.uid() = buyer_id);

CREATE POLICY "orders: seller sees own orders"
  ON orders FOR SELECT
  USING (auth.uid() = seller_id);

CREATE POLICY "orders: seller can update status"
  ON orders FOR UPDATE
  USING (auth.uid() = seller_id);

-- ============================================================
-- cart_items
-- Any authenticated user can manage their own cart.
-- ============================================================

CREATE POLICY "cart: user full access own"
  ON cart_items FOR ALL
  USING (auth.uid() = user_id);

-- ============================================================
-- equipment
-- Any authenticated user can read available listings.
-- Only farmers can insert/update/delete their own equipment.
-- ============================================================

CREATE POLICY "equipment: anyone can read available"
  ON equipment FOR SELECT
  USING (available = TRUE AND auth.uid() IS NOT NULL);

CREATE POLICY "equipment: farmer full access own"
  ON equipment FOR ALL
  USING (
    auth.uid() = owner_id
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role = 'farmer'
    )
  );

-- ============================================================
-- bookings
-- Both farmers and customers can rent equipment.
-- ============================================================

CREATE POLICY "bookings: renter sees own"
  ON bookings FOR SELECT
  USING (auth.uid() = renter_id);

CREATE POLICY "bookings: renter can insert"
  ON bookings FOR INSERT
  WITH CHECK (auth.uid() = renter_id);

CREATE POLICY "bookings: renter can update own"
  ON bookings FOR UPDATE
  USING (auth.uid() = renter_id);

CREATE POLICY "bookings: equipment owner sees bookings"
  ON bookings FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM equipment
      WHERE equipment.id = bookings.equipment_id
        AND equipment.owner_id = auth.uid()
    )
  );

CREATE POLICY "bookings: equipment owner can update status"
  ON bookings FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM equipment
      WHERE equipment.id = bookings.equipment_id
        AND equipment.owner_id = auth.uid()
    )
  );

-- ============================================================
-- public reference tables
-- Read-only for all authenticated users (both roles).
-- ============================================================

CREATE POLICY "locations: authenticated can read"
  ON locations FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "doctors: authenticated can read"
  ON doctors FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "crop_calendar: authenticated can read"
  ON crop_calendar FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "soil_lookup: authenticated can read"
  ON soil_lookup FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "guidelines: authenticated can read published"
  ON guidelines FOR SELECT
  USING (auth.uid() IS NOT NULL AND is_published = TRUE);

-- ============================================================
-- ai_chat_history
-- ============================================================

CREATE POLICY "ai_chat: user full access own"
  ON ai_chat_history FOR ALL
  USING (auth.uid() = user_id);

-- ============================================================
-- notifications
-- ============================================================

CREATE POLICY "notifications: user full access own"
  ON notifications FOR ALL
  USING (auth.uid() = user_id);

-- ============================================================
-- weather_alerts
-- Public read for all authenticated users.
-- ============================================================

CREATE POLICY "weather_alerts: authenticated can read"
  ON weather_alerts FOR SELECT
  USING (auth.uid() IS NOT NULL);
