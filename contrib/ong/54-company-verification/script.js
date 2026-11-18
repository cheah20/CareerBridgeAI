// Example 1: tabs. Buttons with data-tab show the matching <section data-panel>.
document.querySelectorAll(".tabs button").forEach((button) => {
  button.addEventListener("click", () => {
    document.querySelectorAll(".tabs button").forEach((b) => b.classList.toggle("active", b === button));
    document.querySelectorAll("[data-panel]").forEach((p) => (p.hidden = p.dataset.panel !== button.dataset.tab));
  });
});

// Example 2: a button that shows a message instead of saving.
document.querySelectorAll("[data-demo]").forEach((button) => {
  button.addEventListener("click", () => {
    document.getElementById("message").textContent = button.dataset.demo;
  });
});

// ---- Your own code below this line ----
// Official SSM e-Info sample ROC Company Profile PDF URL
const SSM_SAMPLE_PDF = "https://www.ssm-einfo.my/public/assets/sample/Company_Profile.pdf";

// 12 realistic company verification records so pagination (1, 2, 3) is immediately interactive
const FALLBACK_COMPANIES = [
  {
    id: "CMP-1001",
    name: "InTech Worldwide Solutions Sdn Bhd",
    regNo: "202301014892 (1508814-X)",
    industry: "Industrial & Enterprise Technology",
    size: "51–200 employees",
    location: "Bangsar South, Kuala Lumpur",
    address: "Level 12, Vertical Corporate Tower, Bangsar South, 59200 Kuala Lumpur",
    website: "https://www.intechww.com",
    description: "Enterprise industrial engineering and digital transformation provider serving manufacturing clients across Malaysia and ASEAN.",
    contactName: "Farah Nabila",
    contactEmail: "farah.hr@intechww.com",
    submittedAt: "2026-11-12",
    status: "Waiting",
    rejectionReason: "",
    documents: [
      {
        name: "Corporate-Profile.pdf",
        type: "Corporate Profile",
        url: "https://www.intechww.com/wp-content/uploads/Corporate-Profile.pdf",
        summary: "Official InTech Corporate Profile PDF (intechww.com) • Verified industrial & technology solutions provider."
      },
      {
        name: "SSM_Company_Profile_ROC.pdf",
        type: "SSM ROC Extract",
        url: SSM_SAMPLE_PDF,
        summary: "Official 6-page SSM e-Info Company Profile (ROC) extract showing share capital, directors, and active status."
      }
    ]
  },
  {
    id: "CMP-1002",
    name: "BPE Energy Sdn. Bhd.",
    regNo: "201801021450 (1283469-K)",
    industry: "Clean Energy, IoT & AI Predictive Maintenance",
    size: "51–200 employees",
    location: "Shah Alam, Selangor",
    address: "No. 14, Jalan Saujana Indah 8, Taman Perindustrian Saujana Indah, 40150 Shah Alam, Selangor",
    website: "https://www.bpe.com.my",
    description: "Engineering solutions company specializing in electric process heaters, IoT earthing diagnostics, and AI-driven predictive maintenance (ARTESIS).",
    contactName: "Ir. Razak Hamzah",
    contactEmail: "careers@bpe.com.my",
    submittedAt: "2026-11-12",
    status: "Waiting",
    rejectionReason: "",
    documents: [
      {
        name: "BPE-Energy-Company-Profile-2024.pdf",
        type: "Corporate Profile",
        url: "https://www.bpe.com.my/wp-content/uploads/2024/02/BPE-Energy-Company-Profile-2024.pdf",
        summary: "28-page BPE Energy 2024 Corporate Profile detailing IoT diagnostics, AI maintenance, and Board of Engineers Malaysia (BEM) credentials."
      },
      {
        name: "SSM_Company_Profile_ROC.pdf",
        type: "SSM ROC Extract",
        url: SSM_SAMPLE_PDF,
        summary: "SSM e-Info Corporate Information extract confirming active Sdn Bhd incorporation."
      }
    ]
  },
  {
    id: "CMP-1003",
    name: "Straits Technics Sdn. Bhd. (STSB)",
    regNo: "201501009932 (1135267-W)",
    industry: "EPCIC, Mechanical & Electrical Engineering",
    size: "51–200 employees",
    location: "Petaling Jaya, Selangor",
    address: "Block C, Phileo Damansara 1, No. 9, Jalan 16/11, 46350 Petaling Jaya, Selangor",
    website: "https://www.straitstechnics.com.my",
    description: "Malaysian engineering company undertaking EPCIC works, plant operation & maintenance, water pump systems, and airfield ground lighting.",
    contactName: "Syafiq Azman",
    contactEmail: "hr@straitstechnics.com.my",
    submittedAt: "2026-11-12",
    status: "Waiting",
    rejectionReason: "",
    documents: [
      {
        name: "STSB-Company-Profile-2020.pdf",
        type: "Corporate Profile",
        url: "https://www.straitstechnics.com.my/file/STSB-Company-Profile-2020.pdf",
        summary: "Official Straits Technics Sdn Bhd (STSB) Corporate Profile covering EPCIC, M&E engineering, and CIDB fellowship background."
      },
      {
        name: "SSM_Company_Profile_ROC.pdf",
        type: "SSM ROC Extract",
        url: SSM_SAMPLE_PDF,
        summary: "SSM e-Info ROC registration profile."
      }
    ]
  },
  {
    id: "CMP-1004",
    name: "Penang Silicon Microelectronics Sdn. Bhd.",
    regNo: "202001015632 (1371952-T)",
    industry: "IC Design & Embedded Systems",
    size: "201–500 employees",
    location: "Bayan Lepas, Penang",
    address: "Phase 4, Free Industrial Zone, 11900 Bayan Lepas, Pulau Pinang",
    website: "https://www.intechww.com",
    description: "VLSI design verification and embedded firmware R&D center located in Penang Free Industrial Zone.",
    contactName: "Lim Wei Kang",
    contactEmail: "recruitment@penangsilicon.my",
    submittedAt: "2026-11-11",
    status: "Waiting",
    rejectionReason: "",
    documents: [
      {
        name: "SSM_Company_Profile_ROC.pdf",
        type: "SSM ROC Extract",
        url: SSM_SAMPLE_PDF,
        summary: "SSM e-Info ROC extract • Active status • Registered in Bayan Lepas, Penang."
      },
      {
        name: "Corporate-Profile.pdf",
        type: "Corporate Profile",
        url: "https://www.intechww.com/wp-content/uploads/Corporate-Profile.pdf",
        summary: "Corporate overview and semiconductor laboratory capabilities."
      }
    ]
  },
  {
    id: "CMP-1005",
    name: "Ayer Keroh Robotics & Automation Sdn. Bhd.",
    regNo: "202201007741 (1453438-A)",
    industry: "Industrial Robotics & Vision AI",
    size: "11–50 employees",
    location: "Ayer Keroh, Melaka",
    address: "Lot 19, Kawasan Perindustrian Ayer Keroh, 75450 Melaka",
    website: "https://www.bpe.com.my",
    description: "Automated optical inspection (AOI) and factory PLC integration partner for Melaka and Negeri Sembilan manufacturers.",
    contactName: "Chong Kar Wai",
    contactEmail: "hr@akrobotics.com.my",
    submittedAt: "2026-11-11",
    status: "Waiting",
    rejectionReason: "",
    documents: [
      {
        name: "SSM_Company_Profile_ROC.pdf",
        type: "SSM ROC Extract",
        url: SSM_SAMPLE_PDF,
        summary: "SSM e-Info ROC extract confirming registration in Melaka."
      }
    ]
  },
  {
    id: "CMP-1006",
    name: "Borneo Green AgriTech Sdn. Bhd.",
    regNo: "202101041209 (1441509-V)",
    industry: "Smart Agriculture & Drone Mapping",
    size: "11–50 employees",
    location: "Kuching, Sarawak",
    address: "Level 3, Saradise Commercial Centre, 93350 Kuching, Sarawak",
    website: "https://www.straitstechnics.com.my",
    description: "Precision plantation management using multispectral drone imagery and IoT soil sensors.",
    contactName: "Evelyn Baru",
    contactEmail: "talent@borneoagritech.my",
    submittedAt: "2026-11-10",
    status: "Waiting",
    rejectionReason: "",
    documents: [
      {
        name: "SSM_Company_Profile_ROC.pdf",
        type: "SSM ROC Extract",
        url: SSM_SAMPLE_PDF,
        summary: "SSM e-Info ROC extract • Active Sarawak Sdn Bhd entity."
      }
    ]
  },
  {
    id: "CMP-1007",
    name: "SBE Engineering Sdn. Bhd.",
    regNo: "201401018820 (1094907-P)",
    industry: "Civil Engineering & Infrastructure",
    size: "51–200 employees",
    location: "Petaling Jaya, Selangor",
    address: "Suite 8-12, Menara Mutiara Majestic, Jalan Othman, 46000 Petaling Jaya, Selangor",
    website: "https://sbeengineering.com.my",
    description: "CIDB Grade G7 registered civil engineering contractor specializing in bridge expansion joints, slope rehabilitation, and road safety.",
    contactName: "Nurul Huda",
    contactEmail: "admin@sbeengineering.com.my",
    submittedAt: "2026-11-09",
    status: "Approved",
    rejectionReason: "",
    documents: [
      {
        name: "SBE-Profile-Updated.pdf",
        type: "Corporate Profile",
        url: "https://sbeengineering.com.my/wp-content/uploads/2024/06/SBE-Profile-Updated.pdf",
        summary: "Verified SBE Engineering Sdn Bhd Corporate Profile • CIDB Grade G7 contractor with 200+ local workforce."
      },
      {
        name: "SSM_Company_Profile_ROC.pdf",
        type: "SSM ROC Extract",
        url: SSM_SAMPLE_PDF,
        summary: "Verified SSM e-Info ROC extract matching SBE Engineering Sdn Bhd."
      }
    ]
  },
  {
    id: "CMP-1008",
    name: "Mohaz Engineering & Technology (M) Sdn. Bhd.",
    regNo: "200301033412 (634989-H)",
    industry: "Civil, Electrical & Mechanical Construction",
    size: "51–200 employees",
    location: "Shah Alam, Selangor",
    address: "No. 22, Jalan Kristal K7/K, Seksyen 7, 40000 Shah Alam, Selangor",
    website: "https://www.mohazet.com.my",
    description: "Established Bumiputera G7 engineering contractor registered with CIDB, PKK, MOF, and TNB.",
    contactName: "Hafiz Zulkifli",
    contactEmail: "hr@mohazet.com.my",
    submittedAt: "2026-11-08",
    status: "Approved",
    rejectionReason: "",
    documents: [
      {
        name: "Company-Profile-Mohaz-Eng-Tech-M-Sdn-Bhd.pdf",
        type: "Corporate Profile",
        url: "https://www.mohazet.com.my/wp-content/uploads/2020/06/Company-Profile-Mohaz-Eng-Tech-M-Sdn-Bhd.pdf",
        summary: "Authentic Mohaz Engineering & Technology (634989-H) corporate profile with SSM, MOF, and CIDB certificates."
      }
    ]
  },
  {
    id: "CMP-1009",
    name: "Melaka Digital Labs Sdn. Bhd.",
    regNo: "202101033210 (1433510-K)",
    industry: "Software & AI Development",
    size: "11–50 employees",
    location: "Ayer Keroh, Melaka",
    address: "Level 5, Wisma MITC, Jalan Konvensyen, Hang Tuah Jaya, 75450 Ayer Keroh, Melaka",
    website: "https://www.intechww.com",
    description: "AI software house specializing in web platforms, mobile apps, and intelligent automation.",
    contactName: "Amirul Hakim",
    contactEmail: "careers@melakadigital.my",
    submittedAt: "2026-11-07",
    status: "Approved",
    rejectionReason: "",
    documents: [
      {
        name: "SSM_Company_Profile_ROC.pdf",
        type: "SSM ROC Extract",
        url: SSM_SAMPLE_PDF,
        summary: "Verified Sdn Bhd profile and SSM registration 202101033210 (1433510-K)."
      }
    ]
  },
  {
    id: "CMP-1010",
    name: "Cyberjaya Cloud FinTech Sdn. Bhd.",
    regNo: "201901029910 (1339240-D)",
    industry: "Financial Technology & Payment Gateways",
    size: "51–200 employees",
    location: "Cyberjaya, Selangor",
    address: "Persiaran APEC, Cyber 8, 63000 Cyberjaya, Selangor",
    website: "https://www.intechww.com",
    description: "ISO-27001 certified digital payment infrastructure and merchant settlement platform.",
    contactName: "grace.tan@cyberfintech.my",
    contactEmail: "grace.tan@cyberfintech.my",
    submittedAt: "2026-11-06",
    status: "Approved",
    rejectionReason: "",
    documents: [
      {
        name: "SSM_Company_Profile_ROC.pdf",
        type: "SSM ROC Extract",
        url: SSM_SAMPLE_PDF,
        summary: "Verified SSM e-Info ROC extract."
      }
    ]
  },
  {
    id: "CMP-1011",
    name: "QuickRich Global Marketing Enterprise",
    regNo: "JM0982341-D",
    industry: "General Trading & Commission Marketing",
    size: "1–10 employees",
    location: "Johor Bahru, Johor",
    address: "No. 18A, Jalan Permas 10/2, Bandar Baru Permas Jaya, 81750 Masai, Johor",
    website: "https://quickrich-my.example.com",
    description: "Online marketing agency recruiting remote data entry clerks and high-commission agents.",
    contactName: "Kelvin Tan",
    contactEmail: "quickrich888@gmail.com",
    submittedAt: "2026-11-05",
    status: "Rejected",
    rejectionReason: "Submitted profile does not match uploaded PDF — Recruiter claimed to be 'QuickRich Global Marketing', but uploaded the PDF profile of 'Mohaz Engineering & Technology (M) Sdn Bhd (634989-H)'.",
    documents: [
      {
        name: "Company-Profile-Mohaz-Eng-Tech-M-Sdn-Bhd.pdf",
        type: "Mismatched PDF Proof",
        url: "https://www.mohazet.com.my/wp-content/uploads/2020/06/Company-Profile-Mohaz-Eng-Tech-M-Sdn-Bhd.pdf",
        summary: "⚠️ FRAUD ALERT: Uploaded PDF actually belongs to MOHAZ ENGINEERING & TECHNOLOGY (M) SDN. BHD. (634989-H), NOT QuickRich Global Marketing!"
      }
    ]
  },
  {
    id: "CMP-1012",
    name: "FastCash Crypto Holdings",
    regNo: "UNREGISTERED-OFFSHORE",
    industry: "High-Yield Crypto & Forex",
    size: "1–10 employees",
    location: "Unlisted / Remote",
    address: "Virtual Office (No Malaysia physical address provided)",
    website: "https://fastcash-invest.example.io",
    description: "Remote commission agent recruitment for unregulated offshore token trading.",
    contactName: "Alex Wong",
    contactEmail: "admin@fastcash-invest.io",
    submittedAt: "2026-11-04",
    status: "Rejected",
    rejectionReason: "Invalid or expired SSM certificate — No valid Malaysia SSM registration number provided; unverified offshore entity.",
    documents: [
      {
        name: "SSM_Company_Profile_ROC.pdf",
        type: "Unmatched Sample",
        url: SSM_SAMPLE_PDF,
        summary: "Recruiter uploaded a generic blank sample PDF without any company registration details matching FastCash."
      }
    ]
  }
];

// Application state variables (includes pagination & active KPI card filter)
let companies = [];
let activeStatusFilter = "all";
let currentPage = 1;
let pageSize = 5;
let targetApproveCompanyId = null;
let targetRejectCompanyId = null;
let activeInspectCompanyId = null;

/**
 * Display a status or error message in the bottom feedback bar.
 */
function showFeedback(text, isError = false) {
  const msgEl = document.getElementById("message");
  msgEl.textContent = text;
  msgEl.style.color = isError ? "var(--bad)" : "var(--sub)";
}

/**
 * Load company verification records from mock/companies.json (or future #60 FastAPI endpoint).
 * Falls back gracefully to FALLBACK_COMPANIES when opened via file:// in Chrome.
 */
async function loadCompanies() {
  try {
    const response = await fetch("mock/companies.json");
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const data = await response.json();
    if (!Array.isArray(data)) throw new Error("Invalid JSON format");
    companies = data;
  } catch (error) {
    companies = structuredClone(FALLBACK_COMPANIES);
  }
  renderTable();
}

/**
 * Update the 4 clickable KPI cards and the "Displaying: ..." status indicator badge.
 */
function updateStatsAndActiveCard(filteredCount) {
  const waitingCount = companies.filter((c) => c.status === "Waiting").length;
  const approvedCount = companies.filter((c) => c.status === "Approved").length;
  const rejectedCount = companies.filter((c) => c.status === "Rejected").length;

  document.getElementById("stat-total").textContent = companies.length;
  document.getElementById("stat-waiting").textContent = waitingCount;
  document.getElementById("stat-approved").textContent = approvedCount;
  document.getElementById("stat-rejected").textContent = rejectedCount;

  // Highlight whichever KPI card is currently selected
  document.querySelectorAll(".kpi-card").forEach((card) => {
    const isSelected = card.dataset.status === activeStatusFilter;
    card.classList.toggle("active", isSelected);
    card.setAttribute("aria-selected", isSelected ? "true" : "false");
  });

  // Update the current view indicator badge next to the table header
  const viewBadge = document.getElementById("current-view-badge");
  const labelMap = {
    all: "All submissions",
    Waiting: "Waiting review",
    Approved: "Approved companies",
    Rejected: "Rejected companies"
  };
  viewBadge.textContent = `Displaying: ${labelMap[activeStatusFilter] || activeStatusFilter} (${filteredCount})`;
  viewBadge.className =
    activeStatusFilter === "Approved"
      ? "status ok"
      : activeStatusFilter === "Rejected"
      ? "status bad"
      : activeStatusFilter === "Waiting"
      ? "status warn"
      : "status info";
}

/**
 * Render the numbered pagination bar (Prev, 1, 2, 3..., Next) and row counter.
 */
function renderPagination(totalItems) {
  const summaryEl = document.getElementById("pagination-summary");
  const controlsEl = document.getElementById("pagination-controls");
  controlsEl.innerHTML = "";

  if (totalItems === 0) {
    summaryEl.textContent = "Showing 0 of 0 companies";
    return;
  }

  const totalPages = Math.ceil(totalItems / pageSize);
  if (currentPage > totalPages) currentPage = totalPages;
  if (currentPage < 1) currentPage = 1;

  const startIdx = (currentPage - 1) * pageSize + 1;
  const endIdx = Math.min(currentPage * pageSize, totalItems);
  summaryEl.textContent = `Showing ${startIdx}–${endIdx} of ${totalItems} companies`;

  // Previous button
  const prevBtn = document.createElement("button");
  prevBtn.type = "button";
  prevBtn.className = "page-btn";
  prevBtn.textContent = "‹ Prev";
  prevBtn.disabled = currentPage === 1;
  prevBtn.addEventListener("click", () => {
    if (currentPage > 1) {
      currentPage--;
      renderTable();
    }
  });
  controlsEl.appendChild(prevBtn);

  // Numbered page buttons (1, 2, 3...)
  for (let p = 1; p <= totalPages; p++) {
    const pageBtn = document.createElement("button");
    pageBtn.type = "button";
    pageBtn.className = `page-btn ${p === currentPage ? "active" : ""}`;
    pageBtn.textContent = String(p);
    pageBtn.addEventListener("click", () => {
      currentPage = p;
      renderTable();
    });
    controlsEl.appendChild(pageBtn);
  }

  // Next button
  const nextBtn = document.createElement("button");
  nextBtn.type = "button";
  nextBtn.className = "page-btn";
  nextBtn.textContent = "Next ›";
  nextBtn.disabled = currentPage === totalPages;
  nextBtn.addEventListener("click", () => {
    if (currentPage < totalPages) {
      currentPage++;
      renderTable();
    }
  });
  controlsEl.appendChild(nextBtn);
}

/**
 * Render the company verification table with active KPI card filter, search, and pagination.
 */
function renderTable() {
  const searchInput = document.getElementById("search-input");
  const searchQuery = searchInput.value.trim().toLowerCase();
  document.getElementById("clear-search-btn").hidden = !searchQuery;

  const tbody = document.getElementById("company-tbody");
  tbody.innerHTML = "";

  // Step 1: Filter by selected KPI card status + search query
  const filtered = companies.filter((company) => {
    const matchesStatus = activeStatusFilter === "all" || company.status === activeStatusFilter;
    const matchesSearch =
      !searchQuery ||
      company.id.toLowerCase().includes(searchQuery) ||
      company.name.toLowerCase().includes(searchQuery) ||
      company.regNo.toLowerCase().includes(searchQuery) ||
      company.contactName.toLowerCase().includes(searchQuery) ||
      company.contactEmail.toLowerCase().includes(searchQuery) ||
      company.location.toLowerCase().includes(searchQuery) ||
      company.industry.toLowerCase().includes(searchQuery);
    return matchesStatus && matchesSearch;
  });

  // Update KPI card numbers, active highlight, and current view badge
  updateStatsAndActiveCard(filtered.length);

  // Step 2: Calculate pagination slice
  renderPagination(filtered.length);

  if (filtered.length === 0) {
    tbody.innerHTML = `
      <tr>
        <td colspan="7" class="muted" style="text-align:center; padding:28px;">
          No company submissions match your current card filter or search keyword.
        </td>
      </tr>
    `;
    return;
  }

  const startIndex = (currentPage - 1) * pageSize;
  const pageItems = filtered.slice(startIndex, startIndex + pageSize);

  // Step 3: Render only the rows for the current page
  pageItems.forEach((company) => {
    const tr = document.createElement("tr");
    const badgeClass =
      company.status === "Approved" ? "ok" : company.status === "Rejected" ? "bad" : "warn";

    const docsHtml = (company.documents || [])
      .map(
        (doc, idx) => `
          <div class="doc-item">
            <a href="${doc.url}" target="_blank" rel="noopener noreferrer" class="doc-link" title="Open ${doc.name} in new tab">
              📄 ${doc.name} ↗
            </a>
            <button type="button" class="doc-preview-btn" onclick="openInspectorModal('${company.id}', ${idx})">
              View Profile &amp; PDF
            </button>
          </div>
        `
      )
      .join("");

    const rejectReasonHtml =
      company.status === "Rejected" && company.rejectionReason
        ? `<div class="reject-reason-box"><strong>Rejection reason:</strong> ${company.rejectionReason}</div>`
        : "";

    const isAlreadyApproved = company.status === "Approved";
    const isAlreadyRejected = company.status === "Rejected";

    tr.innerHTML = `
      <td>
        <button type="button" class="company-name-btn" onclick="openInspectorModal('${company.id}', 0)">
          ${company.name}
        </button>
        <div class="company-meta">${company.id} • ${company.industry} • ${company.location}</div>
        ${rejectReasonHtml}
      </td>
      <td><span class="ssm-code">${company.regNo}</span></td>
      <td>
        <div>${company.contactName}</div>
        <div class="company-meta">${company.contactEmail}</div>
      </td>
      <td><div class="doc-list">${docsHtml}</div></td>
      <td>${company.submittedAt}</td>
      <td><span class="status ${badgeClass}">${company.status}</span></td>
      <td>
        <div class="action-btns">
          <button type="button" class="btn sm approve" ${isAlreadyApproved ? "disabled" : ""} onclick="openApproveModal('${company.id}')">
            ${isAlreadyApproved ? "Approved ✓" : "Approve"}
          </button>
          <button type="button" class="btn sm danger" ${isAlreadyRejected ? "disabled" : ""} onclick="openRejectModal('${company.id}')">
            ${isAlreadyRejected ? "Rejected ✕" : "Reject"}
          </button>
        </div>
      </td>
    `;
    tbody.appendChild(tr);
  });
}

/**
 * Open the Side-by-Side Company Profile & Proof Document Inspector Modal.
 */
window.openInspectorModal = function (companyId, docIdx = 0) {
  const company = companies.find((c) => c.id === companyId);
  if (!company) {
    showFeedback(`Error: Company record "${companyId}" not found.`, true);
    return;
  }

  activeInspectCompanyId = companyId;
  const badgeClass =
    company.status === "Approved" ? "ok" : company.status === "Rejected" ? "bad" : "warn";

  document.getElementById("ins-company-name").textContent = company.name;
  document.getElementById("ins-company-sub").textContent = `Submission ID: ${company.id} • Submitted on ${company.submittedAt}`;
  document.getElementById("ins-name").textContent = company.name;
  document.getElementById("ins-ssm").textContent = company.regNo;
  document.getElementById("ins-industry-size").textContent = `${company.industry} (${company.size})`;
  document.getElementById("ins-address").textContent = company.address;
  document.getElementById("ins-website").textContent = company.website;
  document.getElementById("ins-website").href = company.website;
  document.getElementById("ins-contact").textContent = `${company.contactName} (${company.contactEmail})`;
  document.getElementById("ins-desc").textContent = company.description;
  document.getElementById("ins-current-status").innerHTML = `Current status: <span class="status ${badgeClass}">${company.status}</span>`;

  document.getElementById("ins-approve-btn").disabled = company.status === "Approved";
  document.getElementById("ins-reject-btn").disabled = company.status === "Rejected";

  const docBtnsContainer = document.getElementById("ins-doc-buttons");
  docBtnsContainer.innerHTML = (company.documents || [])
    .map(
      (d, index) => `
        <div class="doc-item">
          <button type="button" class="doc-preview-btn" onclick="selectInspectorDoc('${company.id}', ${index})">
            📄 Preview ${d.name}
          </button>
          <a href="${d.url}" target="_blank" rel="noopener noreferrer" class="doc-link">Open PDF ↗</a>
        </div>
      `
    )
    .join("");

  selectInspectorDoc(companyId, docIdx);
  document.getElementById("profile-modal").hidden = false;
};

/**
 * Switch the active proof PDF displayed in the right-hand iframe of the inspector modal.
 */
window.selectInspectorDoc = function (companyId, docIdx) {
  const company = companies.find((c) => c.id === companyId);
  if (!company || !company.documents || !company.documents[docIdx]) {
    showFeedback("Error: Requested document could not be loaded.", true);
    return;
  }
  const doc = company.documents[docIdx];

  document.getElementById("ins-active-doc-name").textContent = `${doc.name} (${doc.type})`;
  document.getElementById("ins-open-pdf-tab").href = doc.url;
  document.getElementById("ins-doc-summary").innerHTML = `<strong>Verification Check:</strong> ${doc.summary}`;
  document.getElementById("ins-pdf-iframe").src = doc.url;
};

// Close the Profile & PDF Inspector modal
document.getElementById("close-profile-btn").addEventListener("click", () => {
  document.getElementById("profile-modal").hidden = true;
  document.getElementById("ins-pdf-iframe").src = "about:blank";
  activeInspectCompanyId = null;
});

// Approve / Reject buttons inside the Inspector modal trigger the confirmation modals
document.getElementById("ins-approve-btn").addEventListener("click", () => {
  if (!activeInspectCompanyId) return;
  const id = activeInspectCompanyId;
  document.getElementById("profile-modal").hidden = true;
  document.getElementById("ins-pdf-iframe").src = "about:blank";
  openApproveModal(id);
});

document.getElementById("ins-reject-btn").addEventListener("click", () => {
  if (!activeInspectCompanyId) return;
  const id = activeInspectCompanyId;
  document.getElementById("profile-modal").hidden = true;
  document.getElementById("ins-pdf-iframe").src = "about:blank";
  openRejectModal(id);
});

/**
 * Open the Approve Confirmation Modal to prevent accidental single-click approvals.
 */
window.openApproveModal = function (companyId) {
  const company = companies.find((c) => c.id === companyId);
  if (!company) {
    showFeedback(`Error: Cannot find company ID "${companyId}".`, true);
    return;
  }
  if (company.status === "Approved") {
    showFeedback(`"${company.name}" is already approved.`, true);
    return;
  }

  targetApproveCompanyId = companyId;
  document.getElementById("approve-modal-sub").textContent = `${company.name} • SSM: ${company.regNo}`;
  document.getElementById("approve-confirm-check").checked = false;
  document.getElementById("approve-error").hidden = true;
  document.getElementById("approve-modal").hidden = false;
};

// Cancel button in Approve Confirmation Modal
document.getElementById("cancel-approve-btn").addEventListener("click", () => {
  document.getElementById("approve-modal").hidden = true;
  targetApproveCompanyId = null;
});

// Confirm Approval button: validates that the admin ticked the verification checkbox
document.getElementById("confirm-approve-btn").addEventListener("click", () => {
  const isChecked = document.getElementById("approve-confirm-check").checked;
  const errorEl = document.getElementById("approve-error");

  if (!isChecked) {
    errorEl.hidden = false;
    return;
  }

  const company = companies.find((c) => c.id === targetApproveCompanyId);
  if (!company) {
    showFeedback("Error: Company record not found during approval.", true);
    return;
  }

  company.status = "Approved";
  company.rejectionReason = "";
  showFeedback(`✅ Approved "${company.name}" (SSM: ${company.regNo}). Employer account is now verified.`);

  document.getElementById("approve-modal").hidden = true;
  targetApproveCompanyId = null;
  renderTable();
});

/**
 * Open the mandatory rejection reason modal.
 */
window.openRejectModal = function (companyId) {
  const company = companies.find((c) => c.id === companyId);
  if (!company) {
    showFeedback(`Error: Cannot find company ID "${companyId}".`, true);
    return;
  }
  if (company.status === "Rejected") {
    showFeedback(`"${company.name}" is already rejected.`, true);
    return;
  }

  targetRejectCompanyId = companyId;
  document.getElementById("reject-modal-sub").textContent = `${company.name} • SSM: ${company.regNo}`;
  document.getElementById("reject-reason-input").value = "";
  document.getElementById("reject-error").hidden = true;
  document.getElementById("reject-modal").hidden = false;
  document.getElementById("reject-reason-input").focus();
};

// Cancel button in rejection modal
document.getElementById("cancel-reject-btn").addEventListener("click", () => {
  document.getElementById("reject-modal").hidden = true;
  targetRejectCompanyId = null;
});

// Confirm rejection button: validates that a meaningful reason (>= 10 chars) was entered
document.getElementById("confirm-reject-btn").addEventListener("click", () => {
  const category = document.getElementById("reject-category").value;
  const details = document.getElementById("reject-reason-input").value.trim();
  const errorEl = document.getElementById("reject-error");

  if (details.length < 10) {
    errorEl.hidden = false;
    document.getElementById("reject-reason-input").focus();
    return;
  }

  const company = companies.find((c) => c.id === targetRejectCompanyId);
  if (!company) {
    showFeedback("Error: Company record not found during rejection.", true);
    return;
  }

  company.status = "Rejected";
  company.rejectionReason = `${category} — ${details}`;
  showFeedback(`❌ Rejected "${company.name}". Reason saved: ${company.rejectionReason}`);

  document.getElementById("reject-modal").hidden = true;
  targetRejectCompanyId = null;
  renderTable();
});

// Allow closing any open modal with the Escape key
document.addEventListener("keydown", (event) => {
  if (event.key === "Escape") {
    document.getElementById("profile-modal").hidden = true;
    document.getElementById("approve-modal").hidden = true;
    document.getElementById("reject-modal").hidden = true;
    document.getElementById("ins-pdf-iframe").src = "about:blank";
  }
});

// Bind clickable KPI cards to filter the table and reset pagination to page 1
document.querySelectorAll(".kpi-card").forEach((card) => {
  card.addEventListener("click", () => {
    activeStatusFilter = card.dataset.status;
    currentPage = 1;
    renderTable();
  });
});

// Bind real-time search input (resets to page 1 on search)
document.getElementById("search-input").addEventListener("input", () => {
  currentPage = 1;
  renderTable();
});

// Clear search button
document.getElementById("clear-search-btn").addEventListener("click", () => {
  document.getElementById("search-input").value = "";
  currentPage = 1;
  renderTable();
});

// Bind rows-per-page selector
document.getElementById("page-size-select").addEventListener("change", (event) => {
  pageSize = Number(event.target.value) || 5;
  currentPage = 1;
  renderTable();
});

// Initialize page
loadCompanies();