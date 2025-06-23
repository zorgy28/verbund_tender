-- ===============================================
-- TENDER DOCUMENT IMAGES TABLE - CLEAN NORMALIZED ARCHITECTURE
-- For project: https://fljvxaqqxlioxljkchte.supabase.co
-- Images extracted from tender documents during parsing
-- ===============================================

CREATE TABLE tender_document_images (
    -- Primary Key & Timestamps
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Clean Normalized Relationships
    -- NOTE: tender_id removed for clean normalization
    -- tender_id is derivable via: tender_document_id → tender_documents → tender_id
    tender_document_id BIGINT NOT NULL REFERENCES tender_documents(id) ON DELETE CASCADE,
    
    -- Image Information
    image_path TEXT NOT NULL, -- Path/URL to image
    original_filename TEXT, -- Original image filename
    alt_text TEXT, -- Accessibility alt text
    caption TEXT, -- Image caption/title
    
    -- Image Properties
    width INTEGER,
    height INTEGER,
    file_size BIGINT,
    mimetype TEXT, -- image/png, image/jpeg, etc.
    
    -- Content & Context
    description TEXT, -- AI-generated description
    document_section TEXT, -- Which section/page
    page_number INTEGER, -- Specific page where image appears
    
    -- Image Classification
    image_type TEXT CHECK (image_type IN (
        'diagram', 'chart', 'photo', 'logo', 'signature', 'form', 'table', 'map', 'other'
    )),
    
    -- AI Analysis
    importance_score DECIMAL(3,2), -- 0.00 to 1.00 importance rating
    confidence_score DECIMAL(3,2), -- AI confidence in classification
    
    -- Flexible metadata for future extensions
    metadata JSONB DEFAULT '{}'
);

-- ===============================================
-- INDEXES FOR PERFORMANCE
-- ===============================================

-- Essential indexes
CREATE INDEX idx_tender_document_images_document_id ON tender_document_images(tender_document_id);
CREATE INDEX idx_tender_document_images_type ON tender_document_images(image_type);

-- Image properties indexes
CREATE INDEX idx_tender_document_images_mimetype ON tender_document_images(mimetype);
CREATE INDEX idx_tender_document_images_file_size ON tender_document_images(file_size) WHERE file_size IS NOT NULL;

-- Content indexes
CREATE INDEX idx_tender_document_images_document_section ON tender_document_images(document_section) WHERE document_section IS NOT NULL;
CREATE INDEX idx_tender_document_images_page_number ON tender_document_images(page_number) WHERE page_number IS NOT NULL;

-- AI Analysis indexes
CREATE INDEX idx_tender_document_images_importance ON tender_document_images(importance_score) WHERE importance_score IS NOT NULL;

-- Composite indexes for common queries
CREATE INDEX idx_tender_document_images_document_type ON tender_document_images(tender_document_id, image_type);
CREATE INDEX idx_tender_document_images_document_page ON tender_document_images(tender_document_id, page_number) WHERE page_number IS NOT NULL;

-- ===============================================
-- TRIGGERS
-- ===============================================

-- Auto-update timestamp
CREATE TRIGGER update_tender_document_images_updated_at 
    BEFORE UPDATE ON tender_document_images
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ===============================================
-- CONSTRAINTS & VALIDATIONS
-- ===============================================

-- Ensure image dimensions are positive
ALTER TABLE tender_document_images ADD CONSTRAINT chk_image_width_positive 
    CHECK (width IS NULL OR width > 0);

ALTER TABLE tender_document_images ADD CONSTRAINT chk_image_height_positive 
    CHECK (height IS NULL OR height > 0);

-- Ensure file_size is positive
ALTER TABLE tender_document_images ADD CONSTRAINT chk_image_file_size_positive 
    CHECK (file_size IS NULL OR file_size > 0);

-- Ensure page_number is positive
ALTER TABLE tender_document_images ADD CONSTRAINT chk_page_number_positive 
    CHECK (page_number IS NULL OR page_number > 0);

-- Ensure scores are in valid range (0.00 to 1.00)
ALTER TABLE tender_document_images ADD CONSTRAINT chk_importance_score_range 
    CHECK (importance_score IS NULL OR (importance_score >= 0.00 AND importance_score <= 1.00));

ALTER TABLE tender_document_images ADD CONSTRAINT chk_confidence_score_range 
    CHECK (confidence_score IS NULL OR (confidence_score >= 0.00 AND confidence_score <= 1.00));

-- ===============================================
-- COMMENTS FOR DOCUMENTATION
-- ===============================================

COMMENT ON TABLE tender_document_images IS 'Images extracted from tender documents during parsing - clean normalized relationships';
COMMENT ON COLUMN tender_document_images.tender_document_id IS 'Direct reference to source document (tender_id derivable via JOIN)';
COMMENT ON COLUMN tender_document_images.image_path IS 'Storage path/URL to the image file';
COMMENT ON COLUMN tender_document_images.description IS 'AI-generated description of image content';
COMMENT ON COLUMN tender_document_images.document_section IS 'Section/chapter where image appears in document';
COMMENT ON COLUMN tender_document_images.importance_score IS 'AI-calculated importance rating from 0.00 to 1.00';
COMMENT ON COLUMN tender_document_images.confidence_score IS 'AI confidence in image classification and analysis';

-- ===============================================
-- UTILITY FUNCTIONS FOR NORMALIZED QUERIES
-- ===============================================

-- Function to get tender_id for images (since it's normalized away)
CREATE OR REPLACE FUNCTION get_tender_id_for_image(p_image_id BIGINT)
RETURNS BIGINT AS $$
BEGIN
    RETURN (
        SELECT td.tender_id 
        FROM tender_document_images tdi
        JOIN tender_documents td ON td.id = tdi.tender_document_id
        WHERE tdi.id = p_image_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get all images for a tender (via normalized relationship)
CREATE OR REPLACE FUNCTION get_tender_images(p_tender_id BIGINT)
RETURNS TABLE (
    image_id BIGINT,
    image_path TEXT,
    image_type TEXT,
    document_name TEXT,
    page_number INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        tdi.id as image_id,
        tdi.image_path,
        tdi.image_type,
        td.file_name as document_name,
        tdi.page_number
    FROM tender_document_images tdi
    JOIN tender_documents td ON td.id = tdi.tender_document_id
    WHERE td.tender_id = p_tender_id
    ORDER BY td.file_name, tdi.page_number NULLS LAST;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;