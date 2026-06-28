-- ═══════════════════════════════════════════════════════════════════════════
-- Steel & Aire Soluciones — Asset Class Requirements Seed
-- Run AFTER schema-v2.sql.
-- Idempotent: ON CONFLICT DO UPDATE so re-runs refresh the seed safely.
--
-- PHASE KEY:
--   0 = Intake          1 = Soft Quote
--   2 = Term Sheet      3 = Underwriting    4 = Closing
--
-- ASSUMPTIONS FLAGGED with [ASSUMPTION] — review and correct before go-live.
-- ═══════════════════════════════════════════════════════════════════════════


-- ─────────────────────────────────────────────────────────────────────────
-- 1. MULTIFAMILY
-- Bridge / construction / permanent debt + equity.
-- Based on standard agency/CMBS/bridge lender packages.
-- ─────────────────────────────────────────────────────────────────────────

INSERT INTO asset_class_requirements
  (asset_class, phase, group_name, doc_name, doc_sub, required, sort_order, notes)
VALUES

-- ── Phase 0: Intake ──
('multifamily', 0, 'Sponsor & Borrower',
  'Sponsor Bio / Track Record', 'Prior deals closed, exits, references, LinkedIn or deck',
  true, 10, NULL),

('multifamily', 0, 'Sponsor & Borrower',
  'Personal Financial Statement (PFS)', 'Current within 90 days, signed and dated',
  true, 20, NULL),

('multifamily', 0, 'Sponsor & Borrower',
  'Schedule of Real Estate Owned (REO)', 'All properties, debt balances, equity, and cash flow',
  true, 30, NULL),

('multifamily', 0, 'Property & Operations',
  'Current Rent Roll', 'Unit-level detail: unit, type, sq ft, lease start/end, current rent, market rent',
  true, 40, NULL),

('multifamily', 0, 'Property & Operations',
  'Property Photos / Condition Report', 'Interior, exterior, common areas, deferred maintenance visible',
  true, 50, NULL),

('multifamily', 0, 'Deal & Capital',
  'Executive Summary / OM', 'Deal narrative: asset description, business plan, return targets, sponsor background',
  true, 60, NULL),

('multifamily', 0, 'Deal & Capital',
  'Sources & Uses (Preliminary)', 'High-level capital stack — can be a one-pager at this stage',
  true, 70, NULL),

-- ── Phase 1: Soft Quote ──
('multifamily', 1, 'Sponsor & Borrower',
  'Credit Authorization', 'Signed authorization for credit pull — required before lender quotes',
  true, 100, NULL),

('multifamily', 1, 'Property & Operations',
  'T-12 Operating Statement', 'Trailing 12 months actual income & expenses, month-by-month columns',
  true, 110, NULL),

('multifamily', 1, 'Property & Operations',
  'Pro Forma', 'Stabilized projections with clearly stated assumptions',
  true, 120, NULL),

('multifamily', 1, 'Valuation & Market',
  'Broker Price Opinion (BPO)', 'Recent BPO with comparable sales and rent comps',
  true, 130, NULL),

('multifamily', 1, 'Valuation & Market',
  'Market Comps / Survey', 'Sales and rent comparables within the submarket',
  true, 140, NULL),

('multifamily', 1, 'Deal & Capital',
  'Sources & Uses (Detailed)', 'Full capital stack: senior debt, equity, mezz, reserves, closing costs — must balance',
  true, 150, NULL),

-- ── Phase 2: Term Sheet ──
('multifamily', 2, 'Sponsor & Borrower',
  'Entity Documents', 'Articles of organization, operating agreement, EIN letter for borrowing entity',
  true, 200, NULL),

('multifamily', 2, 'Property & Operations',
  'CapEx / Renovation Budget', 'Itemized scope, per-unit cost, timeline, contractor bids if available',
  false, 210, 'Required for bridge/value-add only; skip for stabilized perm loans.'),

('multifamily', 2, 'Deal & Capital',
  'Purchase Agreement / PSA', 'Executed contract if acquisition, including all addenda and extensions',
  false, 220, 'Required for acquisitions only; skip for refinances.'),

-- ── Phase 3: Underwriting ──
('multifamily', 3, 'Sponsor & Borrower',
  'Personal Tax Returns', 'Most recent 2–3 years, all pages and schedules',
  true, 300, NULL),

('multifamily', 3, 'Sponsor & Borrower',
  'Bank / Liquidity Statements', 'Most recent 2–3 months, all accounts',
  true, 310, NULL),

('multifamily', 3, 'Property & Operations',
  'Leases & Estoppels', 'Sample residential lease or all commercial leases; estoppels if required by lender',
  true, 320, NULL),

('multifamily', 3, 'Valuation & Market',
  'Appraisal (MAI)', 'Lender-ordered or recent third-party MAI appraisal — must be addressed to lender',
  true, 330, NULL),

('multifamily', 3, 'Valuation & Market',
  'Environmental Report (Phase I ESA)', 'Required by most institutional lenders; order early — takes 2–3 weeks',
  false, 340, 'Required for commercial/mixed-use; often waived on pure residential by some bridge lenders.'),

-- ── Phase 4: Closing ──
('multifamily', 4, 'Legal & Title',
  'Title Commitment', 'Preliminary title report from a lender-approved title company',
  true, 400, NULL),

('multifamily', 4, 'Legal & Title',
  'ALTA Survey', 'Lender-required boundary and improvement survey',
  false, 410, 'Required by most agency/CMBS lenders; some bridge lenders waive.'),

('multifamily', 4, 'Legal & Title',
  'Insurance Binder / Quote', 'Evidence of property & casualty coverage at lender-required limits',
  true, 420, NULL),

('multifamily', 4, 'Sponsor & Borrower',
  'Personal Tax Returns (current year)', 'Most recent filed return if underwriting spanned a fiscal year',
  false, 430, 'Only required if original returns are more than 12 months old at closing.'),


-- ─────────────────────────────────────────────────────────────────────────
-- 2. DATA CENTER
-- Hyperscale / colocation / edge — debt + equity, often §48C tax credit stacking.
--
-- [ASSUMPTION] Mixed colocation model assumed. Adjust if primarily hyperscale:
--   - Hyperscale: anchor tenant pre-lease is typically executed (not LOI) at Phase 1
--   - Edge: may not require interconnection agreement; focus on latency/power density
-- [ASSUMPTION] §48C energy community credit included; remove if not applicable.
-- ─────────────────────────────────────────────────────────────────────────

INSERT INTO asset_class_requirements
  (asset_class, phase, group_name, doc_name, doc_sub, required, sort_order, notes)
VALUES

-- ── Phase 0: Intake ──
('data_center', 0, 'Sponsor & Developer',
  'Company / Developer Profile', 'Firm background, data center portfolio, key personnel, prior delivered projects',
  true, 10, NULL),

('data_center', 0, 'Sponsor & Developer',
  'Personal Financial Statement (PFS)', 'Current within 90 days, signed — for principal guarantors',
  true, 20, NULL),

('data_center', 0, 'Sponsor & Developer',
  'Executive Summary', 'Project overview: location, tier classification, MW capacity, target tenant profile, business plan',
  true, 30, NULL),

('data_center', 0, 'Project & Site',
  'Site Control Documents', 'Purchase agreement, option, ground lease, or LOI with key terms',
  true, 40, NULL),

('data_center', 0, 'Project & Site',
  'Preliminary Site Plan / Layout', 'Conceptual plan showing building footprint, power delivery points, access',
  true, 50, NULL),

('data_center', 0, 'Utilities & Power',
  'Power Availability Letter (Utility)', 'Letter from utility confirming available capacity and estimated lead time',
  true, 60, '[ASSUMPTION] Assumes grid-connected colocation. For off-grid or backup-only, replace with generator/battery sizing study.'),

-- ── Phase 1: Soft Quote ──
('data_center', 1, 'Sponsor & Developer',
  'Credit Authorization', 'Signed authorization for sponsor credit pull',
  true, 100, NULL),

('data_center', 1, 'Sponsor & Developer',
  'Schedule of Real Estate / Asset Owned', 'All properties and data center assets, debt, and equity',
  true, 110, NULL),

('data_center', 1, 'Tenancy & Off-Take',
  'Anchor Tenant Pre-Lease or LOI', 'Minimum 10–20 MW commitment preferred; LOI acceptable at Soft Quote, executed lease required by Underwriting',
  true, 120, '[ASSUMPTION] Colocation model. Hyperscale deals typically need executed lease at this stage. Flag if no anchor tenant exists.'),

('data_center', 1, 'Tenancy & Off-Take',
  '§48C Energy Community Certification (preliminary)', 'Evidence that project site qualifies for §48C manufacturing/energy tax credit — IRS energy community map screenshot + county confirmation',
  false, 130, '[ASSUMPTION] §48C credit stacking included per your brief. Remove if not pursuing tax credit financing. Timing: §48C applications open periodically; check current IRS window.'),

('data_center', 1, 'Technical',
  'Power Capacity Study', 'Engineering study confirming MW availability, redundancy plan (2N, N+1), PUE target',
  true, 140, NULL),

('data_center', 1, 'Technical',
  'Cooling Requirements Summary', 'Cooling architecture (air-cooled, liquid-cooled, immersion), redundancy, efficiency',
  true, 150, NULL),

('data_center', 1, 'Financial',
  'Financial Model / Pro Forma', 'Revenue projections by tenant, opex, debt service coverage, stabilized cap rate, IRR',
  true, 160, NULL),

('data_center', 1, 'Financial',
  'Sources & Uses', 'Full capital stack: senior debt, equity, tax equity, any DFI/incentive funding',
  true, 170, NULL),

-- ── Phase 2: Term Sheet ──
('data_center', 2, 'Sponsor & Developer',
  'Entity Documents', 'Articles of org, operating agreement, EIN letter for borrowing entity',
  true, 200, NULL),

('data_center', 2, 'Construction & Budget',
  'Construction Budget (GMP or Cost Plan)', 'Itemized hard and soft costs, contingencies, construction timeline',
  true, 210, NULL),

('data_center', 2, 'Construction & Budget',
  'General Contractor Agreement / GMP', 'Executed or draft GMP contract with qualified data center GC',
  false, 220, 'Draft acceptable at Term Sheet; executed required by Underwriting.'),

('data_center', 2, 'Construction & Budget',
  'Construction Draw Schedule', 'Month-by-month draw against lender advance schedule',
  true, 230, NULL),

('data_center', 2, 'Tax & Incentives',
  '§48C Application Status / ITC Analysis', 'Tax credit quantification memo, application filing status or intent, equity structure for credit monetization',
  false, 240, '[ASSUMPTION] Remove if not pursuing §48C or ITC. If pursuing, get tax counsel memo. §48C is direct pay-eligible for certain entities.'),

-- ── Phase 3: Underwriting ──
('data_center', 3, 'Sponsor & Developer',
  'Corporate / Sponsor Tax Returns', 'Most recent 2–3 years, all entities in the capital stack',
  true, 300, NULL),

('data_center', 3, 'Sponsor & Developer',
  'Bank / Liquidity Statements', 'Most recent 2–3 months for all principals and the project entity',
  true, 310, NULL),

('data_center', 3, 'Tenancy & Off-Take',
  'Executed Anchor Tenant Lease(s)', 'Fully executed, lender-form-approved lease covering minimum required capacity',
  true, 320, NULL),

('data_center', 3, 'Utilities & Power',
  'Interconnection Agreement', 'Executed agreement with utility / ISO / RTO for grid interconnection at required MW',
  true, 330, '[ASSUMPTION] Required for all grid-connected builds. Lead times can be 2–4+ years — flag if not yet secured.'),

('data_center', 3, 'Technical',
  'Engineering Studies (LEED / PUE / Structural)', 'Third-party engineering validation of PUE, structural load, fire suppression, fiber connectivity',
  true, 340, NULL),

('data_center', 3, 'Environmental & Legal',
  'Environmental Report (Phase I ESA)', 'Phase I on the site; Phase II if Phase I identifies recognized environmental conditions',
  true, 350, NULL),

('data_center', 3, 'Environmental & Legal',
  'Title Commitment', 'Preliminary title report from lender-approved title company',
  true, 360, NULL),

('data_center', 3, 'Environmental & Legal',
  'Development or Ground Lease Agreement', 'Executed ground lease or development agreement if land not owned fee simple',
  false, 370, 'Required if site is ground-leased or developer-owned. Provide fee-simple title if owned outright.'),

('data_center', 3, 'Tax & Incentives',
  '§48C Certification / State Incentive Letters', 'DOE/IRS award letter (if §48C) or state incentive commitment letters for grants/abatements',
  false, 380, '[ASSUMPTION] Only required if tax credit or incentive funding is part of the capital stack.'),

-- ── Phase 4: Closing ──
('data_center', 4, 'Legal & Title',
  'Title Insurance', 'ALTA owner and lender title insurance policies',
  true, 400, NULL),

('data_center', 4, 'Legal & Title',
  'ALTA Survey', 'Current boundary and improvement survey',
  true, 410, NULL),

('data_center', 4, 'Legal & Title',
  'Building Permits', 'All required permits pulled: building, electrical, mechanical, special use',
  true, 420, NULL),

('data_center', 4, 'Legal & Title',
  'Contractor Bonds (Performance & Payment)', 'Required by lender for construction loan disbursements',
  true, 430, NULL),

('data_center', 4, 'Insurance',
  'Construction All-Risk Insurance', 'Builders risk policy naming lender as additional insured and loss payee',
  true, 440, NULL),


-- ─────────────────────────────────────────────────────────────────────────
-- 3. HARD MONEY / BRIDGE
-- Fast-close private credit, collateral-driven, less doc-heavy.
-- Typical close: 7–21 days from executed term sheet.
-- ─────────────────────────────────────────────────────────────────────────

INSERT INTO asset_class_requirements
  (asset_class, phase, group_name, doc_name, doc_sub, required, sort_order, notes)
VALUES

-- ── Phase 0: Intake ──
('hard_money', 0, 'Borrower',
  'Personal Financial Statement (PFS)', 'Current within 90 days, signed and dated',
  true, 10, NULL),

('hard_money', 0, 'Borrower',
  'Schedule of Real Estate Owned (REO)', 'All properties, current values, loan balances, and equity',
  true, 20, NULL),

('hard_money', 0, 'Borrower',
  'Credit Authorization', 'Signed authorization — hard money lenders often pull credit at intake',
  true, 30, NULL),

('hard_money', 0, 'Property',
  'Property Address & Description', 'Address, property type, number of units, current occupancy, condition',
  true, 40, NULL),

('hard_money', 0, 'Property',
  'Property Photos', 'Exterior, interior, any distress or deferred maintenance visible',
  true, 50, NULL),

('hard_money', 0, 'Deal',
  'Executive Summary (1-Page)', 'Deal snapshot: ask amount, LTV, use of proceeds, exit strategy, timeline',
  true, 60, NULL),

('hard_money', 0, 'Deal',
  'Exit Strategy Statement', 'How the loan will be repaid: sale, refinance, cash — lenders focus heavily on this',
  true, 70, 'Hard money lenders underwrite the exit more than the entry. Be specific: "Sell at $X in 12 months" or "Refinance to conventional at 70% LTV once stabilized."'),

-- ── Phase 1: Soft Quote ──
('hard_money', 1, 'Valuation',
  'Broker Price Opinion (BPO)', 'Recent BPO with current-value and as-repaired-value comps',
  true, 100, 'Many hard money lenders order their own BPO/appraisal. Provide a sponsor-ordered one to speed the quote.'),

('hard_money', 1, 'Valuation',
  'Comparable Sales / Market Data', 'Recent closed sales comps in the submarket supporting the ARV',
  true, 110, NULL),

('hard_money', 1, 'Property',
  'Current Rent Roll', 'Unit-level detail if income-producing; N/A for vacant/land',
  false, 120, 'Required for income-producing properties; skip for vacant, fix-and-flip, or raw land.'),

('hard_money', 1, 'Deal',
  'Preliminary Sources & Uses', 'Acquisition price, closing costs, rehab budget, total project cost, equity in',
  true, 130, NULL),

-- ── Phase 2: Term Sheet ──
('hard_money', 2, 'Borrower',
  'Entity Documents', 'Articles of org, operating agreement, EIN letter for the borrowing entity',
  true, 200, NULL),

('hard_money', 2, 'Deal',
  'Purchase Agreement / PSA', 'Executed contract if acquisition; title company name and contact',
  false, 210, 'Required for purchases. For refinances, provide current deed and payoff demand.'),

('hard_money', 2, 'Deal',
  'Full Sources & Uses', 'Final breakdown: purchase, closing costs, rehab, reserves',
  true, 220, NULL),

('hard_money', 2, 'Valuation',
  'Formal Appraisal (if required by lender)', 'Full appraisal with as-is and as-repaired values — some hard money lenders waive',
  false, 230, 'Many hard money lenders use an internal BPO instead of a full appraisal. Confirm with lender.'),

-- ── Phase 3: Underwriting ──
('hard_money', 3, 'Borrower',
  'Tax Returns (most recent 1–2 years)', 'Personal and/or entity returns; less scrutiny than conventional but often required',
  false, 300, 'Some hard money lenders waive tax returns entirely if LTV is low and PFS is strong. Confirm per lender.'),

('hard_money', 3, 'Borrower',
  'Bank Statements (2–3 months)', 'Evidence of liquidity for closing costs, down payment, and reserves',
  true, 310, NULL),

('hard_money', 3, 'Legal & Title',
  'Preliminary Title Report', 'From a title company; reveals liens, encumbrances, ownership chain',
  true, 320, NULL),

('hard_money', 3, 'Property',
  'Environmental Phase I (if commercial)',
  'Required by some hard money lenders on commercial collateral; rarely required on residential',
  false, 330, 'Skip for 1–4 family residential. Flag for commercial or industrial collateral.'),

-- ── Phase 4: Closing ──
('hard_money', 4, 'Legal & Title',
  'Title Insurance (Lender Policy)', 'ALTA lender title insurance naming the hard money lender as insured',
  true, 400, NULL),

('hard_money', 4, 'Insurance',
  'Property Insurance Binder', 'Evidence of hazard/fire coverage naming lender as additional insured and loss payee',
  true, 410, NULL),

('hard_money', 4, 'Legal & Title',
  'Payoff Demand (if refinance)', 'Written payoff statement from existing lender if paying off prior debt',
  false, 420, 'Required for refinances only.'),

('hard_money', 4, 'Legal & Title',
  'Executed Loan Documents', 'Promissory note, deed of trust/mortgage, personal guarantee (if recourse)',
  true, 430, NULL),


-- ─────────────────────────────────────────────────────────────────────────
-- 4. NUCLEAR / ENERGY INFRASTRUCTURE
-- SMR and grid-scale projects; sovereign/DFI-backed; long timelines.
--
-- [ASSUMPTION] Assumes project has initiated NRC pre-application or equivalent
--   state/federal regulatory process. Adjust phase gating for earlier-stage.
-- [ASSUMPTION] DFI backing assumed (US DFC, Ex-Im Bank, ADB, multilateral).
--   If purely private equity, remove sovereign/DFI-specific docs.
-- [ASSUMPTION] "Nuclear / Energy" combined asset class. If your pipeline has
--   both SMR and renewable/grid-scale, consider splitting into two asset classes —
--   the regulatory pathways diverge sharply (NRC vs. FERC/NEPA).
-- ─────────────────────────────────────────────────────────────────────────

INSERT INTO asset_class_requirements
  (asset_class, phase, group_name, doc_name, doc_sub, required, sort_order, notes)
VALUES

-- ── Phase 0: Intake ──
('nuclear', 0, 'Sponsor & Developer',
  'Sponsor / Developer Profile', 'Company background, leadership team, nuclear/energy credentials, prior large-scale infrastructure delivered',
  true, 10, '[ASSUMPTION] Nuclear and large-scale energy projects require credentialed developers. Sponsors without nuclear track record need a credentialed operating partner.'),

('nuclear', 0, 'Sponsor & Developer',
  'Personal Financial Statement (PFS)', 'Current within 90 days for key guarantors; corporate financial summary for developer entity',
  false, 20, 'PFS may be less relevant for project-financed structures; include corporate balance sheet instead.'),

('nuclear', 0, 'Project',
  'Project Overview / Investment Deck', 'Technology selection, site overview, capacity (MWe), target in-service date, development thesis',
  true, 30, NULL),

('nuclear', 0, 'Project',
  'Site Location & Ownership / Control', 'Site address, acreage, ownership status or option/control agreement',
  true, 40, NULL),

('nuclear', 0, 'Project',
  'Preliminary Feasibility Study', 'High-level technical and economic feasibility — can be sponsor-prepared at this stage',
  true, 50, NULL),

-- ── Phase 1: Soft Quote ──
('nuclear', 1, 'Off-Take & Revenue',
  'Power Purchase Agreement (PPA) — Term and Counterparty', 'Executed PPA or advanced-stage LOI; counterparty credit quality critical — utilities, data centers, industrial, or government off-takers preferred',
  true, 100, '[ASSUMPTION] Without a credible off-take agreement, most DFIs and institutional lenders will not quote. Flag if no PPA exists — deal may need a different capital path.'),

('nuclear', 1, 'Off-Take & Revenue',
  'Off-Take LOIs or MOUs (additional)', 'Secondary off-take commitments or non-binding agreements from strategic customers',
  false, 110, NULL),

('nuclear', 1, 'Regulatory',
  'NRC Licensing Status or Pre-Application', 'Documentation of NRC pre-application engagement (Early Site Permit, DC application, or combined license application status)',
  true, 120, '[ASSUMPTION] For SMR projects. For grid-scale renewables or storage without nuclear fuel, replace with FERC/NEPA process documentation.'),

('nuclear', 1, 'Regulatory',
  'DOE / State Permit Status Summary', 'Overview of all federal and state permits required, current status, and timeline to completion',
  true, 130, NULL),

('nuclear', 1, 'Technical',
  'Technology Selection Documentation', 'SMR vendor selection (e.g., NuScale, TerraPower, X-energy, Kairos), design maturity, licensing basis',
  true, 140, '[ASSUMPTION] SMR assumed. If grid-scale storage or solar/wind, replace with equipment supplier selection and technology specs.'),

('nuclear', 1, 'Financial',
  'Preliminary Financial Model', 'Project-level model: capacity factor, revenue (PPA), opex, capex, DSCR, IRR, equity returns — with sensitivity table',
  true, 150, NULL),

('nuclear', 1, 'Financial',
  'Capital Structure Memo (Preliminary)', 'Proposed structure: senior debt, DFI tranche, equity, sovereign guarantee — with rationale',
  true, 160, NULL),

-- ── Phase 2: Term Sheet ──
('nuclear', 2, 'Sponsor & Developer',
  'Entity Documents', 'Articles, operating agreement, EIN for the project company / SPV',
  true, 200, NULL),

('nuclear', 2, 'Sponsor & Developer',
  'Corporate / Sovereign Guarantees (draft)', 'Draft term for any corporate guarantee, sovereign guarantee, or political risk insurance',
  false, 210, '[ASSUMPTION] Sovereign guarantee assumed for DFI-backed structures. Omit for purely private capital structures.'),

('nuclear', 2, 'Environmental & Permitting',
  'Environmental Impact Assessment (EIA) / NEPA Process Status', 'EIA/EIS filing status; if complete, provide full report',
  true, 220, '[ASSUMPTION] NEPA/EIA often takes 3–5 years for nuclear. Flag current stage — if not started, flag as critical path risk.'),

('nuclear', 2, 'Project',
  'Site Control Documentation', 'Executed purchase agreement, long-term ground lease, or fee simple ownership documents',
  true, 230, NULL),

('nuclear', 2, 'Financial',
  'Full Development Budget', 'Pre-development, development, construction, commissioning — total lifecycle capex by phase and year',
  true, 240, NULL),

('nuclear', 2, 'Financial',
  'Construction Draw Schedule', 'Multi-year draw schedule aligned with development milestones and DFI tranche structure',
  true, 250, NULL),

-- ── Phase 3: Underwriting ──
('nuclear', 3, 'Sponsor & Developer',
  'Audited Financial Statements (Sponsor)', 'Most recent 2–3 years audited financials for the developer / project company',
  true, 300, NULL),

('nuclear', 3, 'Sponsor & Developer',
  'Sponsor Tax Returns', 'Most recent 2–3 years personal and corporate returns',
  false, 310, 'May be waived for large institutional developers. Required for private sponsors.'),

('nuclear', 3, 'Regulatory',
  'NRC License (if SMR) or FERC Interconnection Order', 'Combined Operating License (COL) or Construction Permit, or FERC interconnection order for grid-scale',
  true, 320, '[ASSUMPTION] This is the single longest-lead item for nuclear projects. License timelines for SMRs are 2–7 years from pre-application to approval. For renewables, FERC interconnection queues are 3–5 years in some ISOs. Confirm current status before quoting a closing timeline.'),

('nuclear', 3, 'Regulatory',
  'State PUC / Regulatory Approvals', 'State public utility commission approvals, rate orders, or exemptions',
  true, 330, NULL),

('nuclear', 3, 'Technical',
  'FEED Study (Front-End Engineering and Design)', 'Completed FEED or equivalent detailed engineering — defines capex within ±10–15%',
  true, 340, '[ASSUMPTION] FEED is required by most DFIs before a loan commitment. Cost: typically $5–50M depending on project scale.'),

('nuclear', 3, 'Technical',
  'Interconnection Agreement', 'Executed or substantially negotiated grid interconnection agreement with ISO/RTO or utility',
  true, 350, NULL),

('nuclear', 3, 'Off-Take & Revenue',
  'Executed PPA (Final)', 'Fully executed, lender-approved Power Purchase Agreement',
  true, 360, NULL),

('nuclear', 3, 'DFI & Sovereign',
  'DFI Term Sheet or Commitment Letter', 'Non-binding or conditional term sheet from DFI lender (US DFC, Ex-Im, ADB, EBRD, etc.)',
  false, 370, '[ASSUMPTION] Required only for DFI-backed structures. For purely private transactions, replace with senior lender term sheet.'),

('nuclear', 3, 'DFI & Sovereign',
  'Sovereign MOU (if applicable)', 'Government-to-government MOU or host-country support agreement if sovereign backing is part of the structure',
  false, 380, '[ASSUMPTION] Relevant for cross-border or international SMR deployments (e.g., US SMR export programs supported by Ex-Im or DFC). Remove for domestic-only projects.'),

-- ── Phase 4: Closing ──
('nuclear', 4, 'Construction & Contracts',
  'EPC Contract (Engineering-Procurement-Construction)', 'Executed fixed-price or cost-plus EPC agreement with a qualified nuclear/energy contractor',
  true, 400, NULL),

('nuclear', 4, 'Construction & Contracts',
  'Construction Agreement / Owner-Contractor Agreement', 'Master construction agreement supplementing the EPC',
  true, 410, NULL),

('nuclear', 4, 'Legal & Title',
  'Land / Site Agreements (Executed)', 'Final executed ground lease, easements, access rights, and any host community agreements',
  true, 420, NULL),

('nuclear', 4, 'Financial',
  'DFI Commitment Letter (Final)', 'Executed DFI loan commitment — condition precedent to closing',
  false, 430, '[ASSUMPTION] Required for DFI-backed structures only.'),

('nuclear', 4, 'Financial',
  'Executed PPA (Final, lender-consented)', 'Lender consent and direct agreement on the PPA — standard DFI requirement',
  true, 440, NULL),

('nuclear', 4, 'Financial',
  'Bond Documents (if bond financing)', 'If project bonds are part of the capital structure: indenture, bond purchase agreement, offering documents',
  false, 450, '[ASSUMPTION] Only required if bond financing is in the capital stack.'),

('nuclear', 4, 'Insurance',
  'Construction All-Risk (CAR) Insurance', 'Builders risk / construction all-risk naming lenders as additional insured',
  true, 460, NULL),

('nuclear', 4, 'Insurance',
  'Delay in Start-Up (DSU) Insurance', 'Covers revenue loss during construction delay — required by most DFIs for large projects',
  true, 470, '[ASSUMPTION] Required by most DFIs for projects over $100M. Confirm with lender.'),

('nuclear', 4, 'Insurance',
  'Nuclear Liability Insurance (Price-Anderson)', 'Required under the Price-Anderson Nuclear Industries Indemnity Act for all US nuclear facilities',
  false, 480, '[ASSUMPTION] Required for US nuclear projects under Price-Anderson. For SMRs in pre-commercial phase, consult nuclear counsel on applicability. Remove for non-nuclear energy projects.')

ON CONFLICT (asset_class, phase, doc_name) DO UPDATE
  SET
    group_name  = EXCLUDED.group_name,
    doc_sub     = EXCLUDED.doc_sub,
    required    = EXCLUDED.required,
    sort_order  = EXCLUDED.sort_order,
    notes       = EXCLUDED.notes;


-- ═══════════════════════════════════════════════════════════════════════════
-- Verification query — run after seeding to confirm counts:
-- SELECT asset_class, phase, count(*) as docs
-- FROM asset_class_requirements
-- GROUP BY asset_class, phase
-- ORDER BY asset_class, phase;
--
-- Expected rows (approximate):
--   multifamily:  ~23 docs across phases 0–4
--   data_center:  ~22 docs across phases 0–4
--   hard_money:   ~17 docs across phases 0–4
--   nuclear:      ~27 docs across phases 0–4
-- ═══════════════════════════════════════════════════════════════════════════
