-- ===============================================
-- TENDER DOCUMENT TYPE TABLE - STANDARDIZED & CLEAN
-- For project: https://fljvxaqqxlioxljkchte.supabase.co
-- Reference table for categorizing document types - German localized
-- ===============================================

CREATE TABLE tender_document_types (
    -- Primary Key & Timestamps
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Basic Information
    title TEXT NOT NULL UNIQUE, -- Document type name
    description TEXT, -- Detailed description
    
    -- Classification
    category TEXT, -- Free text for flexible categorization
    
    -- Document Properties
    is_required BOOLEAN DEFAULT false, -- Whether this type is mandatory for tenders
    expected_criteria_count INTEGER, -- Typical number of criteria found in this type
    
    -- Processing Configuration
    auto_extract_criteria BOOLEAN DEFAULT true, -- Whether to automatically extract criteria
    requires_manual_review BOOLEAN DEFAULT false, -- Whether documents of this type need manual review
    
    -- Display & UI
    display_order INTEGER, -- Order to show in UI lists
    
    -- Status
    is_active BOOLEAN DEFAULT true, -- Whether this type is currently used
    
    -- Flexible metadata for future extensions
    metadata JSONB DEFAULT '{}'
);

-- ===============================================
-- POPULATE WITH COMMON DOCUMENT TYPES (GERMAN)
-- ===============================================

INSERT INTO tender_document_types (title, description, category, is_required, expected_criteria_count, display_order) VALUES
('Technische Spezifikationen', 'Detaillierte technische Anforderungen und Spezifikationen', 'technisch', true, 15, 1),
('Allgemeine Geschäftsbedingungen', 'Rechtliche Bedingungen, Konditionen und Vertragsanforderungen', 'rechtlich', true, 8, 2),
('Einreichungsrichtlinien', 'Anweisungen für die Angebotsabgabe und Formatanforderungen', 'administrativ', true, 5, 3),
('Bewertungskriterien', 'Bewertungsmethodiki und Details zu den Bewertungskriterien', 'kommerziell', true, 12, 4),
('Kommerzielle Anforderungen', 'Preisstruktur, Zahlungsbedingungen und kommerzielle Konditionen', 'kommerziell', true, 6, 5),
('Leistungsumfang', 'Detaillierte Beschreibung der zu erbringenden Arbeiten', 'technisch', true, 10, 6),
('Hintergrundinformationen', 'Projektkontext, Hintergrund und ergänzende Informationen', 'ergänzend', false, 2, 7),
('Formulare und Vorlagen', 'Erforderliche Formulare, Vorlagen und Einreichungsformate', 'administrativ', false, 1, 8),
('Anhänge', 'Unterstützende Dokumente, Diagramme und Referenzmaterialien', 'ergänzend', false, 0, 9),
('Änderungsmitteilung', 'Änderungen, Korrekturen oder Updates zur ursprünglichen Ausschreibung', 'administrativ', false, 3, 10);

-- ===============================================
-- INDEXES FOR PERFORMANCE
-- ===============================================

-- Essential indexes
CREATE INDEX idx_tender_document_types_category ON tender_document_types(category);
CREATE INDEX idx_tender_document_types_is_required ON tender_document_types(is_required) WHERE is_required = true;
CREATE INDEX idx_tender_document_types_is_active ON tender_document_types(is_active) WHERE is_active = true;

-- UI and display indexes
CREATE INDEX idx_tender_document_types_display_order ON tender_document_types(display_order) WHERE display_order IS NOT NULL;
CREATE UNIQUE INDEX idx_tender_document_types_title_active ON tender_document_types(title) WHERE is_active = true;

-- ===============================================
-- TRIGGERS
-- ===============================================

-- Auto-update timestamp
CREATE TRIGGER update_tender_document_types_updated_at 
    BEFORE UPDATE ON tender_document_types
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ===============================================
-- UTILITY FUNCTIONS
-- ===============================================

-- Function to get document types for a specific category
CREATE OR REPLACE FUNCTION get_document_types_by_category(category_filter TEXT)
RETURNS TABLE (
    id BIGINT,
    title TEXT,
    description TEXT,
    is_required BOOLEAN,
    expected_criteria_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dt.id,
        dt.title,
        dt.description,
        dt.is_required,
        dt.expected_criteria_count
    FROM tender_document_types dt
    WHERE 
        dt.category = category_filter
        AND dt.is_active = true
    ORDER BY dt.display_order ASC, dt.title ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get required document types
CREATE OR REPLACE FUNCTION get_required_document_types()
RETURNS TABLE (
    id BIGINT,
    title TEXT,
    description TEXT,
    category TEXT,
    expected_criteria_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dt.id,
        dt.title,
        dt.description,
        dt.category,
        dt.expected_criteria_count
    FROM tender_document_types dt
    WHERE 
        dt.is_required = true
        AND dt.is_active = true
    ORDER BY dt.display_order ASC, dt.title ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to suggest document type based on filename/content
CREATE OR REPLACE FUNCTION suggest_document_type(
    filename TEXT,
    content_keywords TEXT[] DEFAULT NULL
)
RETURNS BIGINT AS $$
DECLARE
    suggested_type_id BIGINT;
    filename_lower TEXT := LOWER(filename);
BEGIN
    -- Simple filename-based suggestions (German keywords)
    IF filename_lower LIKE '%spezifikation%' OR filename_lower LIKE '%technisch%' OR filename_lower LIKE '%tech%' THEN
        SELECT id INTO suggested_type_id FROM tender_document_types 
        WHERE title = 'Technische Spezifikationen' AND is_active = true;
    ELSIF filename_lower LIKE '%bedingung%' OR filename_lower LIKE '%agb%' OR filename_lower LIKE '%vertrag%' OR filename_lower LIKE '%terms%' THEN
        SELECT id INTO suggested_type_id FROM tender_document_types 
        WHERE title = 'Allgemeine Geschäftsbedingungen' AND is_active = true;
    ELSIF filename_lower LIKE '%richtlinie%' OR filename_lower LIKE '%anweisung%' OR filename_lower LIKE '%einreichung%' OR filename_lower LIKE '%guideline%' THEN
        SELECT id INTO suggested_type_id FROM tender_document_types 
        WHERE title = 'Einreichungsrichtlinien' AND is_active = true;
    ELSIF filename_lower LIKE '%bewertung%' OR filename_lower LIKE '%kriterien%' OR filename_lower LIKE '%scoring%' OR filename_lower LIKE '%evaluation%' THEN
        SELECT id INTO suggested_type_id FROM tender_document_types 
        WHERE title = 'Bewertungskriterien' AND is_active = true;
    ELSIF filename_lower LIKE '%kommerziell%' OR filename_lower LIKE '%preis%' OR filename_lower LIKE '%zahlung%' OR filename_lower LIKE '%commercial%' THEN
        SELECT id INTO suggested_type_id FROM tender_document_types 
        WHERE title = 'Kommerzielle Anforderungen' AND is_active = true;
    ELSIF filename_lower LIKE '%leistung%' OR filename_lower LIKE '%umfang%' OR filename_lower LIKE '%arbeit%' OR filename_lower LIKE '%scope%' THEN
        SELECT id INTO suggested_type_id FROM tender_document_types 
        WHERE title = 'Leistungsumfang' AND is_active = true;
    ELSIF filename_lower LIKE '%formular%' OR filename_lower LIKE '%vorlage%' OR filename_lower LIKE '%template%' OR filename_lower LIKE '%form%' THEN
        SELECT id INTO suggested_type_id FROM tender_document_types 
        WHERE title = 'Formulare und Vorlagen' AND is_active = true;
    ELSIF filename_lower LIKE '%änderung%' OR filename_lower LIKE '%update%' OR filename_lower LIKE '%korrektur%' OR filename_lower LIKE '%amendment%' THEN
        SELECT id INTO suggested_type_id FROM tender_document_types 
        WHERE title = 'Änderungsmitteilung' AND is_active = true;
    ELSIF filename_lower LIKE '%anhang%' OR filename_lower LIKE '%attachment%' OR filename_lower LIKE '%anlage%' THEN
        SELECT id INTO suggested_type_id FROM tender_document_types 
        WHERE title = 'Anhänge' AND is_active = true;
    ELSE
        -- Default to Hintergrundinformationen for unknown types
        SELECT id INTO suggested_type_id FROM tender_document_types 
        WHERE title = 'Hintergrundinformationen' AND is_active = true;
    END IF;
    
    RETURN suggested_type_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===============================================
-- ROW LEVEL SECURITY
-- ===============================================

ALTER TABLE tender_document_types ENABLE ROW LEVEL SECURITY;

-- Basic policy for service role
CREATE POLICY "Allow all for service role" ON tender_document_types FOR ALL TO service_role USING (true);

-- Read-only policy for authenticated users (adjust based on your auth needs)
CREATE POLICY "Allow read for authenticated users" ON tender_document_types FOR SELECT TO authenticated USING (is_active = true);

-- ===============================================
-- COMMENTS FOR DOCUMENTATION
-- ===============================================

COMMENT ON TABLE tender_document_types IS 'Reference table for categorizing different types of tender documents with German localization';
COMMENT ON COLUMN tender_document_types.title IS 'Unique name for the document type';
COMMENT ON COLUMN tender_document_types.description IS 'Detailed description of what this document type contains';
COMMENT ON COLUMN tender_document_types.category IS 'Free text classification of document type';
COMMENT ON COLUMN tender_document_types.is_required IS 'Whether documents of this type are mandatory for tenders';
COMMENT ON COLUMN tender_document_types.expected_criteria_count IS 'Typical number of criteria found in documents of this type';
COMMENT ON COLUMN tender_document_types.auto_extract_criteria IS 'Whether to automatically extract criteria from documents of this type';
COMMENT ON COLUMN tender_document_types.display_order IS 'Order to display this type in UI lists';