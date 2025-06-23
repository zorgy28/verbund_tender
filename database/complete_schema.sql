-- ===============================================
-- VERBUND AI TENDER MANAGEMENT - COMPLETE SCHEMA v2.0
-- For project: https://fljvxaqqxlioxljkchte.supabase.co
-- 
-- Deploy this file to create all tables at once
-- ===============================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "vector" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;

-- ===============================================
-- SHARED FUNCTIONS
-- ===============================================

-- Auto-update timestamp function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- ===============================================
-- 1. TENDERS TABLE
-- ===============================================

CREATE TABLE tenders (
    -- Primary Key & Timestamps
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Basic Information
    title TEXT NOT NULL,
    summary TEXT,
    context TEXT,
    
    -- Relationships
    company TEXT,
    manager_user_id UUID,
    contact_info TEXT,
    
    -- Timeline Fields
    due_date TIMESTAMPTZ,
    closing_date TIMESTAMPTZ,
    publication_date TIMESTAMPTZ,
    
    -- Submission Details
    submission_method TEXT,
    
    -- Budget Information
    budget_description TEXT,
    budget_estimation DECIMAL(15,2),
    budget_currency TEXT DEFAULT 'EUR',
    
    -- Access & Visibility
    is_public BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true,
    
    -- Processing State
    process_state TEXT DEFAULT 'pending',
    
    -- Business Status
    status TEXT DEFAULT 'draft' CHECK (status IN (
        'draft', 'review', 'published', 'accepting_submissions', 
        'submission_closed', 'evaluation', 'awarded', 'cancelled', 'archived'
    )),
    
    -- AI Analysis Results
    ai_summary TEXT,
    
    -- Categorization
    category TEXT,
    tender_type TEXT,
    
    -- Reference Numbers
    tender_number TEXT UNIQUE,
    reference_number TEXT,
    
    -- Flexible metadata
    metadata JSONB DEFAULT '{}'
);

-- Tenders indexes
CREATE INDEX idx_tenders_status ON tenders(status);
CREATE INDEX idx_tenders_process_state ON tenders(process_state);
CREATE INDEX idx_tenders_company ON tenders(company);
CREATE INDEX idx_tenders_is_active ON tenders(is_active) WHERE is_active = true;
CREATE INDEX idx_tenders_due_date ON tenders(due_date) WHERE due_date IS NOT NULL;
CREATE INDEX idx_tenders_publication_date ON tenders(publication_date);
CREATE INDEX idx_tenders_status_active ON tenders(status, is_active);
CREATE INDEX idx_tenders_company_status ON tenders(company, status) WHERE company IS NOT NULL;

-- Tenders triggers
CREATE TRIGGER update_tenders_updated_at 
    BEFORE UPDATE ON tenders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ===============================================
-- 2. TENDER DOCUMENTS TABLE
-- ===============================================

CREATE TABLE tender_documents (
    -- Primary Key & Timestamps
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Relationships
    tender_id BIGINT NOT NULL REFERENCES tenders(id) ON DELETE CASCADE,
    
    -- File Information
    file_name TEXT NOT NULL,
    original_filename TEXT,
    file_path_uri TEXT,
    extracted_uri TEXT,
    metadata_uri TEXT,
    
    -- File Properties
    file_size BIGINT,
    mimetype TEXT,
    n_pages INTEGER,
    
    -- Content
    summary TEXT,
    
    -- Processing State
    process_state TEXT DEFAULT 'uploaded',
    
    -- Document Classification
    document_type TEXT,
    importance_level TEXT,
    
    -- Processing Metadata
    company TEXT,
    manager_user UUID,
    
    -- Processing Timestamps
    processing_started_at TIMESTAMPTZ,
    processing_completed_at TIMESTAMPTZ,
    last_processed_at TIMESTAMPTZ,
    
    -- Error Handling
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    
    -- Document Properties
    language TEXT DEFAULT 'en',
    encoding TEXT,
    is_searchable BOOLEAN DEFAULT true,
    
    -- Flexible metadata
    metadata JSONB DEFAULT '{}'
);

-- Tender Documents indexes
CREATE INDEX idx_tender_documents_tender_id ON tender_documents(tender_id);
CREATE INDEX idx_tender_documents_process_state ON tender_documents(process_state);
CREATE INDEX idx_tender_documents_mimetype ON tender_documents(mimetype);
CREATE INDEX idx_tender_documents_document_type ON tender_documents(document_type);
CREATE INDEX idx_tender_documents_file_name ON tender_documents(file_name);
CREATE INDEX idx_tender_documents_file_size ON tender_documents(file_size) WHERE file_size IS NOT NULL;
CREATE INDEX idx_tender_documents_processing ON tender_documents(processing_started_at, processing_completed_at);
CREATE INDEX idx_tender_documents_manager ON tender_documents(manager_user) WHERE manager_user IS NOT NULL;
CREATE INDEX idx_tender_documents_tender_state ON tender_documents(tender_id, process_state);
CREATE INDEX idx_tender_documents_tender_type ON tender_documents(tender_id, document_type);

-- Tender Documents constraints
ALTER TABLE tender_documents ADD CONSTRAINT chk_file_size_positive 
    CHECK (file_size IS NULL OR file_size > 0);
ALTER TABLE tender_documents ADD CONSTRAINT chk_n_pages_positive 
    CHECK (n_pages IS NULL OR n_pages > 0);
ALTER TABLE tender_documents ADD CONSTRAINT chk_retry_count_non_negative 
    CHECK (retry_count >= 0);

-- Tender Documents triggers
CREATE TRIGGER update_tender_documents_updated_at 
    BEFORE UPDATE ON tender_documents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ===============================================
-- 3. TENDER IMAGES TABLE
-- ===============================================

CREATE TABLE tender_images (
    -- Primary Key & Timestamps
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Relationships
    tender_id BIGINT NOT NULL REFERENCES tenders(id) ON DELETE CASCADE,
    tender_document_id BIGINT REFERENCES tender_documents(id) ON DELETE CASCADE,
    
    -- Image Information
    image_path TEXT NOT NULL,
    original_filename TEXT,
    alt_text TEXT,
    caption TEXT,
    
    -- Image Properties
    width INTEGER,
    height INTEGER,
    file_size BIGINT,
    mimetype TEXT,
    
    -- Content & Context
    description TEXT,
    document_section TEXT,
    page_number INTEGER,
    
    -- Image Classification
    image_type TEXT CHECK (image_type IN (
        'diagram', 'chart', 'photo', 'logo', 'signature', 'form', 'table', 'map', 'other'
    )),
    
    -- AI Analysis
    importance_score DECIMAL(3,2),
    confidence_score DECIMAL(3,2),
    
    -- Flexible metadata
    metadata JSONB DEFAULT '{}'
);

-- Tender Images indexes
CREATE INDEX idx_tender_images_tender_id ON tender_images(tender_id);
CREATE INDEX idx_tender_images_document_id ON tender_images(tender_document_id) WHERE tender_document_id IS NOT NULL;
CREATE INDEX idx_tender_images_type ON tender_images(image_type);
CREATE INDEX idx_tender_images_mimetype ON tender_images(mimetype);
CREATE INDEX idx_tender_images_file_size ON tender_images(file_size) WHERE file_size IS NOT NULL;
CREATE INDEX idx_tender_images_document_section ON tender_images(document_section) WHERE document_section IS NOT NULL;
CREATE INDEX idx_tender_images_page_number ON tender_images(page_number) WHERE page_number IS NOT NULL;
CREATE INDEX idx_tender_images_importance ON tender_images(importance_score) WHERE importance_score IS NOT NULL;
CREATE INDEX idx_tender_images_tender_type ON tender_images(tender_id, image_type);
CREATE INDEX idx_tender_images_document_page ON tender_images(tender_document_id, page_number) WHERE tender_document_id IS NOT NULL;

-- Tender Images constraints
ALTER TABLE tender_images ADD CONSTRAINT chk_image_width_positive 
    CHECK (width IS NULL OR width > 0);
ALTER TABLE tender_images ADD CONSTRAINT chk_image_height_positive 
    CHECK (height IS NULL OR height > 0);
ALTER TABLE tender_images ADD CONSTRAINT chk_image_file_size_positive 
    CHECK (file_size IS NULL OR file_size > 0);
ALTER TABLE tender_images ADD CONSTRAINT chk_page_number_positive 
    CHECK (page_number IS NULL OR page_number > 0);
ALTER TABLE tender_images ADD CONSTRAINT chk_importance_score_range 
    CHECK (importance_score IS NULL OR (importance_score >= 0.00 AND importance_score <= 1.00));
ALTER TABLE tender_images ADD CONSTRAINT chk_confidence_score_range 
    CHECK (confidence_score IS NULL OR (confidence_score >= 0.00 AND confidence_score <= 1.00));

-- Tender Images triggers
CREATE TRIGGER update_tender_images_updated_at 
    BEFORE UPDATE ON tender_images
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ===============================================
-- ENABLE ROW LEVEL SECURITY
-- ===============================================

ALTER TABLE tenders ENABLE ROW LEVEL SECURITY;
ALTER TABLE tender_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE tender_images ENABLE ROW LEVEL SECURITY;

-- Basic policies for service role (adjust based on auth requirements)
CREATE POLICY "Allow all for service role" ON tenders FOR ALL TO service_role USING (true);
CREATE POLICY "Allow all for service role" ON tender_documents FOR ALL TO service_role USING (true);
CREATE POLICY "Allow all for service role" ON tender_images FOR ALL TO service_role USING (true);

-- ===============================================
-- TABLE COMMENTS
-- ===============================================

COMMENT ON TABLE tenders IS 'Main tenders/procurement opportunities table';
COMMENT ON COLUMN tenders.process_state IS 'Flexible application state for document processing and analysis pipeline';
COMMENT ON COLUMN tenders.status IS 'Business lifecycle status of the tender';

COMMENT ON TABLE tender_documents IS 'Documents associated with tenders - PDFs, Word docs, etc.';
COMMENT ON COLUMN tender_documents.file_path_uri IS 'Original file storage location/URL';
COMMENT ON COLUMN tender_documents.extracted_uri IS 'Location of extracted text content';
COMMENT ON COLUMN tender_documents.metadata_uri IS 'Location of document metadata';
COMMENT ON COLUMN tender_documents.process_state IS 'Flexible application state for document processing pipeline';
COMMENT ON COLUMN tender_documents.file_size IS 'File size in bytes';
COMMENT ON COLUMN tender_documents.summary IS 'AI-generated document summary';
COMMENT ON COLUMN tender_documents.manager_user IS 'Supabase UUID of user who uploaded/manages this document';

COMMENT ON TABLE tender_images IS 'Images extracted from tender documents - diagrams, charts, photos, etc.';
COMMENT ON COLUMN tender_images.image_path IS 'Storage path/URL to the image file';
COMMENT ON COLUMN tender_images.description IS 'AI-generated description of image content';
COMMENT ON COLUMN tender_images.document_section IS 'Section/chapter where image appears in document';
COMMENT ON COLUMN tender_images.importance_score IS 'AI-calculated importance rating from 0.00 to 1.00';
COMMENT ON COLUMN tender_images.confidence_score IS 'AI confidence in image classification and analysis';

-- ===============================================
-- DEPLOYMENT COMPLETE
-- ===============================================

-- Schema deployed successfully!
-- Next steps:
-- 1. Configure authentication policies
-- 2. Deploy edge functions
-- 3. Set up monitoring
-- 4. Begin data migration from v1.0
