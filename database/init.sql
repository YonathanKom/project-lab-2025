-- Initialize database for the Shopping List Management System

-- Users Table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL
);

-- Households Table
CREATE TABLE IF NOT EXISTS households (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User-Household Many-to-Many Relationship Table
CREATE TABLE IF NOT EXISTS user_households (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    household_id INTEGER NOT NULL,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    role VARCHAR(50) DEFAULT 'member', -- 'admin', 'member'
    CONSTRAINT fk_user_households_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_user_households_household FOREIGN KEY (household_id) REFERENCES households(id) ON DELETE CASCADE,
    UNIQUE(user_id, household_id)
);

-- Household Invitations Table
CREATE TABLE IF NOT EXISTS household_invitations (
    id SERIAL PRIMARY KEY,
    household_id INTEGER NOT NULL,
    invited_by_id INTEGER NOT NULL,
    invited_user_id INTEGER NOT NULL,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'accepted', 'rejected', 'cancelled'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    responded_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT fk_invitations_household FOREIGN KEY (household_id) REFERENCES households(id) ON DELETE CASCADE,
    CONSTRAINT fk_invitations_invited_by FOREIGN KEY (invited_by_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_invitations_invited_user FOREIGN KEY (invited_user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(household_id, invited_user_id, status) -- Prevent duplicate pending invitations
);

-- Shopping Lists Table (keep household_id for list ownership)
CREATE TABLE IF NOT EXISTS shopping_lists (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    owner_id INTEGER NOT NULL,
    household_id INTEGER NOT NULL,
    CONSTRAINT fk_shopping_lists_owner FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_shopping_lists_household FOREIGN KEY (household_id) REFERENCES households(id) ON DELETE CASCADE
);

-- Shopping Items Table
CREATE TABLE IF NOT EXISTS shopping_items (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    quantity FLOAT NOT NULL,
    unit VARCHAR(50) NOT NULL,
    is_purchased BOOLEAN DEFAULT FALSE,
    shopping_list_id INTEGER NOT NULL,
    CONSTRAINT fk_shopping_items_list FOREIGN KEY (shopping_list_id) REFERENCES shopping_lists(id) ON DELETE CASCADE
);

-- Shopping List History Table
CREATE TABLE IF NOT EXISTS shopping_list_history (
    id SERIAL PRIMARY KEY,
    shopping_list_id INTEGER NOT NULL,
    action VARCHAR(50) NOT NULL, -- "add", "update", "delete"
    item_data JSONB NOT NULL,
    user_id INTEGER NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT fk_history_list FOREIGN KEY (shopping_list_id) REFERENCES shopping_lists(id) ON DELETE CASCADE,
    CONSTRAINT fk_history_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Stores Table
CREATE TABLE IF NOT EXISTS stores (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    location TEXT -- Can be GPS coordinates or address
);

-- Item Prices Table
CREATE TABLE IF NOT EXISTS item_prices (
    id SERIAL PRIMARY KEY,
    item_id INTEGER NOT NULL,
    store_id INTEGER NOT NULL,
    price FLOAT NOT NULL,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT fk_prices_item FOREIGN KEY (item_id) REFERENCES shopping_items(id) ON DELETE CASCADE,
    CONSTRAINT fk_prices_store FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE
);

-- Purchase History Table
CREATE TABLE IF NOT EXISTS purchase_history (
    id SERIAL PRIMARY KEY,
    household_id INTEGER NOT NULL,
    item_name VARCHAR(100) NOT NULL,
    purchase_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    frequency INTEGER DEFAULT 1,
    CONSTRAINT fk_purchase_household FOREIGN KEY (household_id) REFERENCES households(id) ON DELETE CASCADE
);

-- Create indexes for better performance
CREATE INDEX idx_invitations_invited_user ON household_invitations(invited_user_id);
CREATE INDEX idx_invitations_status ON household_invitations(status);
CREATE INDEX idx_shopping_items_name ON shopping_items(name);
CREATE INDEX idx_purchase_history_item_name ON purchase_history(item_name);
CREATE INDEX idx_shopping_lists_household ON shopping_lists(household_id);
CREATE INDEX idx_shopping_items_list ON shopping_items(shopping_list_id);
CREATE INDEX idx_history_list ON shopping_list_history(shopping_list_id);
CREATE INDEX idx_user_households_user ON user_households(user_id);
CREATE INDEX idx_user_households_household ON user_households(household_id);