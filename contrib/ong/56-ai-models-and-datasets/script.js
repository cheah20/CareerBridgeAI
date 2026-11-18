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
const FALLBACK_DATA = {
  models: [
    {
      id: "MDL-61-V13",
      version: "v1.3-rc1",
      name: "Random Forest + Bigram TF-IDF (Tuned)",
      pipeline: "Suspicious Job Detection",
      accuracy: 97.9,
      precision: 95.1,
      recall: 89.4,
      f1: 92.2,
      trainedDate: "2026-11-12",
      dataset: "EMSCAD (17,880 jobs)",
      active: false,
      actionType: "Deploy",
      features: ["registration fee", "whatsapp only", "instant payout", "no experience", "telegram"],
      notes: "Candidate build with 5,000 bigram TF-IDF features and class_weight='balanced_subsample'. Ready for production deployment.",
      deployNote: ""
    },
    {
      id: "MDL-61-V12",
      version: "v1.2-prod",
      name: "Random Forest Classifier (200 Trees)",
      pipeline: "Suspicious Job Detection",
      accuracy: 97.4,
      precision: 94.2,
      recall: 88.5,
      f1: 91.2,
      trainedDate: "2026-11-10",
      dataset: "EMSCAD (17,880 jobs)",
      active: true,
      actionType: "Roll back",
      features: ["daily payout", "work from home", "uncapped commission", "gmail.com", "urgent hiring"],
      notes: "Current production model serving the #55 Job Review risk score column.",
      deployNote: "Deployed as primary fraud detector after outperforming Logistic Regression baseline on F1 (+4.7%)."
    },
    {
      id: "MDL-61-V11",
      version: "v1.1-baseline",
      name: "Logistic Regression (L2 Regularized)",
      pipeline: "Suspicious Job Detection",
      accuracy: 95.8,
      precision: 89.6,
      recall: 83.6,
      f1: 86.5,
      trainedDate: "2026-11-04",
      dataset: "EMSCAD (17,880 jobs)",
      active: false,
      actionType: "Roll back",
      features: ["cash handling", "no resume", "weekly payout", "personal bank account"],
      notes: "Fast linear baseline trained in Task #61 for direct comparison against Random Forest.",
      deployNote: ""
    },
    {
      id: "MDL-61-V10",
      version: "v1.0-heuristic",
      name: "Rule-Based Keyword Filter",
      pipeline: "Suspicious Job Detection",
      accuracy: 88.2,
      precision: 76.4,
      recall: 68.1,
      f1: 72.0,
      trainedDate: "2026-10-19",
      dataset: "Manual Scam Keyword List (120 rules)",
      active: false,
      actionType: "Roll back",
      features: ["registration fee", "fast money", "crypto transfer"],
      notes: "Initial static regex/keyword heuristic used prior to ML training.",
      deployNote: ""
    },
    {
      id: "MDL-62-V11",
      version: "v1.1-prod",
      name: "pdfplumber BBox & Table Geometry Analyzer",
      pipeline: "Resume Layout Check",
      accuracy: 96.0,
      precision: 95.0,
      recall: 96.5,
      f1: 95.7,
      trainedDate: "2026-11-11",
      dataset: "Synthetic Resume PDF Corpus (10 PDFs)",
      active: true,
      actionType: "Roll back",
      features: ["x0/x1 gutter gap detection", "page.extract_tables()", "multi-column word clustering"],
      notes: "Production layout engine for Resume X-Ray (#62); detects two-column layouts and embedded tables accurately.",
      deployNote: "Active layout checker for seeker resume uploads."
    },
    {
      id: "MDL-62-V10",
      version: "v1.0-baseline",
      name: "Line-Break & Whitespace Gap Heuristic",
      pipeline: "Resume Layout Check",
      accuracy: 80.0,
      precision: 81.2,
      recall: 78.0,
      f1: 79.6,
      trainedDate: "2026-10-25",
      dataset: "Synthetic Resume PDF Corpus (10 PDFs)",
      active: false,
      actionType: "Roll back",
      features: ["consecutive spaces", "tab character count"],
      notes: "Early text-only layout heuristic; struggled with borderless PDF tables.",
      deployNote: ""
    },
    {
      id: "MDL-FIT-V21",
      version: "v2.1-prod",
      name: "Fine-Tuned MiniLM + Role Skill Graph",
      pipeline: "Resume-Role Fit Scoring",
      accuracy: 94.2,
      precision: 93.8,
      recall: 95.1,
      f1: 94.4,
      trainedDate: "2026-11-08",
      dataset: "Malaysian Roles & Synthetic Resumes (1,100 pairs)",
      active: true,
      actionType: "Roll back",
      features: ["semantic skill embedding", "core/nice-to-have skill overlap", "experience level weight"],
      notes: "Active semantic matcher powering CareerBridge role recommendations.",
      deployNote: ""
    },
    {
      id: "MDL-FIT-V20",
      version: "v2.0-baseline",
      name: "TF-IDF Cosine Similarity Matcher",
      pipeline: "Resume-Role Fit Scoring",
      accuracy: 89.5,
      precision: 88.2,
      recall: 89.6,
      f1: 88.9,
      trainedDate: "2026-10-22",
      dataset: "Malaysian Roles Catalog (110 roles)",
      active: false,
      actionType: "Roll back",
      features: ["exact skill token match", "TF-IDF cosine score"],
      notes: "Lightweight lexical baseline used when GPU/transformer weights are unavailable.",
      deployNote: ""
    }
  ],
  datasets: [
    {
      id: "DS-EMSCAD-01",
      name: "EMSCAD (Employment Scam Aegean Dataset)",
      pipeline: "Suspicious Job Detection (#61)",
      records: "17,880 job posts (17,014 real / 866 fraudulent)",
      split: "80% Train / 20% Stratified Test",
      license: "CC0: Public Domain (Kaggle)",
      sourceUrl: "https://www.kaggle.com/datasets/shivamb/real-or-fake-fake-jobposting-prediction",
      updatedAt: "2026-11-01"
    },
    {
      id: "DS-LAYOUT-02",
      name: "Synthetic Resume Layout PDF Corpus",
      pipeline: "Resume Layout Check (#62)",
      records: "10 PDFs (4 clean single-column, 3 two-column, 3 with tables)",
      split: "100% Validation Benchmark",
      license: "Internal Synthetic (No PII)",
      sourceUrl: "../56-ai-models-and-datasets/index.html",
      updatedAt: "2026-11-11"
    },
    {
      id: "DS-ROLES-03",
      name: "Malaysian ICT & Engineering Roles Catalog",
      pipeline: "Resume-Role Fit Scoring",
      records: "110 Malaysian job roles across 12 industry sectors",
      split: "Reference Knowledge Base",
      license: "Internal Curated (MASCO Aligned)",
      sourceUrl: "../56-ai-models-and-datasets/index.html",
      updatedAt: "2026-10-28"
    },
    {
      id: "DS-SYNTH-04",
      name: "Malaysian Graduate Synthetic Resume Set",
      pipeline: "Resume-Role Fit Scoring",
      records: "1,100 synthetic resume-to-role labeled pairs",
      split: "85% Train / 15% Validation",
      license: "Internal Synthetic (Faker / No Real PII)",
      sourceUrl: "../56-ai-models-and-datasets/index.html",
      updatedAt: "2026-11-05"
    }
  ]
};

// Application state
let models = [];
let datasets = [];
let activeKpiFilter = "all"; // 'all' | 'Active' | 'Suspicious Job Detection' | 'Standby'
let currentPage = 1;
let pageSize = 5;
let targetSwitchModelId = null;
let activeInspectModelId = null;

/**
 * Show a status message in the bottom feedback bar.
 */
function showFeedback(text, isError = false) {
  const msgEl = document.getElementById("message");
  msgEl.textContent = text;
  msgEl.style.color = isError ? "var(--bad)" : "var(--sub)";
}

/**
 * Load models and datasets from mock/models-datasets.json (with local file:// fallback).
 */
async function loadModelsAndDatasets() {
  try {
    const response = await fetch("mock/models-datasets.json");
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const data = await response.json();
    models = data.models || [];
    datasets = data.datasets || [];
  } catch (error) {
    const clone = structuredClone(FALLBACK_DATA);
    models = clone.models;
    datasets = clone.datasets;
  }
  renderModelsTable();
  renderDatasetsTable();
}

/**
 * Update the 4 clickable KPI summary cards and active highlight.
 */
function updateKPIsAndActiveCard(filteredCount) {
  const activeCount = models.filter((m) => m.active).length;
  const standbyCount = models.filter((m) => !m.active).length;
  const activeFraudModel = models.find((m) => m.pipeline === "Suspicious Job Detection" && m.active);

  document.getElementById("stat-total-models").textContent = models.length;
  document.getElementById("stat-active-models").textContent = activeCount;
  document.getElementById("stat-standby-models").textContent = standbyCount;

  if (activeFraudModel) {
    document.getElementById("stat-fraud-acc").textContent = `${activeFraudModel.accuracy.toFixed(1)}%`;
    document.getElementById("stat-fraud-sub").textContent = `Active: ${activeFraudModel.version} (F1 ${activeFraudModel.f1.toFixed(1)}%)`;
  }

  // Highlight whichever KPI card is selected
  document.querySelectorAll(".kpi-card").forEach((card) => {
    const isSelected = card.dataset.filter === activeKpiFilter;
    card.classList.toggle("active", isSelected);
    card.setAttribute("aria-selected", isSelected ? "true" : "false");
  });

  // Update "Displaying: ..." badge
  const badgeEl = document.getElementById("current-view-badge");
  const labelMap = {
    all: "All Model Versions",
    Active: "Active Production Models",
    "Suspicious Job Detection": "Job Fraud Detection Models (#61)",
    Standby: "Standby / Rollback Versions"
  };
  badgeEl.textContent = `Displaying: ${labelMap[activeKpiFilter] || activeKpiFilter} (${filteredCount})`;
  badgeEl.className =
    activeKpiFilter === "Active"
      ? "status ok"
      : activeKpiFilter === "Standby"
      ? "status warn"
      : "status info";
}

/**
 * Render numbered pagination buttons (Prev, 1, 2..., Next).
 */
function renderPagination(totalItems) {
  const summaryEl = document.getElementById("pagination-summary");
  const controlsEl = document.getElementById("pagination-controls");
  controlsEl.innerHTML = "";

  if (totalItems === 0) {
    summaryEl.textContent = "Showing 0 of 0 models";
    return;
  }

  const totalPages = Math.ceil(totalItems / pageSize);
  if (currentPage > totalPages) currentPage = totalPages;
  if (currentPage < 1) currentPage = 1;

  const startIdx = (currentPage - 1) * pageSize + 1;
  const endIdx = Math.min(currentPage * pageSize, totalItems);
  summaryEl.textContent = `Showing ${startIdx}–${endIdx} of ${totalItems} model versions`;

  const prevBtn = document.createElement("button");
  prevBtn.type = "button";
  prevBtn.className = "page-btn";
  prevBtn.textContent = "‹ Prev";
  prevBtn.disabled = currentPage === 1;
  prevBtn.addEventListener("click", () => {
    if (currentPage > 1) {
      currentPage--;
      renderModelsTable();
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
      renderModelsTable();
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
      renderModelsTable();
    }
  });
  controlsEl.appendChild(nextBtn);
}

/**
 * Render the AI Model Versions table according to active KPI card, pipeline filter, search, and pagination.
 */
function renderModelsTable() {
  const pipelineVal = document.getElementById("pipeline-select").value;
  const searchQuery = document.getElementById("search-input").value.trim().toLowerCase();
  document.getElementById("clear-search-btn").hidden = !searchQuery;

  const tbody = document.getElementById("models-tbody");
  tbody.innerHTML = "";

  const filtered = models.filter((m) => {
    // 1. KPI Card Filter
    let matchesCard = true;
    if (activeKpiFilter === "Active") matchesCard = m.active === true;
    else if (activeKpiFilter === "Standby") matchesCard = m.active === false;
    else if (activeKpiFilter === "Suspicious Job Detection") matchesCard = m.pipeline === "Suspicious Job Detection";

    // 2. Pipeline Dropdown Filter
    const matchesPipeline = pipelineVal === "all" || m.pipeline === pipelineVal;

    // 3. Search Query Filter
    const matchesSearch =
      !searchQuery ||
      m.version.toLowerCase().includes(searchQuery) ||
      m.name.toLowerCase().includes(searchQuery) ||
      m.pipeline.toLowerCase().includes(searchQuery) ||
      m.dataset.toLowerCase().includes(searchQuery);

    return matchesCard && matchesPipeline && matchesSearch;
  });

  updateKPIsAndActiveCard(filtered.length);
  renderPagination(filtered.length);

  if (filtered.length === 0) {
    tbody.innerHTML = `
      <tr>
        <td colspan="7" class="muted" style="text-align:center; padding:28px;">
          No AI model versions match the selected filter or search query.
        </td>
      </tr>
    `;
    return;
  }

  const startIndex = (currentPage - 1) * pageSize;
  const pageItems = filtered.slice(startIndex, startIndex + pageSize);

  pageItems.forEach((m) => {
    const tr = document.createElement("tr");
    if (m.active) tr.className = "active-model-row";

    const statusBadge = m.active
      ? `<span class="status ok">● Active (In Use)</span>`
      : `<span class="status info">Standby</span>`;

    const deployNoteHtml = m.deployNote
      ? `<div class="deploy-note-box"><strong>Deployment note:</strong> ${m.deployNote}</div>`
      : "";

    // Determine whether button should say "Deploy" or "Roll back"
    const isDeployAction = m.actionType === "Deploy";
    const actionBtnHtml = m.active
      ? `<button type="button" class="btn sm" disabled>In Production ✓</button>`
      : `<button type="button" class="btn sm ${isDeployAction ? "deploy" : "rollback"}" onclick="openSwitchModal('${m.id}')">
           ${isDeployAction ? "🚀 Deploy" : "↩ Roll back"}
         </button>`;

    tr.innerHTML = `
      <td>
        <div style="display:flex; align-items:center; gap:8px; flex-wrap:wrap;">
          <span class="version-code">${m.version}</span>
          <button type="button" class="model-name-btn" onclick="openModelInspector('${m.id}')">
            ${m.name}
          </button>
        </div>
        <div class="model-meta">Dataset: ${m.dataset}</div>
        ${deployNoteHtml}
      </td>
      <td><strong>${m.pipeline}</strong></td>
      <td>
        <div class="acc-wrap">
          <strong>${m.accuracy.toFixed(1)}%</strong>
          <div class="acc-bar"><div class="acc-fill" style="width: ${m.accuracy}%;"></div></div>
        </div>
      </td>
      <td>
        <div class="metric-pills">
          <span class="metric-pill">P: ${m.precision.toFixed(1)}%</span>
          <span class="metric-pill">R: ${m.recall.toFixed(1)}%</span>
          <span class="metric-pill"><strong>F1: ${m.f1.toFixed(1)}%</strong></span>
        </div>
      </td>
      <td>${m.trainedDate}</td>
      <td>${statusBadge}</td>
      <td>
        <div class="action-btns">
          ${actionBtnHtml}
          <button type="button" class="btn sm" onclick="openModelInspector('${m.id}')">Details</button>
        </div>
      </td>
    `;
    tbody.appendChild(tr);
  });
}

/**
 * Render the Training & Evaluation Datasets table.
 */
function renderDatasetsTable() {
  const tbody = document.getElementById("datasets-tbody");
  tbody.innerHTML = "";
  document.getElementById("dataset-count-badge").textContent = `${datasets.length} Verified Datasets`;

  datasets.forEach((ds) => {
    const tr = document.createElement("tr");
    const isExternal = ds.sourceUrl.startsWith("http");
    const licenseBadge = ds.license.includes("CC0")
      ? `<span class="status info">${ds.license}</span>`
      : `<span class="status ok">${ds.license}</span>`;

    tr.innerHTML = `
      <td>
        <strong>${ds.name}</strong>
        <div class="model-meta">ID: <code>${ds.id}</code></div>
      </td>
      <td><strong>${ds.pipeline}</strong></td>
      <td>
        <div>${ds.records}</div>
        <div class="model-meta">${ds.split}</div>
      </td>
      <td>
        <div>${licenseBadge}</div>
        ${
          isExternal
            ? `<div style="margin-top:4px;"><a href="${ds.sourceUrl}" target="_blank" rel="noopener noreferrer" style="font-size:12px; font-weight:600;">View Dataset Source ↗</a></div>`
            : ""
        }
      </td>
      <td>${ds.updatedAt}</td>
    `;
    tbody.appendChild(tr);
  });
}

/**
 * Open the Model Inspector Modal to view full Precision, Recall, F1, and top features.
 */
window.openModelInspector = function (modelId) {
  const m = models.find((item) => item.id === modelId);
  if (!m) return;

  activeInspectModelId = modelId;
  document.getElementById("ins-model-title").textContent = `${m.version} — ${m.name}`;
  document.getElementById("ins-model-sub").textContent = `Model ID: ${m.id} • Pipeline: ${m.pipeline}`;
  document.getElementById("ins-pipeline").textContent = m.pipeline;
  document.getElementById("ins-algorithm").textContent = `${m.version} (${m.name})`;
  document.getElementById("ins-dataset").textContent = m.dataset;
  document.getElementById("ins-date").textContent = m.trainedDate;
  document.getElementById("ins-notes").textContent = m.notes;

  document.getElementById("ins-acc").textContent = `${m.accuracy.toFixed(1)}%`;
  document.getElementById("ins-prec").textContent = `${m.precision.toFixed(1)}%`;
  document.getElementById("ins-rec").textContent = `${m.recall.toFixed(1)}%`;
  document.getElementById("ins-f1").textContent = `${m.f1.toFixed(1)}%`;

  document.getElementById("ins-features").innerHTML = (m.features || [])
    .map((f) => `<span class="feature-tag">${f}</span>`)
    .join("");

  document.getElementById("ins-status-badge").innerHTML = m.active
    ? `<span class="status ok">● Active (In Use)</span>`
    : `<span class="status info">Standby</span>`;

  const actionBtn = document.getElementById("ins-action-btn");
  actionBtn.disabled = m.active;
  actionBtn.textContent = m.active
    ? "Currently Active in Production"
    : m.actionType === "Deploy"
    ? `🚀 Deploy ${m.version}`
    : `↩ Roll back to ${m.version}`;

  document.getElementById("inspector-modal").hidden = false;
};

document.getElementById("close-inspector-btn").addEventListener("click", () => {
  document.getElementById("inspector-modal").hidden = true;
  activeInspectModelId = null;
});

document.getElementById("ins-action-btn").addEventListener("click", () => {
  if (!activeInspectModelId) return;
  const id = activeInspectModelId;
  document.getElementById("inspector-modal").hidden = true;
  openSwitchModal(id);
});

/**
 * Open the Deploy / Roll Back Confirmation Modal.
 * Compares Target Model against Current Active Model in the same pipeline.
 */
window.openSwitchModal = function (modelId) {
  const targetModel = models.find((m) => m.id === modelId);
  if (!targetModel || targetModel.active) return;

  targetSwitchModelId = modelId;
  const currentActive = models.find((m) => m.pipeline === targetModel.pipeline && m.active);

  const isRollback = targetModel.actionType === "Roll back";
  document.getElementById("switch-modal-title").textContent = isRollback
    ? `Roll back ${targetModel.pipeline} model`
    : `Deploy ${targetModel.pipeline} model`;
  document.getElementById("switch-modal-sub").textContent = `Pipeline: ${targetModel.pipeline}`;

  // Populate side-by-side comparison box
  if (currentActive) {
    document.getElementById("cmp-curr-ver").textContent = `${currentActive.version} (${currentActive.name})`;
    document.getElementById("cmp-curr-metrics").textContent = `Accuracy: ${currentActive.accuracy.toFixed(1)}% • F1: ${currentActive.f1.toFixed(1)}%`;
  } else {
    document.getElementById("cmp-curr-ver").textContent = "None";
    document.getElementById("cmp-curr-metrics").textContent = "—";
  }

  const accDelta = currentActive ? (targetModel.accuracy - currentActive.accuracy).toFixed(1) : "0.0";
  const deltaSign = Number(accDelta) >= 0 ? `+${accDelta}%` : `${accDelta}%`;

  document.getElementById("cmp-target-ver").textContent = `${targetModel.version} (${targetModel.name})`;
  document.getElementById("cmp-target-metrics").textContent = `Accuracy: ${targetModel.accuracy.toFixed(1)}% (${deltaSign}) • F1: ${targetModel.f1.toFixed(1)}%`;

  // Business Rule #2: Require mandatory reason if rolling back OR if accuracy is lower than current active
  const isRegression = currentActive && targetModel.accuracy < currentActive.accuracy;
  const warningBox = document.getElementById("regression-warning-box");
  if (isRollback || isRegression) {
    document.getElementById("regression-title").textContent = isRegression
      ? `⚠️ Accuracy Regression Warning (${deltaSign} Accuracy)`
      : `⚠️ Model Rollback Confirmation`;
    document.getElementById("regression-desc").textContent =
      "Business Rule: Rolling back to an earlier model version or switching to a lower-accuracy model requires an audit reason note.";
    warningBox.hidden = false;
  } else {
    warningBox.hidden = true;
  }

  document.getElementById("switch-reason-input").value = "";
  document.getElementById("switch-confirm-check").checked = false;
  document.getElementById("switch-error").hidden = true;
  document.getElementById("switch-modal").hidden = false;
};

document.getElementById("cancel-switch-btn").addEventListener("click", () => {
  document.getElementById("switch-modal").hidden = true;
  targetSwitchModelId = null;
});

document.getElementById("confirm-switch-btn").addEventListener("click", () => {
  const targetModel = models.find((m) => m.id === targetSwitchModelId);
  if (!targetModel) return;

  const currentActive = models.find((m) => m.pipeline === targetModel.pipeline && m.active);
  const isRollback = targetModel.actionType === "Roll back";
  const isRegression = currentActive && targetModel.accuracy < currentActive.accuracy;
  const requiresReason = isRollback || isRegression;

  const reasonText = document.getElementById("switch-reason-input").value.trim();
  const isChecked = document.getElementById("switch-confirm-check").checked;
  const errorEl = document.getElementById("switch-error");

  if (requiresReason && reasonText.length < 10) {
    errorEl.textContent = "Please enter a clear rollback/deployment reason (at least 10 characters).";
    errorEl.hidden = false;
    document.getElementById("switch-reason-input").focus();
    return;
  }

  if (!isChecked) {
    errorEl.textContent = "Please tick the confirmation checkbox to switch the active production model.";
    errorEl.hidden = false;
    return;
  }

  // Business Rule #1: Deactivate previous active model in the same pipeline and activate target model
  models.forEach((m) => {
    if (m.pipeline === targetModel.pipeline) {
      if (m.id === targetModel.id) {
        m.active = true;
        m.deployNote = reasonText
          ? `${isRollback ? "Rolled back" : "Deployed"}: ${reasonText}`
          : `Promoted ${targetModel.version} to active production.`;
      } else {
        m.active = false;
      }
    }
  });

  showFeedback(
    `✅ ${isRollback ? "Rolled back" : "Deployed"} "${targetModel.pipeline}" to ${targetModel.version} (Accuracy: ${targetModel.accuracy.toFixed(1)}%).`
  );

  document.getElementById("switch-modal").hidden = true;
  targetSwitchModelId = null;
  renderModelsTable();
});

// Escape key closes modals
document.addEventListener("keydown", (event) => {
  if (event.key === "Escape") {
    document.getElementById("inspector-modal").hidden = true;
    document.getElementById("switch-modal").hidden = true;
  }
});

// Bind Clickable KPI Cards
document.querySelectorAll(".kpi-card").forEach((card) => {
  card.addEventListener("click", () => {
    activeKpiFilter = card.dataset.filter;
    if (activeKpiFilter === "Suspicious Job Detection") {
      document.getElementById("pipeline-select").value = "Suspicious Job Detection";
    } else {
      document.getElementById("pipeline-select").value = "all";
    }
    currentPage = 1;
    renderModelsTable();
  });
});

// Bind Pipeline Select, Search Input, Clear Button, and Page Size Selector
document.getElementById("pipeline-select").addEventListener("change", () => {
  currentPage = 1;
  renderModelsTable();
});

document.getElementById("search-input").addEventListener("input", () => {
  currentPage = 1;
  renderModelsTable();
});

document.getElementById("clear-search-btn").addEventListener("click", () => {
  document.getElementById("search-input").value = "";
  currentPage = 1;
  renderModelsTable();
});

document.getElementById("page-size-select").addEventListener("change", (event) => {
  pageSize = Number(event.target.value) || 5;
  currentPage = 1;
  renderModelsTable();
});

// Initialize page
loadModelsAndDatasets();