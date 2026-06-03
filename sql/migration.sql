-- ============================================================
-- SpiceDesk - Full Supabase PostgreSQL Schema
-- ============================================================

-- Helper: get the business_id for the current authenticated user
-- Returns the first business owned by the user
CREATE OR REPLACE FUNCTION get_business_id()
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    biz_id UUID;
BEGIN
    SELECT id INTO biz_id
    FROM businesses
    WHERE owner_id = auth.uid()
    LIMIT 1;
    RETURN biz_id;
END;
$$;

-- Helper: update stock via RPC
CREATE OR REPLACE FUNCTION adjust_stock(product_id UUID, quantity INT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE products
    SET stock = stock + quantity
    WHERE id = product_id;
END;
$$;

-- ============================================================
-- PROFILES
-- ============================================================
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
    ON profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id);

-- Trigger: auto-create profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO profiles (id, email, name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', NEW.raw_user_meta_data->>'full_name')
    );
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();

-- ============================================================
-- BUSINESSES
-- ============================================================
CREATE TABLE businesses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    address TEXT,
    phone TEXT,
    email TEXT,
    logo_url TEXT,
    currency TEXT DEFAULT 'INR',
    vat_rate DECIMAL DEFAULT 12.0,
    invoice_prefix TEXT DEFAULT 'INV',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE businesses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own businesses"
    ON businesses FOR SELECT
    USING (auth.uid() = owner_id);

CREATE POLICY "Users can insert own businesses"
    ON businesses FOR INSERT
    WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update own businesses"
    ON businesses FOR UPDATE
    USING (auth.uid() = owner_id);

CREATE POLICY "Users can delete own businesses"
    ON businesses FOR DELETE
    USING (auth.uid() = owner_id);

-- ============================================================
-- CATEGORIES
-- ============================================================
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('product', 'expense')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own categories"
    ON categories FOR SELECT
    USING (business_id = get_business_id());

CREATE POLICY "Users can insert own categories"
    ON categories FOR INSERT
    WITH CHECK (business_id = get_business_id());

CREATE POLICY "Users can update own categories"
    ON categories FOR UPDATE
    USING (business_id = get_business_id());

CREATE POLICY "Users can delete own categories"
    ON categories FOR DELETE
    USING (business_id = get_business_id());

-- ============================================================
-- PRODUCTS
-- ============================================================
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    barcode TEXT,
    sku TEXT,
    description TEXT,
    price DECIMAL NOT NULL DEFAULT 0,
    cost_price DECIMAL,
    stock INT DEFAULT 0,
    unit TEXT DEFAULT 'piece',
    image_url TEXT,
    low_stock_threshold INT DEFAULT 10,
    vat_rate DECIMAL DEFAULT 12.0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own products"
    ON products FOR SELECT
    USING (business_id = get_business_id());

CREATE POLICY "Users can insert own products"
    ON products FOR INSERT
    WITH CHECK (business_id = get_business_id());

CREATE POLICY "Users can update own products"
    ON products FOR UPDATE
    USING (business_id = get_business_id());

CREATE POLICY "Users can delete own products"
    ON products FOR DELETE
    USING (business_id = get_business_id());

-- ============================================================
-- CUSTOMERS
-- ============================================================
CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    address TEXT,
    total_orders INT DEFAULT 0,
    total_spent DECIMAL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own customers"
    ON customers FOR SELECT
    USING (business_id = get_business_id());

CREATE POLICY "Users can insert own customers"
    ON customers FOR INSERT
    WITH CHECK (business_id = get_business_id());

CREATE POLICY "Users can update own customers"
    ON customers FOR UPDATE
    USING (business_id = get_business_id());

CREATE POLICY "Users can delete own customers"
    ON customers FOR DELETE
    USING (business_id = get_business_id());

-- ============================================================
-- ORDERS
-- ============================================================
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    order_number TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('walk-in', 'delivery', 'dine-in')),
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'preparing', 'ready', 'completed', 'cancelled')),
    subtotal DECIMAL NOT NULL DEFAULT 0,
    tax_amount DECIMAL NOT NULL DEFAULT 0,
    discount DECIMAL NOT NULL DEFAULT 0,
    total DECIMAL NOT NULL DEFAULT 0,
    payment_method TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own orders"
    ON orders FOR SELECT
    USING (business_id = get_business_id());

CREATE POLICY "Users can insert own orders"
    ON orders FOR INSERT
    WITH CHECK (business_id = get_business_id());

CREATE POLICY "Users can update own orders"
    ON orders FOR UPDATE
    USING (business_id = get_business_id());

CREATE POLICY "Users can delete own orders"
    ON orders FOR DELETE
    USING (business_id = get_business_id());

-- ============================================================
-- ORDER ITEMS
-- ============================================================
CREATE TABLE order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    product_name TEXT NOT NULL,
    unit_price DECIMAL NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    discount DECIMAL NOT NULL DEFAULT 0,
    tax_amount DECIMAL NOT NULL DEFAULT 0,
    total DECIMAL NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own order items"
    ON order_items FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM orders
            WHERE orders.id = order_items.order_id
              AND orders.business_id = get_business_id()
        )
    );

CREATE POLICY "Users can insert own order items"
    ON order_items FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM orders
            WHERE orders.id = order_items.order_id
              AND orders.business_id = get_business_id()
        )
    );

CREATE POLICY "Users can update own order items"
    ON order_items FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM orders
            WHERE orders.id = order_items.order_id
              AND orders.business_id = get_business_id()
        )
    );

CREATE POLICY "Users can delete own order items"
    ON order_items FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM orders
            WHERE orders.id = order_items.order_id
              AND orders.business_id = get_business_id()
        )
    );

-- ============================================================
-- EXPENSES
-- ============================================================
CREATE TABLE expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT,
    amount DECIMAL NOT NULL,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    receipt_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own expenses"
    ON expenses FOR SELECT
    USING (business_id = get_business_id());

CREATE POLICY "Users can insert own expenses"
    ON expenses FOR INSERT
    WITH CHECK (business_id = get_business_id());

CREATE POLICY "Users can update own expenses"
    ON expenses FOR UPDATE
    USING (business_id = get_business_id());

CREATE POLICY "Users can delete own expenses"
    ON expenses FOR DELETE
    USING (business_id = get_business_id());

-- ============================================================
-- INVOICES
-- ============================================================
CREATE TABLE invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    invoice_number TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'draft'
        CHECK (status IN ('draft', 'issued', 'paid', 'cancelled', 'overdue')),
    subtotal DECIMAL NOT NULL DEFAULT 0,
    tax_amount DECIMAL NOT NULL DEFAULT 0,
    discount DECIMAL NOT NULL DEFAULT 0,
    total DECIMAL NOT NULL DEFAULT 0,
    pdf_path TEXT,
    due_date DATE,
    issued_date DATE DEFAULT CURRENT_DATE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own invoices"
    ON invoices FOR SELECT
    USING (business_id = get_business_id());

CREATE POLICY "Users can insert own invoices"
    ON invoices FOR INSERT
    WITH CHECK (business_id = get_business_id());

CREATE POLICY "Users can update own invoices"
    ON invoices FOR UPDATE
    USING (business_id = get_business_id());

CREATE POLICY "Users can delete own invoices"
    ON invoices FOR DELETE
    USING (business_id = get_business_id());

-- ============================================================
-- BANK ACCOUNTS
-- ============================================================
CREATE TABLE bank_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    account_name TEXT NOT NULL,
    account_number TEXT,
    bank_name TEXT,
    ifsc_code TEXT,
    balance DECIMAL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE bank_accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own bank accounts"
    ON bank_accounts FOR SELECT
    USING (business_id = get_business_id());

CREATE POLICY "Users can insert own bank accounts"
    ON bank_accounts FOR INSERT
    WITH CHECK (business_id = get_business_id());

CREATE POLICY "Users can update own bank accounts"
    ON bank_accounts FOR UPDATE
    USING (business_id = get_business_id());

CREATE POLICY "Users can delete own bank accounts"
    ON bank_accounts FOR DELETE
    USING (business_id = get_business_id());

-- ============================================================
-- BANK TRANSACTIONS
-- ============================================================
CREATE TABLE bank_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bank_account_id UUID NOT NULL REFERENCES bank_accounts(id) ON DELETE CASCADE,
    description TEXT,
    amount DECIMAL NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('credit', 'debit')),
    reference TEXT,
    transaction_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE bank_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own bank transactions"
    ON bank_transactions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM bank_accounts
            WHERE bank_accounts.id = bank_transactions.bank_account_id
              AND bank_accounts.business_id = get_business_id()
        )
    );

CREATE POLICY "Users can insert own bank transactions"
    ON bank_transactions FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM bank_accounts
            WHERE bank_accounts.id = bank_transactions.bank_account_id
              AND bank_accounts.business_id = get_business_id()
        )
    );

CREATE POLICY "Users can update own bank transactions"
    ON bank_transactions FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM bank_accounts
            WHERE bank_accounts.id = bank_transactions.bank_account_id
              AND bank_accounts.business_id = get_business_id()
        )
    );

CREATE POLICY "Users can delete own bank transactions"
    ON bank_transactions FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM bank_accounts
            WHERE bank_accounts.id = bank_transactions.bank_account_id
              AND bank_accounts.business_id = get_business_id()
        )
    );

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_businesses_owner ON businesses(owner_id);
CREATE INDEX IF NOT EXISTS idx_categories_business ON categories(business_id);
CREATE INDEX IF NOT EXISTS idx_products_business ON products(business_id);
CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(business_id, barcode);
CREATE INDEX IF NOT EXISTS idx_customers_business ON customers(business_id);
CREATE INDEX IF NOT EXISTS idx_orders_business ON orders(business_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(business_id, status);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_expenses_business ON expenses(business_id);
CREATE INDEX IF NOT EXISTS idx_invoices_business ON invoices(business_id);
CREATE INDEX IF NOT EXISTS idx_bank_accounts_business ON bank_accounts(business_id);
CREATE INDEX IF NOT EXISTS idx_bank_transactions_account ON bank_transactions(bank_account_id);
