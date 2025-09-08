-- Users table for registration
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    telegram_id BIGINT UNIQUE NOT NULL,
    chat_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tables in restaurant
CREATE TABLE IF NOT EXISTS restaurant_tables (
    id SERIAL PRIMARY KEY,
    table_number INT UNIQUE NOT NULL,
    capacity INT NOT NULL,
    location VARCHAR(50), -- 'window', 'center', 'terrace'
    is_available BOOLEAN DEFAULT true
);

-- Bookings
CREATE TABLE IF NOT EXISTS bookings (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id),
    table_id INT REFERENCES restaurant_tables(id),
    booking_date DATE NOT NULL,
    booking_time TIME NOT NULL,
    guests INT NOT NULL,
    special_requests TEXT,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'confirmed', 'cancelled'
    confirmation_code VARCHAR(10) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(table_id, booking_date, booking_time)
);

-- Flow instances storage for persistent_flow
CREATE TABLE IF NOT EXISTS flow_instances (
    id VARCHAR(255) PRIMARY KEY,
    flow_name VARCHAR(100) NOT NULL,
    user_id BIGINT NOT NULL,
    chat_id BIGINT NOT NULL,
    current_step VARCHAR(100) NOT NULL,
    state_data JSONB,
    scene_data JSONB,
    wait_token VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for flow_instances
CREATE INDEX IF NOT EXISTS idx_flow_user ON flow_instances (user_id, chat_id);
CREATE INDEX IF NOT EXISTS idx_flow_token ON flow_instances (wait_token);

-- Insert sample tables
INSERT INTO restaurant_tables (table_number, capacity, location) VALUES
    (1, 2, 'window'),
    (2, 2, 'window'),
    (3, 4, 'center'),
    (4, 4, 'center'),
    (5, 6, 'center'),
    (6, 2, 'terrace'),
    (7, 4, 'terrace'),
    (8, 8, 'terrace');

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bookings_updated_at BEFORE UPDATE ON bookings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_flow_instances_updated_at BEFORE UPDATE ON flow_instances
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();