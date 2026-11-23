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
const POOL_SIZE = 400;
const REQUIREMENTS = [
  { id: "flutter", label: "Skill: Flutter", shutout: 245, enabled: true },
  { id: "dart", label: "Skill: Dart", shutout: 268, enabled: true },
  { id: "rest", label: "Skill: REST API", shutout: 192, enabled: true },
  { id: "exp", label: "Experience: 1+ Year", shutout: 294, enabled: true },
  { id: "edu", label: "Education: Bachelor's Degree", shutout: 164, enabled: true },
  { id: "loc", label: "Location: KL / Selangor", shutout: 148, enabled: true }
];

const reqListEl = document.getElementById("requirementsList");
const barsEl = document.getElementById("shutoutBars");
const fitCountEl = document.getElementById("fitCount");
const fitRateEl = document.getElementById("fitRate");
const topBlockerNameEl = document.getElementById("topBlockerName");
const topBlockerLossEl = document.getElementById("topBlockerLoss");
const activeReqCountEl = document.getElementById("activeReqCount");
const resetBtn = document.getElementById("resetSimBtn");

function computeFitCount() {
  const active = REQUIREMENTS.filter(r => r.enabled);
  if (active.length === 0) return POOL_SIZE;
  let remaining = POOL_SIZE;
  active.forEach((r, idx) => {
    const dropFactor = (r.shutout / POOL_SIZE) * (idx === 0 ? 0.85 : 0.42);
    remaining = Math.max(8, Math.round(remaining * (1 - dropFactor)));
  });
  return remaining;
}

function render() {
  const active = REQUIREMENTS.filter(r => r.enabled);
  activeReqCountEl.textContent = String(active.length);

  const fit = computeFitCount();
  const pct = ((fit / POOL_SIZE) * 100).toFixed(1);
  fitCountEl.textContent = String(fit);
  fitRateEl.textContent = `${pct}% of ${POOL_SIZE} simulated profiles`;

  const poolForBlocker = active.length > 0 ? active : REQUIREMENTS;
  const sortedByShutout = [...poolForBlocker].sort((a, b) => b.shutout - a.shutout);
  const top = sortedByShutout[0];

  if (top) {
    topBlockerNameEl.textContent = top.label.replace(/^(Skill|Experience|Education|Location):\s*/, "");
    topBlockerLossEl.textContent = `Excludes ${top.shutout} of ${POOL_SIZE} profiles`;
  }

  reqListEl.innerHTML = REQUIREMENTS.map(r => `
    <label class="req-row" style="margin-top:0; cursor:pointer;">
      <span style="display:flex; align-items:center; gap:10px; font-weight:500;">
        <input type="checkbox" data-req-id="${r.id}" ${r.enabled ? "checked" : ""} style="width:auto; margin:0;">
        <span>${r.label}</span>
      </span>
      <span class="muted" style="font-size:12px;">-${r.shutout} profiles</span>
    </label>
  `).join("");

  const barsSorted = [...REQUIREMENTS].sort((a, b) => b.shutout - a.shutout);
  const highestId = barsSorted[0]?.id;

  barsEl.innerHTML = barsSorted.map(r => {
    const widthPct = Math.round((r.shutout / POOL_SIZE) * 100);
    const isTop = r.id === highestId && r.enabled;
    const opacityStyle = r.enabled ? "" : "opacity:0.45;";
    return `
      <div class="bar-item" style="${opacityStyle}">
        <div class="bar-header">
          <strong>${r.label}</strong>
          <span><strong>${r.shutout}</strong> / ${POOL_SIZE} shut out (${widthPct}%)</span>
        </div>
        <div class="bar-track">
          <div class="bar-fill ${isTop ? "top-blocker" : ""}" style="width:${widthPct}%;"></div>
        </div>
      </div>
    `;
  }).join("");

  reqListEl.querySelectorAll("input[type='checkbox']").forEach(cb => {
    cb.addEventListener("change", (e) => {
      const id = e.target.dataset.reqId;
      const item = REQUIREMENTS.find(x => x.id === id);
      if (item) item.enabled = e.target.checked;
      render();
    });
  });
}

resetBtn.addEventListener("click", () => {
  REQUIREMENTS.forEach(r => { r.enabled = true; });
  render();
});

render();