CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone_number VARCHAR(30) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('client', 'agent', 'admin')),
    license_number VARCHAR(100) NULL,
    avatar_url VARCHAR(500) NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE property_types (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(100) NOT NULL UNIQUE
);


INSERT INTO property_types (name, slug) VALUES
('Residential', 'residential'),
('Villas', 'villas'),
('Apartments', 'apartments'),
('Townhouses', 'townhouses'),
('Luxury Villas', 'luxury-villas'),
('House & Lot', 'house-and-lot'),
('Subdivision', 'subdivision'),
('Residential Lot', 'residential-lot');


CREATE TABLE properties (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    agent_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    property_type_id INT NOT NULL REFERENCES property_types(id) ON DELETE RESTRICT,
    title VARCHAR(255) NOT NULL,
    subdivision_name VARCHAR(255) NULL,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,           
    province VARCHAR(100) NOT NULL,       
    price DECIMAL(14, 2) NOT NULL,       
    bedrooms INT DEFAULT 0,
    bathrooms INT DEFAULT 0,
    lot_area_sqm DECIMAL(10, 2) NOT NULL,  
    floor_area_sqm DECIMAL(10, 2) NULL,    
    status VARCHAR(30) DEFAULT 'available' CHECK (status IN ('available', 'reserved', 'sold')),
    title_status VARCHAR(100) DEFAULT 'Clean Title',
    utilities VARCHAR(255) DEFAULT 'Water, Electricity',
    description TEXT NULL,
    latitude DECIMAL(10, 7) NULL,
    longitude DECIMAL(10, 7) NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);


CREATE INDEX idx_properties_location ON properties (city, province);
CREATE INDEX idx_properties_type ON properties (property_type_id);
CREATE INDEX idx_properties_price ON properties (price);
CREATE INDEX idx_properties_specs ON properties (bedrooms, bathrooms);


CREATE TABLE property_images (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    property_id BIGINT NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    image_url VARCHAR(500) NOT NULL,
    display_order INT DEFAULT 1,
    is_primary BOOLEAN DEFAULT FALSE
);

CREATE TABLE property_features (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    property_id BIGINT NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    feature_name VARCHAR(255) NOT NULL
);


CREATE TABLE saved_properties (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    property_id BIGINT NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    saved_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_saved_property UNIQUE (user_id, property_id)
);


CREATE TABLE inquiries (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    inquiry_code VARCHAR(50) NOT NULL UNIQUE, 
    client_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    property_id BIGINT NOT NULL REFERENCES properties(id) ON DELETE RESTRICT,
    assigned_agent_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    message TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'submitted' CHECK (
        status IN (
            'submitted', 
            'requirements_submitted', 
            'under_review', 
            'for_resubmission', 
            'approved', 
            'completed', 
            'cancelled'
        )
    ),
    submitted_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_inquiries_client ON inquiries (client_id);
CREATE INDEX idx_inquiries_agent ON inquiries (assigned_agent_id);
CREATE INDEX idx_inquiries_status ON inquiries (status);


CREATE TABLE inquiry_documents (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    inquiry_id BIGINT NOT NULL REFERENCES inquiries(id) ON DELETE CASCADE,
    document_type VARCHAR(50) NOT NULL CHECK (
        document_type IN ('government_id', 'proof_of_income', 'other')
    ),
    file_name VARCHAR(255) NULL,
    file_url VARCHAR(500) NULL,
    file_size_mb DECIMAL(5, 2) NULL CHECK (file_size_mb <= 5.00),
    status VARCHAR(30) DEFAULT 'not_uploaded' CHECK (
        status IN ('not_uploaded', 'submitted', 'under_review', 'verified', 'rejected')
    ),
    remarks TEXT NULL,
    uploaded_at TIMESTAMPTZ NULL
);


CREATE TABLE inquiry_status_history (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    inquiry_id BIGINT NOT NULL REFERENCES inquiries(id) ON DELETE CASCADE,
    status VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    changed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE notifications (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    message TEXT NOT NULL,
    reference_type VARCHAR(50) NULL, 
    reference_id BIGINT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user_read ON notifications (user_id, is_read);
