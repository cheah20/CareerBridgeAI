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

// 12 realistic job postings with mock AI fraud risk scores and reasons.
// Note on Business Logic: AI riskScore evaluates the job text (NLP/TF-IDF from #61),
// while companyVerified reflects whether the employer has passed #54 Company Verification.
// Therefore, a legitimate company still waiting in #54 (e.g., BPE Energy, JOB-509) can have
// a Low AI Risk Score (12%) while still being Unverified.
const FALLBACK_JOBS = [
  {
    id: "JOB-501",
    title: "Remote Data Entry Clerk (Instant Daily Payout)",
    company: "QuickRich Global Marketing Enterprise",
    companyVerified: false,
    recruiterEmail: "quickrich888@gmail.com",
    salary: "RM 6,500 – RM 9,000 / month",
    location: "Remote (Anywhere in Malaysia)",
    submittedAt: "2026-11-12",
    riskScore: 96,
    reasons: [
      "Salary is 320% above market average for entry-level data entry",
      "Requests RM 150 'training & registration fee' before onboarding",
      "Employer company failed SSM verification (#54)"
    ],
    keywords: ["instant payout", "registration fee", "whatsapp only", "no experience"],
    description: "Urgent hiring! Work 2 hours a day from your phone typing simple forms. Earn RM 300 daily with instant payout. Must pay a refundable RM 150 registration fee for account activation. Contact us on WhatsApp only.",
    status: "Waiting",
    decisionNote: ""
  },
  {
    id: "JOB-502",
    title: "Part-Time E-Commerce Order Processor (Work From Home)",
    company: "FastCash Crypto Holdings",
    companyVerified: false,
    recruiterEmail: "admin@fastcash-invest.io",
    salary: "RM 1,800 / week",
    location: "Remote",
    submittedAt: "2026-11-12",
    riskScore: 91,
    reasons: [
      "Classic task-boosting / advance-fee scam pattern detected",
      "Directs candidates to external Telegram channel instead of platform",
      "Unregistered offshore employer entity"
    ],
    keywords: ["telegram", "weekly payout", "top up", "guaranteed commission"],
    description: "Help merchants boost product ratings from home. No interview required! Earn RM 1,800 every week with guaranteed commission. Message our Telegram coordinator to start immediately.",
    status: "Waiting",
    decisionNote: ""
  },
  {
    id: "JOB-503",
    title: "Personal Assistant & Crypto Payment Courier",
    company: "Global FastEarn Enterprise",
    companyVerified: false,
    recruiterEmail: "hr.fastearn@yahoo.com",
    salary: "RM 8,000 / month",
    location: "Johor Bahru, Johor",
    submittedAt: "2026-11-11",
    riskScore: 85,
    reasons: [
      "Asks applicant to use personal bank account to transfer client funds (Money Mule risk)",
      "Recruiter uses free personal @yahoo.com email address"
    ],
    keywords: ["personal bank account", "cash handling", "crypto transfer", "urgent"],
    description: "Looking for an energetic assistant to receive client transfers into your personal bank account and convert them at designated kiosks. 10% commission per transaction.",
    status: "Waiting",
    decisionNote: ""
  },
  {
    id: "JOB-504",
    title: "Social Media Ad Posting Assistant (No Resume Needed)",
    company: "Alpha Media Venture",
    companyVerified: false,
    recruiterEmail: "alphamedia.jb@gmail.com",
    salary: "RM 4,500 – RM 7,000 / month",
    location: "Remote / Petaling Jaya",
    submittedAt: "2026-11-10",
    riskScore: 76,
    reasons: [
      "High salary with zero qualification or resume requirement",
      "Contains multiple high-risk scam n-grams from EMSCAD dataset"
    ],
    keywords: ["no resume", "easy money", "work from phone", "daily cash"],
    description: "Copy and paste ads on social media from your phone. No resume or experience needed. Daily cash settlement.",
    status: "Rejected",
    decisionNote: "Suspected job scam / upfront fee requested — Flagged at 76% AI risk for 'no resume' and 'daily cash' scam patterns."
  },
  {
    id: "JOB-505",
    title: "High-Commission Property & Forex Telemarketer",
    company: "Apex Wealth Partners",
    companyVerified: true,
    recruiterEmail: "talent@apexwealth.com.my",
    salary: "RM 1,500 Basic + Uncapped Commission",
    location: "Cheras, Kuala Lumpur",
    submittedAt: "2026-11-11",
    riskScore: 58,
    reasons: [
      "Heavy emphasis on 'uncapped commission' and cold-calling",
      "Job description is unusually brief (< 45 words)"
    ],
    keywords: ["uncapped commission", "cold calling", "fast money"],
    description: "Call high-net-worth leads for offshore wealth products. Uncapped commission structure where top performers make RM 20k/month.",
    status: "Waiting",
    decisionNote: ""
  },
  {
    id: "JOB-506",
    title: "Freelance Night-Shift Live Stream Host",
    company: "Starlight Media Sdn. Bhd.",
    companyVerified: true,
    recruiterEmail: "hr@starlightmedia.my",
    salary: "RM 3,500 – RM 6,000 / month",
    location: "Subang Jaya, Selangor",
    submittedAt: "2026-11-11",
    riskScore: 44,
    reasons: [
      "Wide salary variance; requests personal social media links upfront"
    ],
    keywords: ["night shift", "cash bonus"],
    description: "Host 4-hour evening e-commerce live streams for fashion and gadget brands. Base allowance plus sales commission.",
    status: "Waiting",
    decisionNote: ""
  },
  {
    id: "JOB-507",
    title: "Junior Customer Support Executive (Shift Basis)",
    company: "Cyberjaya Cloud FinTech Sdn. Bhd.",
    companyVerified: true,
    recruiterEmail: "grace.tan@cyberfintech.my",
    salary: "RM 2,800 – RM 3,400 / month",
    location: "Cyberjaya, Selangor",
    submittedAt: "2026-11-10",
    riskScore: 22,
    reasons: [
      "Verified corporate employer; minor flag for 'urgent hiring' phrase"
    ],
    keywords: ["urgent hiring"],
    description: "Handle merchant payment gateway inquiries via ticketing system and phone. Rotational shift allowance provided.",
    status: "Waiting",
    decisionNote: ""
  },
  {
    id: "JOB-508",
    title: "AI & Python Backend Engineer (FastAPI)",
    company: "Melaka Digital Labs Sdn. Bhd.",
    companyVerified: true,
    recruiterEmail: "careers@melakadigital.my",
    salary: "RM 4,000 – RM 5,200 / month",
    location: "Ayer Keroh, Melaka",
    submittedAt: "2026-11-11",
    riskScore: 15,
    reasons: [
      "Verified SSM employer (#54)",
      "Detailed technical requirements (Python, FastAPI, PostgreSQL, Docker)"
    ],
    keywords: [],
    description: "Build and maintain RESTful AI microservices using FastAPI, scikit-learn, and PostgreSQL. Collaborate with Flutter frontend engineers.",
    status: "Waiting",
    decisionNote: ""
  },
  {
    id: "JOB-509",
    title: "Predictive Maintenance IoT Engineer",
    company: "BPE Energy Sdn. Bhd.",
    companyVerified: false,
    recruiterEmail: "careers@bpe.com.my",
    salary: "RM 4,200 – RM 5,500 / month",
    location: "Shah Alam, Selangor",
    submittedAt: "2026-11-12",
    riskScore: 12,
    reasons: [
      "Low AI text risk (clear engineering scope & realistic salary)",
      "Note: Employer SSM verification (CMP-1002) is still Waiting in #54"
    ],
    keywords: [],
    description: "Deploy IoT earthing sensors and analyze motor vibration telemetry using BPE's ARTESIS predictive maintenance platform.",
    status: "Waiting",
    decisionNote: ""
  },
  {
    id: "JOB-510",
    title: "Mechanical & Electrical (M&E) Project Engineer",
    company: "Straits Technics Sdn. Bhd. (STSB)",
    companyVerified: true,
    recruiterEmail: "hr@straitstechnics.com.my",
    salary: "RM 3,800 – RM 4,800 / month",
    location: "Petaling Jaya, Selangor",
    submittedAt: "2026-11-09",
    riskScore: 10,
    reasons: [
      "Clear engineering scope, valid corporate domain, and standard EPF/SOCSO benefits"
    ],
    keywords: [],
    description: "Supervise EPCIC mechanical and water pump installation works across Selangor utility sites. Degree in Mechanical/Electrical Engineering required.",
    status: "Approved",
    decisionNote: ""
  },
  {
    id: "JOB-511",
    title: "Civil & Structural Site Engineer (CIDB G7 Projects)",
    company: "SBE Engineering Sdn. Bhd.",
    companyVerified: true,
    recruiterEmail: "admin@sbeengineering.com.my",
    salary: "RM 4,000 – RM 5,000 / month",
    location: "Kuala Lumpur",
    submittedAt: "2026-11-08",
    riskScore: 8,
    reasons: [
      "Verified CIDB G7 employer; zero fraud indicators detected"
    ],
    keywords: [],
    description: "Manage bridge expansion joint replacement and slope rehabilitation works. Coordinate site safety and QA/QC inspections.",
    status: "Approved",
    decisionNote: ""
  },
  {
    id: "JOB-512",
    title: "Graduate IC Design & Embedded Firmware Engineer",
    company: "Penang Silicon Microelectronics Sdn. Bhd.",
    companyVerified: true,
    recruiterEmail: "recruitment@penangsilicon.my",
    salary: "RM 4,500 – RM 5,400 / month",
    location: "Bayan Lepas, Penang",
    submittedAt: "2026-11-07",
    riskScore: 6,
    reasons: [
      "Verified Penang FIZ employer; detailed C/C++ and Verilog skill requirements"
    ],
    keywords: [],
    description: "Develop and validate embedded C++ firmware and RTL testbenches for automotive microcontrollers in Bayan Lepas FIZ.",
    status: "Approved",
    decisionNote: ""
  }
];

// Application state
let jobs = [];
let activeCardFilter = "all"; // 'all' | 'Waiting' | 'HighRisk' | 'Reviewed'
let currentPage = 1;
let pageSize = 5;
let targetApproveJobId = null;
let targetRejectJobId = null;
let activeInspectJobId = null;

/**
 * Display a feedback message at the bottom of the page.
 */
function showFeedback(text, isError = false) {
  const msgEl = document.getElementById("message");
  msgEl.textContent = text;
  msgEl.style.color = isError ? "var(--bad)" : "var(--sub)";
}

/**
 * Load job review records from mock/jobs-review.json (or future #60 FastAPI endpoint).
 * Falls back gracefully to FALLBACK_JOBS when opened via file:// in Chrome.
 */
async function loadJobs() {
  try {
    const response = await fetch("mock/jobs-review.json");
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const data = await response.json();
    if (!Array.isArray(data)) throw new Error("Invalid JSON format");
    jobs = data;
  } catch (error) {
    jobs = structuredClone(FALLBACK_JOBS);
  }
  renderJobsTable();
}

/**
 * Update the 4 clickable KPI cards and the "Displaying: ..." status badge.
 */
function updateKPIsAndActiveCard(filteredCount) {
  const waitingCount = jobs.filter((j) => j.status === "Waiting").length;
  const highRiskCount = jobs.filter((j) => j.riskScore >= 70).length;
  const reviewedCount = jobs.filter((j) => j.status !== "Waiting").length;

  document.getElementById("stat-total").textContent = jobs.length;
  document.getElementById("stat-waiting").textContent = waitingCount;
  document.getElementById("stat-high").textContent = highRiskCount;
  document.getElementById("stat-reviewed").textContent = reviewedCount;

  // Highlight active KPI card
  document.querySelectorAll(".kpi-card").forEach((card) => {
    const isSelected = card.dataset.filter === activeCardFilter;
    card.classList.toggle("active", isSelected);
    card.setAttribute("aria-selected", isSelected ? "true" : "false");
  });

  // Update the current view indicator badge next to table title
  const badgeEl = document.getElementById("current-view-badge");
  const labelMap = {
    all: "All job posts",
    Waiting: "Waiting review",
    HighRisk: "High AI risk (≥ 70%)",
    Reviewed: "Reviewed jobs (Approved / Rejected)"
  };
  badgeEl.textContent = `Displaying: ${labelMap[activeCardFilter]} (${filteredCount})`;
  badgeEl.className =
    activeCardFilter === "HighRisk"
      ? "status bad"
      : activeCardFilter === "Waiting"
      ? "status warn"
      : activeCardFilter === "Reviewed"
      ? "status ok"
      : "status info";
}

/**
 * Render numbered pagination controls (Prev, 1, 2, 3..., Next).
 */
function renderPagination(totalItems) {
  const summaryEl = document.getElementById("pagination-summary");
  const controlsEl = document.getElementById("pagination-controls");
  controlsEl.innerHTML = "";

  if (totalItems === 0) {
    summaryEl.textContent = "Showing 0 of 0 job postings";
    return;
  }

  const totalPages = Math.ceil(totalItems / pageSize);
  if (currentPage > totalPages) currentPage = totalPages;
  if (currentPage < 1) currentPage = 1;

  const startIdx = (currentPage - 1) * pageSize + 1;
  const endIdx = Math.min(currentPage * pageSize, totalItems);
  summaryEl.textContent = `Showing ${startIdx}–${endIdx} of ${totalItems} job postings`;

  const prevBtn = document.createElement("button");
  prevBtn.type = "button";
  prevBtn.className = "page-btn";
  prevBtn.textContent = "‹ Prev";
  prevBtn.disabled = currentPage === 1;
  prevBtn.addEventListener("click", () => {
    if (currentPage > 1) {
      currentPage--;
      renderJobsTable();
    }
  });
  controlsEl.appendChild(prevBtn);

  for (let p = 1; p <= totalPages; p++) {
    const pageBtn = document.createElement("button");
    pageBtn.type = "button";
    pageBtn.className = `page-btn ${p === currentPage ? "active" : ""}`;
    pageBtn.textContent = String(p);
    pageBtn.addEventListener("click", () => {
      currentPage = p;
      renderJobsTable();
    });
    controlsEl.appendChild(pageBtn);
  }

  const nextBtn = document.createElement("button");
  nextBtn.type = "button";
  nextBtn.className = "page-btn";
  nextBtn.textContent = "Next ›";
  nextBtn.disabled = currentPage === totalPages;
  nextBtn.addEventListener("click", () => {
    if (currentPage < totalPages) {
      currentPage++;
      renderJobsTable();
    }
  });
  controlsEl.appendChild(nextBtn);
}

/**
 * Render the Job Review table.
 * BUSINESS RULE #1: Always sort jobs by highest AI riskScore at the top (descending).
 */
function renderJobsTable() {
  const riskTier = document.getElementById("risk-level-select").value;
  const searchQuery = document.getElementById("search-input").value.trim().toLowerCase();
  document.getElementById("clear-search-btn").hidden = !searchQuery;

  const tbody = document.getElementById("jobs-tbody");
  tbody.innerHTML = "";

  // Core requirement #55: Sort highest AI risk score at the top
  const sortedJobs = [...jobs].sort((a, b) => b.riskScore - a.riskScore);

  // Filter by active KPI card + risk dropdown + search keyword
  const filtered = sortedJobs.filter((job) => {
    // 1. KPI Card filter
    let matchesCard = true;
    if (activeCardFilter === "Waiting") matchesCard = job.status === "Waiting";
    else if (activeCardFilter === "HighRisk") matchesCard = job.riskScore >= 70;
    else if (activeCardFilter === "Reviewed") matchesCard = job.status !== "Waiting";

    // 2. Risk tier dropdown filter
    let matchesTier = true;
    if (riskTier === "high") matchesTier = job.riskScore >= 70;
    else if (riskTier === "medium") matchesTier = job.riskScore >= 40 && job.riskScore < 70;
    else if (riskTier === "low") matchesTier = job.riskScore < 40;

    // 3. Search query filter
    const matchesSearch =
      !searchQuery ||
      job.id.toLowerCase().includes(searchQuery) ||
      job.title.toLowerCase().includes(searchQuery) ||
      job.company.toLowerCase().includes(searchQuery) ||
      job.location.toLowerCase().includes(searchQuery) ||
      (job.keywords || []).some((k) => k.toLowerCase().includes(searchQuery));

    return matchesCard && matchesTier && matchesSearch;
  });

  updateKPIsAndActiveCard(filtered.length);
  renderPagination(filtered.length);

  if (filtered.length === 0) {
    tbody.innerHTML = `
      <tr>
        <td colspan="6" class="muted" style="text-align:center; padding:28px;">
          No job postings match the selected card filter or search query.
        </td>
      </tr>
    `;
    return;
  }

  const startIndex = (currentPage - 1) * pageSize;
  const pageItems = filtered.slice(startIndex, startIndex + pageSize);

  pageItems.forEach((job) => {
    const tr = document.createElement("tr");

    const riskColor =
      job.riskScore >= 70 ? "var(--bad)" : job.riskScore >= 40 ? "var(--warn)" : "var(--ok)";
    const riskBadgeClass =
      job.riskScore >= 70 ? "bad" : job.riskScore >= 40 ? "warn" : "ok";
    const statusClass =
      job.status === "Approved" ? "ok" : job.status === "Rejected" ? "bad" : "warn";

    // Business Rule #3: Flag jobs posted by unverified companies (even if job text is Low Risk)
    const companyBadge = job.companyVerified
      ? `<span class="verify-pill verified">✓ Verified Company</span>`
      : `<span class="verify-pill unverified">⚠️ Unverified Company (#54)</span>`;

    const reasonsHtml = (job.reasons || [])
      .map((r) => `<li>${r}</li>`)
      .join("");

    const keywordsHtml = (job.keywords || [])
      .map((kw) => `<span class="tag bad-word">🚩 "${kw}"</span>`)
      .join("");

    const decisionNoteHtml = job.decisionNote
      ? `<div class="decision-note-box ${job.status === "Rejected" ? "rejected" : "override"}">
           <strong>${job.status === "Rejected" ? "Rejection reason:" : "Admin override note:"}</strong> ${job.decisionNote}
         </div>`
      : "";

    const isApproved = job.status === "Approved";
    const isRejected = job.status === "Rejected";

    tr.innerHTML = `
      <td>
        <button type="button" class="job-title-btn" onclick="openJobInspector('${job.id}')">
          ${job.title}
        </button>
        <div class="job-meta">
          <span>${job.id} • ${job.company}</span>
          ${companyBadge}
        </div>
        ${decisionNoteHtml}
      </td>
      <td>
        <div><strong>${job.salary}</strong></div>
        <div class="muted" style="font-size: 13px;">${job.location}</div>
      </td>
      <td>
        <div class="risk-wrap">
          <div><span class="status ${riskBadgeClass}">${job.riskScore}% Risk</span></div>
          <div class="risk-bar" title="AI Fraud Risk Score: ${job.riskScore}%">
            <div class="risk-fill" style="width: ${job.riskScore}%; background: ${riskColor};"></div>
          </div>
        </div>
      </td>
      <td>
        <ul class="reason-list-compact">${reasonsHtml}</ul>
        <div class="reason-tags">${keywordsHtml}</div>
      </td>
      <td><span class="status ${statusClass}">${job.status}</span></td>
      <td>
        <div class="action-btns">
          <button type="button" class="btn sm approve" ${isApproved ? "disabled" : ""} onclick="openApproveModal('${job.id}')">
            ${isApproved ? "Approved ✓" : "Approve"}
          </button>
          <button type="button" class="btn sm danger" ${isRejected ? "disabled" : ""} onclick="openRejectModal('${job.id}')">
            ${isRejected ? "Rejected ✕" : "Reject"}
          </button>
        </div>
      </td>
    `;
    tbody.appendChild(tr);
  });
}

/**
 * Open the Job Details & AI Risk Breakdown Inspector Modal.
 */
window.openJobInspector = function (jobId) {
  const job = jobs.find((j) => j.id === jobId);
  if (!job) return;

  activeInspectJobId = jobId;
  const riskBadgeClass =
    job.riskScore >= 70 ? "bad" : job.riskScore >= 40 ? "warn" : "ok";
  const statusClass =
    job.status === "Approved" ? "ok" : job.status === "Rejected" ? "bad" : "warn";

  document.getElementById("ins-job-title").textContent = job.title;
  document.getElementById("ins-job-sub").textContent = `${job.id} • Submitted on ${job.submittedAt}`;
  document.getElementById("ins-company").innerHTML = `${job.company} ${
    job.companyVerified
      ? '<span class="verify-pill verified">✓ Verified</span>'
      : '<span class="verify-pill unverified">⚠️ Unverified (#54)</span>'
  }`;
  document.getElementById("ins-salary").textContent = job.salary;
  document.getElementById("ins-location").textContent = job.location;
  document.getElementById("ins-email").textContent = job.recruiterEmail;
  document.getElementById("ins-description").textContent = job.description;

  document.getElementById("ins-risk-badge-wrap").innerHTML = `
    <span class="status ${riskBadgeClass}" style="font-size:14px;">AI Fraud Risk Score: ${job.riskScore}%</span>
  `;

  document.getElementById("ins-reasons-list").innerHTML = (job.reasons || [])
    .map((r) => `<li>${r}</li>`)
    .join("");

  document.getElementById("ins-keywords").innerHTML =
    job.keywords && job.keywords.length > 0
      ? job.keywords.map((kw) => `<span class="tag bad-word">🚩 "${kw}"</span>`).join("")
      : `<span class="muted" style="font-size:13px;">No suspicious trigger keywords detected.</span>`;

  document.getElementById("ins-status-label").innerHTML = `Current status: <span class="status ${statusClass}">${job.status}</span>`;
  document.getElementById("ins-approve-btn").disabled = job.status === "Approved";
  document.getElementById("ins-reject-btn").disabled = job.status === "Rejected";

  document.getElementById("job-modal").hidden = false;
};

document.getElementById("close-job-modal-btn").addEventListener("click", () => {
  document.getElementById("job-modal").hidden = true;
  activeInspectJobId = null;
});

document.getElementById("ins-approve-btn").addEventListener("click", () => {
  if (!activeInspectJobId) return;
  const id = activeInspectJobId;
  document.getElementById("job-modal").hidden = true;
  openApproveModal(id);
});

document.getElementById("ins-reject-btn").addEventListener("click", () => {
  if (!activeInspectJobId) return;
  const id = activeInspectJobId;
  document.getElementById("job-modal").hidden = true;
  openRejectModal(id);
});

/**
 * Open Approve Confirmation Modal.
 * BUSINESS RULE #2 & #3: If job.riskScore >= 70% OR !job.companyVerified,
 * display the warning box and require a mandatory Admin Override / Verification Note.
 */
window.openApproveModal = function (jobId) {
  const job = jobs.find((j) => j.id === jobId);
  if (!job) return;

  targetApproveJobId = jobId;
  document.getElementById("approve-modal-sub").textContent = `${job.title} • ${job.company} (AI Risk: ${job.riskScore}%)`;
  document.getElementById("approve-confirm-check").checked = false;
  document.getElementById("override-reason-input").value = "";
  document.getElementById("approve-error").hidden = true;

  const warningBox = document.getElementById("high-risk-warning-box");
  const alertTitle = document.getElementById("override-alert-title");
  const alertDesc = document.getElementById("override-alert-desc");

  if (job.riskScore >= 70 && !job.companyVerified) {
    alertTitle.textContent = `⚠️ High AI Risk (${job.riskScore}%) & Unverified Company (#54)`;
    alertDesc.textContent =
      "Business Rule: This job is flagged as high fraud risk AND the employer is not yet verified in #54. You must provide an override justification to publish.";
    warningBox.hidden = false;
  } else if (job.riskScore >= 70) {
    alertTitle.textContent = `⚠️ High AI Fraud Risk Warning (${job.riskScore}%)`;
    alertDesc.textContent =
      "Business Rule: This job was flagged as high risk by the AI detector. To override the AI warning and publish, provide a justification note below.";
    warningBox.hidden = false;
  } else if (!job.companyVerified) {
    alertTitle.textContent = `⚠️ Employer Pending Verification in #54 (AI Risk: ${job.riskScore}% Low)`;
    alertDesc.textContent =
      "Business Rule: Although the job description text has a low AI fraud score, this employer has not yet been approved in #54 Company Verification. Confirm SSM verification or enter an override note below.";
    warningBox.hidden = false;
  } else {
    warningBox.hidden = true;
  }

  document.getElementById("approve-modal").hidden = false;
};

document.getElementById("cancel-approve-btn").addEventListener("click", () => {
  document.getElementById("approve-modal").hidden = true;
  targetApproveJobId = null;
});

document.getElementById("confirm-approve-btn").addEventListener("click", () => {
  const job = jobs.find((j) => j.id === targetApproveJobId);
  if (!job) return;

  const isChecked = document.getElementById("approve-confirm-check").checked;
  const overrideText = document.getElementById("override-reason-input").value.trim();
  const errorEl = document.getElementById("approve-error");
  const requiresOverride = job.riskScore >= 70 || !job.companyVerified;

  // Validate Business Rule: High-risk or Unverified company jobs require >= 10 chars justification
  if (requiresOverride && overrideText.length < 10) {
    errorEl.textContent = "Please provide an override / verification justification note (at least 10 characters).";
    errorEl.hidden = false;
    document.getElementById("override-reason-input").focus();
    return;
  }

  if (!isChecked) {
    errorEl.textContent = "Please tick the confirmation checkbox before publishing this job.";
    errorEl.hidden = false;
    return;
  }

  job.status = "Approved";
  if (requiresOverride) {
    job.decisionNote = `Approved with Note: ${overrideText}`;
    job.companyVerified = true; // Mark verified once admin confirms
  } else {
    job.decisionNote = "";
  }
  showFeedback(`✅ Approved and published "${job.title}" (${job.id}).`);

  document.getElementById("approve-modal").hidden = true;
  targetApproveJobId = null;
  renderJobsTable();
});

/**
 * Open Mandatory Reject Job Modal.
 */
window.openRejectModal = function (jobId) {
  const job = jobs.find((j) => j.id === jobId);
  if (!job) return;

  targetRejectJobId = jobId;
  document.getElementById("reject-modal-sub").textContent = `${job.title} • ${job.company} (AI Risk: ${job.riskScore}%)`;
  document.getElementById("reject-reason-input").value = "";
  document.getElementById("reject-error").hidden = true;
  document.getElementById("reject-modal").hidden = false;
  document.getElementById("reject-reason-input").focus();
};

document.getElementById("cancel-reject-btn").addEventListener("click", () => {
  document.getElementById("reject-modal").hidden = true;
  targetRejectJobId = null;
});

document.getElementById("confirm-reject-btn").addEventListener("click", () => {
  const category = document.getElementById("reject-category").value;
  const details = document.getElementById("reject-reason-input").value.trim();
  const errorEl = document.getElementById("reject-error");

  if (details.length < 10) {
    errorEl.hidden = false;
    document.getElementById("reject-reason-input").focus();
    return;
  }

  const job = jobs.find((j) => j.id === targetRejectJobId);
  if (job) {
    job.status = "Rejected";
    job.decisionNote = `${category} — ${details}`;
    showFeedback(`🚫 Rejected "${job.title}" (${job.id}). Reason recorded: ${job.decisionNote}`);
  }

  document.getElementById("reject-modal").hidden = true;
  targetRejectJobId = null;
  renderJobsTable();
});

// Close modals on Escape key
document.addEventListener("keydown", (event) => {
  if (event.key === "Escape") {
    document.getElementById("job-modal").hidden = true;
    document.getElementById("approve-modal").hidden = true;
    document.getElementById("reject-modal").hidden = true;
  }
});

// Bind clickable KPI cards
document.querySelectorAll(".kpi-card").forEach((card) => {
  card.addEventListener("click", () => {
    activeCardFilter = card.dataset.filter;
    currentPage = 1;
    renderJobsTable();
  });
});

// Bind risk tier dropdown, search input, clear button, and page size selector
document.getElementById("risk-level-select").addEventListener("change", () => {
  currentPage = 1;
  renderJobsTable();
});

document.getElementById("search-input").addEventListener("input", () => {
  currentPage = 1;
  renderJobsTable();
});

document.getElementById("clear-search-btn").addEventListener("click", () => {
  document.getElementById("search-input").value = "";
  currentPage = 1;
  renderJobsTable();
});

document.getElementById("page-size-select").addEventListener("change", (event) => {
  pageSize = Number(event.target.value) || 5;
  currentPage = 1;
  renderJobsTable();
});

// Initialize page
loadJobs();