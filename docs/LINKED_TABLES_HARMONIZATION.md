# Tender Criteria Schema - Linked Tables & Field Harmonization ✅ CORRECTED

## 🔗 **LINKED TABLES FOR `05_tender_criteria.sql`**

### **Direct Foreign Key References:**

| Source Table | Field | References | Relationship |
|-------------|-------|------------|-------------|
| `tender_criteria` | `tender_id` | `tenders(id)` | Each criteria belongs to one tender |
| `tender_criteria_dependencies` | `criteria_id` | `tender_criteria(id)` | Many-to-many criteria dependencies |
| `tender_criteria_dependencies` | `dependency_id` | `tender_criteria(id)` | Self-referencing dependencies |
| `tender_criteria_source` | `criteria_id` | `tender_criteria(id)` | Evidence links to criteria |
| `tender_criteria_source` | `tender_document_id` | `tender_documents(id)` | Evidence from documents |
| `tender_criteria_source` | `tender_document_image_id` | `tender_document_images(id)` | Evidence from extracted images |

### **Cascading Deletion Rules:**
- **CASCADE**: When tender is deleted → all criteria and evidence are deleted
- **CASCADE**: When criteria is deleted → dependencies and evidence are deleted  
- **SET NULL**: When document/image is deleted → evidence reference becomes null (evidence remains)

---

## ✅ **CORRECTED RELATIONSHIP MODEL**

### **🎯 Final Clean Architecture:**

```
Tenders (root)
├── Tender Documents (tender_id)
│   ├── → Document Types (document_type_id)
│   └── Tender Document Images (tender_document_id + tender_id)
│       └── [Extracted during parsing + Used as evidence]
│
├── Tender Criteria (tender_id)
│   ├── Tender Criteria Source (criteria_id) ← CLEAN: No redundant tender_id
│   │   ├── → Links to Tender Documents (document evidence)
│   │   └── → Links to Tender Document Images (image evidence) ✅
│   └── Tender Criteria Dependencies (criteria_id ↔ dependency_id)
│
└── Tender Document Types (standalone reference)
```

---

## 🔧 **CORRECTIONS IMPLEMENTED**

### **✅ FIXED Issues:**

#### **1. Table & Field Naming Clarity:**
| Original | Corrected | Reason |
|----------|-----------|--------|
| `tender_images` | `tender_document_images` | **Clear relationship** - images are FROM documents |
| `tender_image_id` | `tender_document_image_id` | **Consistent naming** with table |

#### **2. Clean Normalization:**
| Field | Action | Reason |
|-------|--------|--------|
| `tender_id` in `tender_criteria_source` | **REMOVED** | **Redundant** - derivable via `criteria_id → tender_criteria.tender_id` |

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
  - `tender_document_image_id` → references `tender_document_images(id)` ✅

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
  - `idx_criteria_source_document_image_id` ✅

---

## 🏗️ **CORRECTED RELATIONSHIP DIAGRAM**

```
tenders (1) ────────┐
    │               │
    │ tender_id     │ tender_id
    ▼               ▼
tender_criteria    tender_documents ──► tender_document_types
    │ ▲                     │                (document_type_id)
    │ │ criteria_id         │ tender_document_id
    │ │                     ▼
    │ │              tender_document_images
    │ │                     │
    │ │ tender_document_image_id
    │ │                     │
    │ └── tender_criteria_source ◄─────────┘
    │           │
    │           │ criteria_id
    │           ▼
    └─── tender_criteria_dependencies
              │
              │ dependency_id
              └─────┘ (self-reference)
```

---

## 📋 **TABLE PURPOSES**

### **`tender_document_images`** - Images extracted from documents
- **Clear naming** - Obviously related to documents
- Images extracted during document parsing
- Used as evidence sources for criteria evaluation
- Maintains both document and tender references for performance

### **`tender_criteria_source`** - Evidence tracking (CLEAN)
- **No redundant fields** - Clean normalization
- Links criteria to source documents and extracted images
- `tender_id` derivable via JOIN when needed
- Supports multi-source evidence for single criteria

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

---

## 🔧 **QUERY PATTERN CHANGES**

### **Evidence Queries (Updated):**

```sql
-- Get all evidence for a tender (via JOIN - clean normalization)
SELECT tcs.*, td.file_name, tdi.image_path
FROM tender_criteria_source tcs
JOIN tender_criteria tc ON tc.id = tcs.criteria_id
LEFT JOIN tender_documents td ON td.id = tcs.tender_document_id
LEFT JOIN tender_document_images tdi ON tdi.id = tcs.tender_document_image_id
WHERE tc.tender_id = 123;

-- Get evidence for specific criteria (direct)
SELECT * FROM tender_criteria_source WHERE criteria_id = 456;
```

---

## 📊 **FILES UPDATED**

### **✅ Schema Files:**
- **`database/03_tender_document_images.sql`** - New clear naming ✅
- **`database/05_tender_criteria.sql`** - Clean normalization ✅
- **Deleted**: `database/03_tender_images.sql` (replaced)

### **✅ Documentation:**
- **`README.md`** - Updated deployment instructions ✅
- **`docs/LINKED_TABLES_HARMONIZATION.md`** - This file ✅

### **✅ Benefits Achieved:**
- ✅ **Crystal clear relationships** - No confusion about image source
- ✅ **Clean normalization** - No redundant foreign keys
- ✅ **Consistent naming** - All fields follow patterns
- ✅ **Better maintainability** - Fewer constraints to manage
- ✅ **Proper hierarchy** - Documents → Images → Evidence

---

**Last Updated**: June 23, 2025  
**Schema Version**: v2.0 - **Corrected & Finalized**  
**Correction Status**: ✅ **Complete - Clean Architecture Achieved**