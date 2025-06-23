-- ===============================================
-- TENDER DOCUMENTS TABLE - STANDARDIZED & CLEAN ARCHITECTURE
-- For project: https://fljvxaqqxlioxljkchte.supabase.co
-- ===============================================

CREATE TABLE tender_documents (
    -- Primary Key & Timestamps
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Relationships
    tender_id BIGINT NOT NULL REFERENCES tenders(id) ON DELETE CASCADE,
    document_type_id BIGINT REFERENCES tender_document_types(id) ON DELETE SET NULL,
    
    -- File Information (Standardized Names)
    file_name TEXT NOT NULL,
    original_filename TEXT, -- Store original name if renamed
    file_path TEXT, -- Storage path/URL to original file
    extracted_uri TEXT, -- Path to extracted content
    metadata_uri TEXT, -- Path to metadata
    
    -- File Properties (Standardized Names)
    file_size BIGINT, -- File size in bytes
    mimetype TEXT,
    page_count INTEGER, -- Number of pages (for PDFs)
    document_hash TEXT, -- Content hash for integrity
    
    -- Content
    summary TEXT, -- AI-generated summary
    
    -- Processing State
    process_state TEXT DEFAULT 'uploaded', -- Flexible text for app workflow
    
    -- Document Classification
    document_type TEXT, -- requirements, specifications, terms, etc. (legacy field)
    importance_level TEXT, -- high, medium, low
    
    -- Processing Metadata
    company TEXT, -- Company that uploaded/manages this
    manager_user UUID, -- Supabase user who uploaded/manages
    
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
CREATE INDEX idx_tender_documents_document_type_id ON tender_documents(document_type_id) WHERE document_type_id IS NOT NULL;
CREATE INDEX idx_tender_documents_process_state ON tender_documents(process_state);
CREATE INDEX idx_tender_documents_mimetype ON tender_documents(mimetype);
CREATE INDEX idx_tender_documents_document_type ON tender_documents(document_type);

-- File management indexes
CREATE INDEX idx_tender_documents_file_name ON tender_documents(file_name);
CREATE INDEX idx_tender_documents_file_size ON tender_documents(file_size) WHERE file_size IS NOT NULL;
CREATE INDEX idx_tender_documents_document_hash ON tender_documents(document_hash) WHERE document_hash IS NOT NULL;

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

-- Ensure page_count is positive
ALTER TABLE tender_documents ADD CONSTRAINT chk_page_count_positive 
    CHECK (page_count IS NULL OR page_count > 0);

-- Ensure retry_count is non-negative
ALTER TABLE tender_documents ADD CONSTRAINT chk_retry_count_non_negative 
    CHECK (retry_count >= 0);

-- Ensure processing timeline makes sense
ALTER TABLE tender_documents ADD CONSTRAINT chk_processing_timeline
    CHECK (processing_completed_at IS NULL OR processing_started_at IS NULL OR processing_completed_at >= processing_started_at);

-- ===============================================
-- COMMENTS FOR DOCUMENTATION
-- ===============================================

COMMENT ON TABLE tender_documents IS 'Documents associated with tenders - PDFs, Word docs, etc. with standardized field names';
COMMENT ON COLUMN tender_documents.file_path IS 'Storage path/URL to the original document file';
COMMENT ON COLUMN tender_documents.extracted_uri IS 'Location of extracted text content';
COMMENT ON COLUMN tender_documents.metadata_uri IS 'Location of document metadata';
COMMENT ON COLUMN tender_documents.process_state IS 'Flexible application state for document processing pipeline';
COMMENT ON COLUMN tender_documents.file_size IS 'File size in bytes';
COMMENT ON COLUMN tender_documents.page_count IS 'Number of pages in the document';
COMMENT ON COLUMN tender_documents.document_hash IS 'Content hash for file integrity verification';
COMMENT ON COLUMN tender_documents.summary IS 'AI-generated document summary';
COMMENT ON COLUMN tender_documents.manager_user IS 'Supabase UUID of user who uploaded/manages this document';
COMMENT ON COLUMN tender_documents.document_type_id IS 'Foreign key reference to tender_document_types for proper classification';