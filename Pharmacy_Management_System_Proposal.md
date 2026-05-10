# Pharmacy Management System Proposal

## 1. Problem Statement
Small and independent retail pharmacies in India typically rely on manual paper‑based registers or basic spreadsheets to manage their daily operations. This leads to several critical problems:   

- **Inventory Chaos:** Expiry dates and batch numbers are tracked manually, resulting in frequent sale of expired medicines, stock‑outs of fast‑moving items, and over‑stocking of low‑demand drugs.
- **Slow Billing & Errors:** Without barcode scanning, the cashier types medicine names by hand, causing long queues, pricing mistakes, and incorrect tax calculations.
- **No Unified Data:** Customer purchase history, sales reports, and purchase records exist in scattered physical files or disparate Excel sheets. Generating GST‑ready reports or daily summaries is time‑consuming and error‑prone.
- **No Off‑site Backup:** In the event of computer failure, theft, or fire, all business data is lost permanently, as there is no automated, secure, off‑site backup mechanism.
- **Zero Cost–Sensitivity:** Most existing pharmacy software solutions require expensive monthly subscriptions, cloud hosting, or proprietary hardware that small shops cannot afford.
- **Limited Communication:** Sending invoices to customers via email, sharing sales data with an accountant, or exporting data for analysis is either impossible or involves a complicated manual process.

There is a clear need for a fully offline‑capable, zero‑operational‑cost pharmacy management system that automates billing, real‑time inventory tracking, batch‑wise stock control, and provides seamless online backup and data sharing without any recurring hosting fees.

## 2. Proposed Solution
We propose a cross‑platform desktop application built with Flutter that runs entirely on the shop’s local Windows PC. It stores all data in an embedded SQLite database and uses free, internet‑based services only for background backup, email delivery, and optional data export. The system’s key capabilities are divided into basic (core) and advanced features.

### 2.1 Core (Basic) Features

| Feature | Description |
|---|---|
| **Medicine Inventory Master** | CRUD for medicines with name, generic, category, manufacturer, HSN, GST rate, pack size, and barcode. |
| **Batch & Stock Tracking** | Each batch has its own expiry date, purchase price, MRP, selling price, and current quantity. Supports FIFO/nearest‑expiry dispensing. |
| **Barcode‑Driven Billing (POS)** | USB barcode scanner acts as keyboard input – instantly finds medicine and batch. Cart system with real‑time calculations (subtotal, discount, tax, grand total). |
| **Multi‑Payment Invoicing** | Supports cash, card, UPI, credit. Generates GST‑compliant PDF invoices with shop details, invoice number, item list, and tax breakup. |
| **Customer Management** | Store customer details (name, phone, email) and link past sales for quick refill or loyalty tracking. |
| **CSV Import/Export** | Bulk‑add medicines from CSV; export inventory, sales reports, or customer lists for external analysis. |
| **Email Reports & Invoices** | Send invoice PDF directly to customer’s email; email daily/monthly stock/sales reports to owner. |
| **Local Backup & Restore** | One‑click manual backup of the SQLite database; restore from any previous backup file. |

### 2.2 Advanced Features (Planned for Later Versions)
- **Expiry & Low‑Stock Dashboard:** Visual alerts with filters (30/60/90 days); automatic email alerts to owner.
- **Purchase & Supplier Management:** Record goods received, update stock and batch quantities, track payments to suppliers.
- **Sales Analytics & Graphs:** Daily/weekly turnover, top‑selling medicines, slow‑moving items, profit margin reports.
- **Prescription Image Upload & OCR:** Attach scanned/photographed prescriptions to sales; basic OCR to extract medicine names.
- **GST Report Generator:** GSTR‑1 summary, purchase register, sales register for direct filing.
- **Multi‑User Roles:** Admin, pharmacist, cashier with permission‑based access.
- **Barcode Label Printing:** For loose medicine strips – print small labels with batch, MRP, expiry.
- **Audit Trail:** Log every price change, stock adjustment, and sale edit with user and timestamp.
- **Mobile Companion App:** Let the owner check stock, sales, and expiry alerts from a mobile phone (using the same database synced via Google Drive or a local network).

### 2.3 The Zero‑Cost Online Backup & Data Transfer Strategy
The app uses Google Drive (free 15 GB storage) as an automated, off‑site backup destination. A Google Service Account (non‑human user) uploads an encrypted ZIP of the database daily. This requires no user interaction after initial one‑time setup. The same mechanism can be used to transfer data to another PC (just copy the latest backup and restore).
Email is handled via the shop’s existing Gmail account using SMTP (500 free emails/day), so there is no recurring server cost.

## 3. How We Are Going to Build This

### 3.1 Technology Stack (All Free & Open‑Source)

| Layer | Technology | Justification |
|---|---|---|
| **UI Framework** | Flutter 3.x (Dart) | Single codebase for Windows desktop, excellent performance, rich widget library. |
| **Database** | SQLite (via `sqflite_common_ffi`) | Zero‑configuration, embedded, ACID‑compliant, perfect for offline desktop apps. |
| **Barcode Input** | Raw keyboard listener (no plugin) | USB scanners behave like keyboards; works out‑of‑the‑box. |
| **PDF & Printing** | `pdf` + `printing` packages | Generate invoices; preview/print on regular or network printers. |
| **Thermal Printer** | `esc_pos_printer` (optional) | Direct USB/network printing for receipts. |
| **CSV Handling** | `csv` package + `file_picker` | Import/export data easily. |
| **Email Service** | `mailer` package (SMTP) | Send emails using Gmail’s free SMTP. |
| **Backup** | `googleapis` + `googleapis_auth` | Direct upload to Google Drive with service account. |
| **State Management** | `provider` or `riverpod` | Manage cart and UI states efficiently. |

### 3.2 System Architecture
```text
[ Flutter Windows Desktop App ]
        │
        ├── Local File System (SQLite DB, PDFs, CSV)
        ├── USB Barcode Scanner (Keyboard Wedge)
        ├── Printer (USB/Network)
        └── Internet (used only when explicitly triggered)
                │
                ├── Google Drive API → automated daily backup (no user login required)
                └── Gmail SMTP → send invoices & reports
```

### 3.3 Development Roadmap (12‑Day Demo Prototype)
A working prototype that showcases all core features will be built in a structured 12‑day sprint:

| Day | Focus | Deliverable |
|---|---|---|
| **1** | Project setup, SQLite schema, database helper | App launches, DB created with all tables |
| **2** | Medicine & batch CRUD screens | User can add/view medicines and batches |
| **3** | Barcode scan integration | Scan a barcode → medicine & batch fetched |
| **4** | Billing screen (cart logic, totals, tax) | Complete sale workflow, save to DB |
| **5** | PDF invoice generation & print preview | Invoice PDF shown on screen |
| **6** | Customer management & CSV export | Add customers, export sales to CSV |
| **7** | Email invoice via Gmail SMTP | Invoice sent as PDF attachment |
| **8** | Google Drive automated backup | Manual & scheduled backup with service account |
| **9** | Dashboard & navigation | Unified app with POS, Inventory, Reports tabs |
| **10** | Low‑stock & expiry alerts | Interactive alerts on dashboard |
| **11** | Realistic test data & UI polish | 50+ medicines, test sales, smooth flow |
| **12** | Build Windows release, finalize demo | Standalone `.exe`, demo script ready |

### 3.4 Why This Approach Works
- **True Offline Capability:** The shop can operate fully even without internet; billing and inventory do not depend on connectivity.
- **Zero Recurring Cost:** No server, no database hosting, no monthly fees – only a free Google account.
- **Data Safety:** Local SQLite database is backed up every night to the cloud; in case of PC failure, just install the app on a new machine and restore the latest backup.
- **Scalability:** The architecture can easily evolve to multi‑branch (syncing via the same Google Drive or a central DB later) without rewriting the core logic.
- **Rapid Prototyping:** Flutter’s hot reload allows fast iteration, making it possible to demonstrate a working billing system in under two weeks.

## 4. Future Scope
The current prototype and first release focus on a single‑shop, single‑PC scenario. The following enhancements are planned for subsequent phases:

- **Mobile Companion App (Android/iOS):** Using the same Flutter codebase, compile a mobile version that the owner can use to view daily sales, stock alerts, and expiry reports. The mobile app can fetch the latest backup file from Google Drive and present read‑only dashboards.
- **Multi‑Branch Synchronization:** For pharmacy chains, implement a central server (or use Firebase/Supabase free tier) that all branch apps sync with. The local‑first architecture remains; the app will push/pull changes when online.
- **Cloud‑Based Prescription Storage & Sharing:** Allow customers to upload prescriptions via a web portal; these are directly visible in the pharmacy’s inventory for quick dispensing.
- **AI‑Powered Demand Forecasting:** Analyse historical sales data to predict future stock requirements, optimise reorder quantities, and reduce wastage from expiry.
- **Integration with Online Medicine Aggregators:** Expose an API for third‑party delivery platforms (like PharmEasy, Netmeds) to push orders directly into the billing queue.
- **Voice‑Activated Dispensing:** Hands‑free barcode scanning and quantity entry using voice commands, especially useful for handling large volumes.
- **Blockchain‑Based Drug Traceability:** Track a medicine’s journey from manufacturer to patient, ensuring authenticity and regulatory compliance.

## 5. Conclusion
This project delivers a professional, reliable, and completely free‑to‑run pharmacy management system that addresses the critical needs of small Indian pharmacies. By leveraging Flutter and serverless cloud services exclusively for backup and email, the system provides a modern point‑of‑sale experience with zero operational overhead. The 12‑day prototype will demonstrate the complete billing lifecycle, inventory control, and data security, laying a strong foundation for future expansions.
