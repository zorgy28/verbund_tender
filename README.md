# Verbund AI Tender Management - Database Schema v2.0

This repository contains the optimized Supabase database schema for the Verbund AI Tender Management system.

## 🏗️ **Architecture Overview**

**Target Supabase Project**: `https://fljvxaqqxlioxljkchte.supabase.co`

**Key Improvements over v1.0:**
- ✅ Standardized naming conventions (snake_case)
- ✅ Proper data types and constraints
- ✅ Optimized indexes for performance
- ✅ Centralized vector storage approach
- ✅ Flexible process state management
- ✅ Proper foreign key relationships

## 📊 **Database Tables**

### **Core Tables**

| Table | Status | Description |
|-------|--------|-------------|
| `tenders` | ✅ **Finalized** | Main tender/procurement opportunities |
| `tender_documents` | ✅ **Finalized** | Documents associated with tenders |
| `tender_images` | ✅ **Finalized** | Images extracted from documents |
| `tender_document_types` | ✅ **Finalized** | German localized document type classification |
| `tender_criteria` | 🔄 **In Progress** | Evaluation criteria and requirements |

### **Planned Tables**

| Table | Status | Description |
|-------|--------|-------------|
| `offers` | 📋 **Planned** | Bid proposals from companies |
| `offer_documents` | 📋 **Planned** | Documents in offer submissions |
| `offer_images` | 📋 **Planned** | Images from offer documents |
| `companies` | 📋 **Planned** | Centralized company management |
| `embeddings` | 📋 **Planned** | Unified vector storage (Mistral) |
| `chat_sessions` | 📋 **Planned** | AI chat session management |
| `chat_messages` | 📋 **Planned** | Chat conversation history |

## 🚀 **Deployment Instructions**

### **1. Setup New Supabase Project**

```bash
# Connect to target project
npx supabase link --project-ref fljvxaqqxlioxljkchte

# Run schema files in order
psql $DATABASE_URL -f database/01_tenders.sql
psql $DATABASE_URL -f database/02_tender_documents.sql
psql $DATABASE_URL -f database/03_tender_images.sql
psql $DATABASE_URL -f database/04_tender_document_types.sql
```

### **2. Enable Required Extensions**

```sql
-- Enable in Supabase Dashboard > Database > Extensions
CREATE EXTENSION IF NOT EXISTS "vector" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;
```

### **3. Setup Row Level Security**

```sql
-- Enable RLS on all tables
ALTER TABLE tenders ENABLE ROW LEVEL SECURITY;
ALTER TABLE tender_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE tender_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE tender_document_types ENABLE ROW LEVEL SECURITY;

-- Basic policies (adjust based on auth requirements)
CREATE POLICY "Allow all for service role" ON tenders FOR ALL TO service_role USING (true);
CREATE POLICY "Allow all for service role" ON tender_documents FOR ALL TO service_role USING (true);
CREATE POLICY "Allow all for service role" ON tender_images FOR ALL TO service_role USING (true);
CREATE POLICY "Allow all for service role" ON tender_document_types FOR ALL TO service_role USING (true);
```

## 🔧 **Schema Design Principles**

### **Naming Conventions**
- **Tables**: `snake_case` (e.g., `tender_documents`)
- **Columns**: `snake_case` (e.g., `created_at`, `file_size`)
- **Indexes**: `idx_table_column` (e.g., `idx_tenders_status`)
- **Constraints**: `chk_description` (e.g., `chk_file_size_positive`)

### **Data Types**
- **IDs**: `BIGINT GENERATED ALWAYS AS IDENTITY`
- **Timestamps**: `TIMESTAMPTZ NOT NULL DEFAULT NOW()`
- **Money**: `DECIMAL(15,2)` for precise financial calculations
- **Scores**: `DECIMAL(3,2)` for 0.00-1.00 ranges
- **User References**: `UUID` for Supabase auth integration
- **Flexible Fields**: `JSONB` for metadata
- **State Management**: `TEXT` (no constraints) for app flexibility

### **Performance Optimizations**
- **Essential indexes** on FK columns, status fields, and timestamps
- **Composite indexes** for common query patterns
- **Partial indexes** with WHERE clauses for filtered queries
- **Proper constraints** for data integrity
- **Auto-updating timestamps** via triggers

## 🔄 **Migration from v1.0**

### **Field Mappings**

| v1.0 Field | v2.0 Field | Changes |
|------------|------------|---------|
| `isActive` | `is_active` | snake_case |
| `createdAt` | `created_at` | snake_case |
| `updatedAt` | `updated_at` | snake_case |
| `size` | `file_size` | More specific |
| `process_status` | `process_state` | Flexible text |

## 🎛️ **Key Features**

### **Flexible State Management**
- `process_state` fields accept any text for app flexibility
- No rigid CHECK constraints on processing states
- Allows dynamic workflow states like:
  - `"uploading_file_1_of_5"`
  - `"mistral_embedding_generation_started"`
  - `"error_pdf_corrupted"`

### **Proper Foreign Keys**
- Cascading deletes for data consistency
- Reference integrity between tenders, documents, and images
- UUID references for Supabase user management

### **Search Optimization**
- Full-text search vectors removed from main tables
- Centralized vector storage in separate `embeddings` table
- Hybrid search approach with Mistral embeddings

### **German Localization**
- `tender_document_types` table with German document types
- Smart filename detection for both German and English keywords
- Pre-populated with 10 common document types in German

---

**Last Updated**: June 23, 2025  
**Schema Version**: v2.0  
**Target Project**: fljvxaqqxlioxljkchte.supabase.co