-- ===============================================
-- TENDER DOCUMENTS TABLE - STANDARDIZED PROPOSAL
-- For project: https://fljvxaqqxlioxljkchte.supabase.co
-- ===============================================

CREATE TABLE tender_documents (
    -- Primary Key & Timestamps
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Relationships
    tender_id BIGINT NOT NULL REFERENCES tenders(id) ON DELETE CASCADE,
    
    -- File Information
    file_name TEXT NOT NULL, -- Your existing field
    original_filename TEXT, -- Store original name if renamed
    file_path_uri TEXT, -- Your existing field (path to original file)
    extracted_uri TEXT, -- Your existing field (path to extracted content)
    metadata_uri TEXT, -- Your existing field (path to metadata)
    
    -- File Properties
    file_size BIGINT, -- Renamed from 'size' for clarity
    mimetype TEXT, -- Your existing field
    n_pages INTEGER, -- Your existing field
    
    -- Content
    summary TEXT, -- Your existing field (AI-generated summary)
    
    -- Processing State
    process_state TEXT DEFAULT 'uploaded', -- Your existing field (flexible text)
    
    -- Document Classification
    document_type TEXT, -- requirements, specifications, terms, etc.
    importance_level TEXT, -- high, medium, low
    
    -- Processing Metadata
    company TEXT, -- Your existing field
    manager_user UUID, -- Your existing field (Supabase user who uploaded/manages)
    
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
    
    -- Flexible metadata for future extensions
    metadata JSONB DEFAULT '{}'
);

-- ===============================================
-- INDEXES FOR PERFORMANCE
-- ===============================================

-- Essential indexes
CREATE INDEX idx_tender_documents_tender_id ON tender_documents(tender_id);
CREATE INDEX idx_tender_documents_process_state ON tender_documents(process_state);
CREATE INDEX idx_tender_documents_mimetype ON tender_documents(mimetype);
CREATE INDEX idx_tender_documents_document_type ON tender_documents(document_type);

-- File management indexes
CREATE INDEX idx_tender_documents_file_name ON tender_documents(file_name);
CREATE INDEX idx_tender_documents_file_size ON tender_documents(file_size) WHERE file_size IS NOT NULL;

-- Processing indexes
CREATE INDEX idx_tender_documents_processing ON tender_documents(processing_started_at, processing_completed_at);
CREATE INDEX idx_tender_documents_manager ON tender_documents(manager_user) WHERE manager_user IS NOT NULL;

-- Composite indexes for common queries
CREATE INDEX idx_tender_documents_tender_state ON tender_documents(tender_id, process_state);
CREATE INDEX idx_tender_documents_tender_type ON tender_documents(tender_id, document_type);

-- ===============================================
-- TRIGGERS
-- ===============================================

-- Auto-update timestamp
CREATE TRIGGER update_tender_documents_updated_at 
    BEFORE UPDATE ON tender_documents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ===============================================
-- CONSTRAINTS & VALIDATIONS
-- ===============================================

-- Ensure file_size is positive
ALTER TABLE tender_documents ADD CONSTRAINT chk_file_size_positive 
    CHECK (file_size IS NULL OR file_size > 0);

-- Ensure n_pages is positive
ALTER TABLE tender_documents ADD CONSTRAINT chk_n_pages_positive 
    CHECK (n_pages IS NULL OR n_pages > 0);

-- Ensure retry_count is non-negative
ALTER TABLE tender_documents ADD CONSTRAINT chk_retry_count_non_negative 
    CHECK (retry_count >= 0);

-- ===============================================
-- COMMENTS FOR DOCUMENTATION
-- ===============================================

COMMENT ON TABLE tender_documents IS 'Documents associated with tenders - PDFs, Word docs, etc.';
COMMENT ON COLUMN tender_documents.file_path_uri IS 'Original file storage location/URL';
COMMENT ON COLUMN tender_documents.extracted_uri IS 'Location of extracted text content';
COMMENT ON COLUMN tender_documents.metadata_uri IS 'Location of document metadata';
COMMENT ON COLUMN tender_documents.process_state IS 'Flexible application state for document processing pipeline';
COMMENT ON COLUMN tender_documents.file_size IS 'File size in bytes';
COMMENT ON COLUMN tender_documents.summary IS 'AI-generated document summary';
COMMENT ON COLUMN tender_documents.manager_user IS 'Supabase UUID of user who uploaded/manages this document';
