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
// Fallback sample data so index.html works directly when opened via double-click (file://)
const FALLBACK_COMPANIES = [
  {
    id: "CMP-1001",
    name: "Nexus Cloud Solutions Sdn Bhd",
    regNo: "202301014892 (1508814-X)",
    industry: "Cloud & ICT Services",
    location: "Bangsar South, Kuala Lumpur",
    website: "https://nexuscloud.my",
    contactName: "Farah Nabila",
    contactEmail: "farah.hr@nexuscloud.my",
    submittedAt: "2026-11-11",
    status: "Waiting",
    rejectionReason: "",
    documents: [
      {
        name: "SSM_Section17_NexusCloud.pdf",
        type: "SSM Certificate",
        summary: "Incorporation Date: 14 Apr 2023 • Status: Active Sdn Bhd • Nature of Business: Cloud architecture and enterprise software."
      },
      {
        name: "TNB_Utility_Bill_Oct2026.pdf",
        type: "Address Proof",
        summary: "Registered commercial lot at Level 12, Vertical Corporate Tower, Bangsar South, 59200 KL."
      }
    ]
  },
  {
    id: "CMP-1002",
    name: "Straits Precision Engineering Sdn Bhd",
    regNo: "201901008821 (1318149-M)",
    industry: "Semiconductor & Automation",
    location: "Bayan Lepas, Penang",
    website: "https://straitsprecision.com.my",
    contactName: "Lim Wei康 (Lim Wei Kang)",
    contactEmail: "talent@straitsprecision.com.my",
    submittedAt: "2026-11-11",
    status: "Waiting",
    rejectionReason: "",
    documents: [
      {
        name: "SSM_Superform_Straits.pdf",
        type: "SSM Certificate",
        summary: "Incorporation Date: 08 Mar 2019 • Paid-up Capital: RM 2,500,000 • Free Industrial Zone Phase 3, Penang."
      },
      {
        name: "MIDA_Manufacturing_License.pdf",
        type: "Operating License",
        summary: "MITI / MIDA Approved Precision Tooling & Automated Test Equipment Manufacturer."
      }
    ]
  },
  {
    id: "CMP-1003",
    name: "QuickRich Global Marketing Enterprise",
    regNo: "JM0982341-D",
    industry: "General Trading & Marketing",
    location: "Johor Bahru, Johor",
    website: "N/A",
    contactName: "Kelvin Tan",
    contactEmail: "quickrich888@gmail.com",
    submittedAt: "2026-11-12",
    status: "Waiting",
    rejectionReason: "",
    documents: [
      {
        name: "Blurred_Business_Slip.jpg",
        type: "SSM Form D",
        summary: "Warning: Low-resolution photo scan. Expiry date appears to be 10 Jan 2025 (Expired). Recruiter uses personal Gmail address."
      }
    ]
  },
  {
    id: "CMP-1004",
    name: "Melaka Digital Labs Sdn Bhd",
    regNo: "202101033210 (1433510-K)",
    industry: "Software & AI Development",
    location: "Ayer Keroh, Melaka",
    website: "https://melakadigital.my",
    contactName: "Amirul Hakim",
    contactEmail: "careers@melakadigital.my",
    submittedAt: "2026-11-09",
    status: "Approved",
    rejectionReason: "",
    documents: [
      {
        name: "SSM_Cert_MelakaDigital.pdf",
        type: "SSM Certificate",
        summary: "Verified Sdn Bhd • MITC Ayer Keroh, 75450 Melaka • Matches corporate domain melakadigital.my."
      }
    ]
  },
  {
    id: "CMP-1005",
    name: "FastCash Crypto Holdings",
    regNo: "UNREGISTERED-OFFSHORE",
    industry: "Financial & Crypto",
    location: "Unlisted / Remote",
    website: "https://fastcash-invest.io",
    contactName: "Alex Wong",
    contactEmail: "admin@fastcash-invest.io",
    submittedAt: "2026-11-08",
    status: "Rejected",
    rejectionReason: "Invalid or expired SSM certificate — No valid SSM registration number provided; unverified offshore entity.",
    documents: [
      {
        name: "Self_Declaration_Letter.pdf",
        type: "Unofficial Letter",
        summary: "Unsigned 1-page document without Companies Commission of Malaysia (SSM) watermark or QR verification."
      }
    ]
  }
];

let companies = [];
let activeStatusFilter = "all";
let targetRejectCompanyId = null;

async function loadCompanies() {
  try {
    const res = await fetch("mock/companies.json");
    if (!res.ok) throw new Error("Failed to load JSON");
    companies = await res.json();
  } catch (err) {
    // Fallback when opened directly via file:// in Chrome
    companies = structuredClone(FALLBACK_COMPANIES);
  }
  renderTable();
}

function updateStats() {
  const waiting = companies.filter((c) => c.status === "Waiting").length;
  const approved = companies.filter((c) => c.status === "Approved").length;
  const rejected = companies.filter((c) => c.status === "Rejected").length;

  document.getElementById("stat-waiting").textContent = waiting;
  document.getElementById("stat-approved").textContent = approved;
  document.getElementById("stat-rejected").textContent = rejected;
  document.getElementById("stat-total").textContent = companies.length;
}

function renderTable() {
  updateStats();
  const searchQuery = document.getElementById("search-input").value.trim().toLowerCase();
  const tbody = document.getElementById("company-tbody");
  tbody.innerHTML = "";

  const filtered = companies.filter((c) => {
    const matchesStatus = activeStatusFilter === "all" || c.status === activeStatusFilter;
    const matchesSearch =
      !searchQuery ||
      c.name.toLowerCase().includes(searchQuery) ||
      c.regNo.toLowerCase().includes(searchQuery) ||
      c.contactEmail.toLowerCase().includes(searchQuery) ||
      c.location.toLowerCase().includes(searchQuery);
    return matchesStatus && matchesSearch;
  });

  if (filtered.length === 0) {
    tbody.innerHTML = `<tr><td colspan="7" class="muted" style="text-align:center; padding:24px;">No company applications match the current filter.</td></tr>`;
    return;
  }

  filtered.forEach((company) => {
    const tr = document.createElement("tr");
    const badgeClass =
      company.status === "Approved" ? "ok" : company.status === "Rejected" ? "bad" : "warn";

    const docsHtml = company.documents
      .map(
        (doc, idx) =>
          `<button type="button" class="doc-btn" onclick="openDocPreview('${company.id}', ${idx})">📄 ${doc.name}</button>`
      )
      .join("");

    const rejectReasonHtml =
      company.status === "Rejected" && company.rejectionReason
        ? `<div class="reject-reason-box"><strong>Rejected reason:</strong> ${company.rejectionReason}</div>`
        : "";

    tr.innerHTML = `
      <td>
        <strong>${company.name}</strong>
        <div class="company-meta">${company.industry} • ${company.location}</div>
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
          <button type="button" class="btn sm approve" onclick="handleApprove('${company.id}')">Approve</button>
          <button type="button" class="btn sm danger" onclick="openRejectModal('${company.id}')">Reject</button>
        </div>
      </td>
    `;
    tbody.appendChild(tr);
  });
}

window.openDocPreview = function (companyId, docIdx) {
  const company = companies.find((c) => c.id === companyId);
  if (!company || !company.documents[docIdx]) return;
  const doc = company.documents[docIdx];

  document.getElementById("doc-modal-title").textContent = doc.name;
  document.getElementById("doc-modal-company").textContent = `${company.name} (${company.regNo}) — ${doc.type}`;
  document.getElementById("doc-modal-content").innerHTML = `
    <p style="margin:0 0 8px;"><strong>Extracted Document Verification Summary:</strong></p>
    <p style="margin:0;">${doc.summary}</p>
  `;
  document.getElementById("doc-modal").hidden = false;
};

document.getElementById("close-doc-btn").addEventListener("click", () => {
  document.getElementById("doc-modal").hidden = true;
});

window.handleApprove = function (companyId) {
  const company = companies.find((c) => c.id === companyId);
  if (!company) return;
  company.status = "Approved";
  company.rejectionReason = "";
  document.getElementById("message").textContent = `Approved "${company.name}" (${company.regNo}). Recruiter account is now verified.`;
  renderTable();
};

window.openRejectModal = function (companyId) {
  const company = companies.find((c) => c.id === companyId);
  if (!company) return;
  targetRejectCompanyId = companyId;
  document.getElementById("reject-modal-sub").textContent = `${company.name} • SSM: ${company.regNo}`;
  document.getElementById("reject-reason-input").value = "";
  document.getElementById("reject-error").hidden = true;
  document.getElementById("reject-modal").hidden = false;
  document.getElementById("reject-reason-input").focus();
};

document.getElementById("cancel-reject-btn").addEventListener("click", () => {
  document.getElementById("reject-modal").hidden = true;
  targetRejectCompanyId = null;
});

document.getElementById("confirm-reject-btn").addEventListener("click", () => {
  const category = document.getElementById("reject-category").value;
  const details = document.getElementById("reject-reason-input").value.trim();
  const errorEl = document.getElementById("reject-error");

  if (!details) {
    errorEl.hidden = false;
    document.getElementById("reject-reason-input").focus();
    return;
  }

  const company = companies.find((c) => c.id === targetRejectCompanyId);
  if (company) {
    company.status = "Rejected";
    company.rejectionReason = `${category} — ${details}`;
    document.getElementById("message").textContent = `Rejected "${company.name}". Reason saved: ${company.rejectionReason}`;
  }

  document.getElementById("reject-modal").hidden = true;
  targetRejectCompanyId = null;
  renderTable();
});

// Status tab filtering
document.querySelectorAll(".tabs button[data-status]").forEach((btn) => {
  btn.addEventListener("click", () => {
    activeStatusFilter = btn.dataset.status;
    renderTable();
  });
});

// Search bar filtering
document.getElementById("search-input").addEventListener("input", renderTable);

// Initialize page
loadCompanies();