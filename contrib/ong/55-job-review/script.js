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
const FALLBACK_JOBS = [
  {
    id: "JOB-402",
    title: "Data Entry Clerk (Work From Home - Instant Pay)",
    company: "Global FastEarn Enterprise",
    salary: "RM 6,500 – RM 9,000 / month",
    location: "Remote (Anywhere)",
    riskScore: 94,
    reasons: [
      "Unrealistic salary for entry-level data entry",
      "Suspicious keywords: 'instant pay', 'WhatsApp only', 'registration fee'",
      "Recruiter email domain mismatch"
    ],
    status: "Waiting"
  },
  {
    id: "JOB-405",
    title: "Junior Administrative Assistant (No Experience Needed)",
    company: "QuickRich Global Marketing",
    salary: "RM 5,000 / week",
    location: "Johor Bahru (Remote option)",
    riskScore: 82,
    reasons: [
      "Trigger phrases: 'no experience', 'weekly payout', 'Telegram contact'",
      "Recruiter uses free personal email (@gmail.com)"
    ],
    status: "Waiting"
  },
  {
    id: "JOB-401",
    title: "Commission-Only Digital Marketing Executive",
    company: "Alpha Media Venture",
    salary: "Uncapped Commission",
    location: "Petaling Jaya, Selangor",
    riskScore: 54,
    reasons: [
      "Vague compensation structure ('uncapped commission')",
      "Short job description body (< 60 words)"
    ],
    status: "Waiting"
  },
  {
    id: "JOB-404",
    title: "Junior AI & Python Developer",
    company: "Melaka Digital Labs Sdn Bhd",
    salary: "RM 3,800 – RM 4,800 / month",
    location: "Ayer Keroh, Melaka",
    riskScore: 14,
    reasons: [
      "Verified SSM corporate employer account",
      "Clear technical stack requirements (Python, FastAPI, SQL)"
    ],
    status: "Waiting"
  },
  {
    id: "JOB-403",
    title: "Graduate Embedded Software Engineer",
    company: "Straits Precision Engineering Sdn Bhd",
    salary: "RM 4,200 – RM 5,000 / month",
    location: "Bayan Lepas, Penang",
    riskScore: 8,
    reasons: [
      "Standard market entry salary",
      "Detailed engineering responsibilities and valid office address"
    ],
    status: "Waiting"
  }
];

let jobs = [];

async function loadJobs() {
  try {
    const res = await fetch("mock/jobs-review.json");
    if (!res.ok) throw new Error("Failed to load jobs JSON");
    jobs = await res.json();
  } catch (err) {
    // Fallback if opened via file:// protocol
    jobs = structuredClone(FALLBACK_JOBS);
  }
  renderJobsTable();
}

function updateSummaryKPIs() {
  const pendingCount = jobs.filter((j) => j.status === "Waiting").length;
  const highRiskCount = jobs.filter((j) => j.riskScore >= 70 && j.status === "Waiting").length;
  const approvedCount = jobs.filter((j) => j.status === "Approved").length;

  document.getElementById("stat-pending").textContent = pendingCount;
  document.getElementById("stat-high").textContent = highRiskCount;
  document.getElementById("stat-approved").textContent = approvedCount;
}

function renderJobsTable() {
  updateSummaryKPIs();
  const riskFilter = document.getElementById("risk-filter").value;
  const searchQuery = document.getElementById("search-input").value.trim().toLowerCase();
  const tbody = document.getElementById("jobs-tbody");
  tbody.innerHTML = "";

  // CRITICAL REQUIREMENT #55: Sort highest risk score at the top (descending order)
  const sortedJobs = [...jobs].sort((a, b) => b.riskScore - a.riskScore);

  const filtered = sortedJobs.filter((job) => {
    // Filter by risk category
    let matchesRisk = true;
    if (riskFilter === "high") matchesRisk = job.riskScore >= 70;
    else if (riskFilter === "medium") matchesRisk = job.riskScore >= 40 && job.riskScore < 70;
    else if (riskFilter === "low") matchesRisk = job.riskScore < 40;

    // Filter by search query
    const matchesSearch =
      !searchQuery ||
      job.title.toLowerCase().includes(searchQuery) ||
      job.company.toLowerCase().includes(searchQuery) ||
      job.location.toLowerCase().includes(searchQuery);

    return matchesRisk && matchesSearch;
  });

  if (filtered.length === 0) {
    tbody.innerHTML = `<tr><td colspan="6" class="muted" style="text-align:center; padding:24px;">No job posts match the filter criteria.</td></tr>`;
    return;
  }

  filtered.forEach((job) => {
    const tr = document.createElement("tr");

    // Determine risk styling based on score threshold
    const riskColor = job.riskScore >= 70 ? "var(--bad)" : job.riskScore >= 40 ? "var(--warn)" : "var(--ok)";
    const riskBadgeClass = job.riskScore >= 70 ? "bad" : job.riskScore >= 40 ? "warn" : "ok";
    const statusClass = job.status === "Approved" ? "ok" : job.status === "Rejected" ? "bad" : "warn";

    const reasonsHtml = job.reasons.map((r) => `<span class="tag">${r}</span>`).join("");

    tr.innerHTML = `
      <td>
        <strong>${job.title}</strong>
        <div class="muted" style="font-size: 13px;">${job.company} (${job.id})</div>
      </td>
      <td>
        <div>${job.salary}</div>
        <div class="muted" style="font-size: 13px;">${job.location}</div>
      </td>
      <td>
        <div class="risk-wrap" style="color: ${riskColor};">
          <span class="status ${riskBadgeClass}">${job.riskScore}%</span>
          <div class="risk-bar" title="AI Fraud Risk Score: ${job.riskScore}%">
            <div class="risk-fill" style="width: ${job.riskScore}%; background: ${riskColor};"></div>
          </div>
        </div>
      </td>
      <td><div class="reason-tags">${reasonsHtml}</div></td>
      <td><span class="status ${statusClass}">${job.status}</span></td>
      <td>
        <div class="action-btns">
          <button type="button" class="btn sm approve" onclick="handleJobAction('${job.id}', 'Approved')">Approve</button>
          <button type="button" class="btn sm danger" onclick="handleJobAction('${job.id}', 'Rejected')">Reject</button>
        </div>
      </td>
    `;
    tbody.appendChild(tr);
  });
}

window.handleJobAction = function (jobId, newStatus) {
  const job = jobs.find((j) => j.id === jobId);
  if (!job) return;
  job.status = newStatus;

  const msg =
    newStatus === "Approved"
      ? `✅ Approved "${job.title}" (${job.id}). Listing is now published.`
      : `🚫 Rejected "${job.title}" (${job.id}) due to high AI risk score (${job.riskScore}%).`;
  document.getElementById("message").textContent = msg;

  renderJobsTable();
};

// Event listeners for filter and search
document.getElementById("risk-filter").addEventListener("change", renderJobsTable);
document.getElementById("search-input").addEventListener("input", renderJobsTable);

// Initialize
loadJobs();