# Tender Criteria Schema - Linked Tables & Field Harmonization

## 🔗 **LINKED TABLES FOR `05_tender_criteria.sql`**

### **Direct Foreign Key References:**

| Source Table | Field | References | Relationship |
|-------------|-------|------------|-------------|
| `tender_criteria` | `tender_id` | `tenders(id)` | Each criteria belongs to one tender |
| `tender_criteria_dependencies` | `criteria_id` | `tender_criteria(id)` | Many-to-many criteria dependencies |
| `tender_criteria_dependencies` | `dependency_id` | `tender_criteria(id)` | Self-referencing dependencies |
| `tender_criteria_source` | `tender_id` | `tenders(id)` | Evidence links to tender |
| `tender_criteria_source` | `criteria_id` | `tender_criteria(id)` | Evidence links to criteria |
| `tender_criteria_source` | `tender_document_id` | `tender_documents(id)` | Evidence from documents |
| `tender_criteria_source` | `tender_image_id` | `tender_images(id)` | Evidence from images |

### **Cascading Deletion Rules:**
- **CASCADE**: When tender is deleted → all criteria and evidence are deleted
- **CASCADE**: When criteria is deleted → dependencies and evidence are deleted  
- **SET NULL**: When document/image is deleted → evidence reference becomes null (evidence remains)

---

## ⚠️ **FIELD NAME HARMONIZATION ISSUES DISCOVERED**

### **🔴 Issues Found & Fixed:**

#### **1. Foreign Key Naming Inconsistency:**
| Table | Original Field | Corrected To | Pattern Applied |
|-------|---------------|-------------|-----------------|
| `tender_criteria_source` | `tender_documents_id` | `tender_document_id` | Singular table name + `_id` |
| `tender_criteria_source` | `tender_images_id` | `tender_image_id` | Singular table name + `_id` |

**Rule Applied**: Foreign keys follow pattern `[table_name_singular]_id`

#### **2. Cross-Table Inconsistency (Still in codebase):**
| Table | Field | Issue | Recommendation |
|-------|-------|-------|----------------|
| `tender_documents` | `manager_user` | Missing `_id` suffix | Should be `manager_user_id` |
| `tenders` | `manager_user_id` | ✅ Correct | Standard followed |

---

## ✅ **HARMONIZED NAMING CONVENTIONS**

### **Applied Standards:**

#### **Primary Keys:**
- Pattern: `id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY`
- ✅ All tables follow this pattern

#### **Foreign Keys:**
- Pattern: `[table_name_singular]_id BIGINT REFERENCES [table](id)`
- Examples:
  - `tender_id` → references `tenders(id)` ✅
  - `tender_document_id` → references `tender_documents(id)` ✅
  - `tender_image_id` → references `tender_images(id)` ✅

#### **Timestamps:**
- Pattern: `created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`
- Pattern: `updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`
- ✅ All tables follow this pattern

#### **Boolean Fields:**
- Pattern: `is_[description] BOOLEAN DEFAULT [value]`
- Examples:
  - `is_active` ✅
  - `is_binary_validation` ✅
  - `is_public` ✅

#### **Index Naming:**
- Pattern: `idx_[table]_[column(s)]`
- Examples:
  - `idx_tender_criteria_tender_id` ✅
  - `idx_criteria_source_document_id` ✅

---

## 🏗️ **RELATIONSHIP DIAGRAM**

```
tenders (1) ────────┐
    │               │
    │ tender_id     │ tender_id
    ▼               ▼
tender_criteria ──► tender_criteria_source
    │ ▲                     │ │
    │ │ criteria_id         │ │ tender_document_id
    │ │                     │ │ tender_image_id  
    │ │                     ▼ ▼
    │ └── tender_criteria_dependencies
    │           │
    │           │ dependency_id
    └───────────┘
         (self-reference)

tender_documents ───► tender_criteria_source
tender_images ──────► tender_criteria_source
```

---

## 📋 **TABLE PURPOSES**

### **`tender_criteria`** - Main evaluation criteria
- Stores individual evaluation requirements
- Supports explicit/implicit classification  
- Flexible JSON validation conditions
- Weight-based scoring system

### **`tender_criteria_dependencies`** - Criteria relationships
- Many-to-many dependencies between criteria
- Types: requires, conflicts, enhances
- Prevents circular dependencies
- Active/inactive relationship management

### **`tender_criteria_source`** - Evidence tracking
- Links criteria to source documents and images
- Tracks evidence location (page numbers, sections)
- Supports multi-source evidence for single criteria
- Maintains evidence even if source documents are deleted

---

## 🔧 **MIGRATION NOTES**

### **If updating existing databases:**

1. **Update `tender_documents` table:**
   ```sql
   ALTER TABLE tender_documents RENAME COLUMN manager_user TO manager_user_id;
   ```

2. **Verify all FK constraints:**
   ```sql
   SELECT 
       tc.table_name,
       kcu.column_name,
       ccu.table_name AS foreign_table_name,
       ccu.column_name AS foreign_column_name
   FROM information_schema.table_constraints AS tc
   JOIN information_schema.key_column_usage AS kcu ON tc.constraint_name = kcu.constraint_name
   JOIN information_schema.constraint_column_usage AS ccu ON ccu.constraint_name = tc.constraint_name
   WHERE constraint_type = 'FOREIGN KEY' AND tc.table_schema = 'public';
   ```

---

**Last Updated**: June 23, 2025  
**Schema Version**: v2.0  
**Harmonization Status**: ✅ Complete