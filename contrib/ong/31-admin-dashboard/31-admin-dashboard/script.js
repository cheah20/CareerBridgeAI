// Example 1: Tabs functionality - show/hide matching panels based on button clicks
document.querySelectorAll(".tabs button").forEach((button) => {
  button.addEventListener("click", () => {
    document.querySelectorAll(".tabs button").forEach((b) =>
      b.classList.toggle("active", b === button)
    );
    document.querySelectorAll("[data-panel]").forEach(
      (p) => (p.hidden = p.dataset.panel !== button.dataset.tab)
    );
  });
});

// Example 2: Demo buttons that show a demo message when clicked
document.querySelectorAll("[data-demo]").forEach((button) => {
  button.addEventListener("click", () => {
    document.getElementById("message").textContent = button.dataset.demo;
  });
});

// ---- Your own code below this line ----

// Mock backend data for the dashboard (fake data for display)
const dashboardData = {
  usersPerRole: {
    total: 12845,
    jobSeekers: 10240,
    recruiters: 2580,
    admins: 25,
  },
  systemOperations: {
    pendingCompanyReviews: 18,
    pendingJobReviews: 42,
    activeApplications: 3491,
    apiUsageToday: "842k",
  },
  aiModel: {
    version: "v2.4.1-stable",
    lastUpdated: "24 Oct 2026",
    status: "Online",
  },
  recentErrors: {
    criticalErrors: 0,
    warningAlerts: 3,
    systemHealth: "Good",
  },
};

// Update the dashboard display using the passed data object
function updateDashboard(data) {
  console.log("updateDashboard is called");
  try {
    // Update Users Per Role numbers, ensure elements exist
    const userNumbers = document.querySelectorAll("#usersPerRole .number");
    if (userNumbers.length < 4) throw new Error("Users per role elements missing");
    userNumbers[0].textContent = data.usersPerRole.total.toLocaleString();
    userNumbers[1].textContent = data.usersPerRole.jobSeekers.toLocaleString();
    userNumbers[2].textContent = data.usersPerRole.recruiters.toLocaleString();
    userNumbers[3].textContent = data.usersPerRole.admins.toLocaleString();

    // Update System Operations numbers, ensure elements exist
    const systemNumbers = document.querySelectorAll("#systemOperations .number");
    if (systemNumbers.length < 4) throw new Error("System operations elements missing");
    systemNumbers[0].textContent = data.systemOperations.pendingCompanyReviews.toLocaleString();
    systemNumbers[1].textContent = data.systemOperations.pendingJobReviews.toLocaleString();
    systemNumbers[2].textContent = data.systemOperations.activeApplications.toLocaleString();
    systemNumbers[3].textContent = data.systemOperations.apiUsageToday;

    // Update AI Model info if elements present and robust to missing parts
    const aiModelSection = document.getElementById("currentAIModel");
    if (!aiModelSection) {
      console.warn("AI model section missing, skipping update");
    } else {
      const aiLines = aiModelSection.querySelectorAll("p.info-line");
      console.log("Found p.info-line count:", aiLines.length);
      if (aiLines.length === 0) {
        console.warn("No AI model info lines found");
      } else {
        if (aiLines[0]) aiLines[0].textContent = `Version: ${data.aiModel.version}`;
        if (aiLines[1]) aiLines[1].textContent = `Last Updated: ${data.aiModel.lastUpdated}`;
        if (aiLines[2]) {
          aiLines[2].textContent = `Status: ${data.aiModel.status}`;
          aiLines[2].className = data.aiModel.status.toLowerCase() === "online" ? "status ok info" : "status bad info";
        }
      }
    }

    // Update Recent Errors with checks and dynamic styling
    const errorsSection = document.getElementById("recentErrors");
    if (!errorsSection) {
      console.warn("Recent errors section missing, skipping update");
    } else {
      const criticalSpan = errorsSection.querySelector("p.info-line:nth-child(2) span");
      const warningSpan = errorsSection.querySelector("p.info-line:nth-child(3) span");
      const healthSpan = errorsSection.querySelector("p.info-line:nth-child(4) span");

      if (!criticalSpan || !warningSpan || !healthSpan) {
        console.warn("Recent errors spans missing, skipping some updates");
      } else {
        criticalSpan.textContent = data.recentErrors.criticalErrors;
        criticalSpan.className = Number(data.recentErrors.criticalErrors) > 0 ? "status bad" : "status ok";

        warningSpan.textContent = data.recentErrors.warningAlerts;
        // Optional dynamic styling example for warning alerts; adjust thresholds as needed:
        if (Number(data.recentErrors.warningAlerts) > 5) {
          warningSpan.className = "status warn";
        } else {
          warningSpan.className = "status ok";
        }

        healthSpan.textContent = data.recentErrors.systemHealth;
        switch (data.recentErrors.systemHealth.toLowerCase()) {
          case "good":
            healthSpan.className = "status ok";
            break;
          case "warning":
            healthSpan.className = "status warn";
            break;
          case "critical":
            healthSpan.className = "status bad";
            break;
          default:
            healthSpan.className = "status info";
            break;
        }
      }
    }
  } catch (error) {
    console.error("updateDashboard error:", error);
    throw error; // Re-throw for outer handler to manage
  }
}

// Bind event listener safely to refresh button for async data update simulation
const refreshBtn = document.getElementById("refreshBtn");
if (refreshBtn) {
  let refreshing = false; // flag to prevent re-entry
  refreshBtn.addEventListener("click", () => {
    if (refreshing) return;
    refreshing = true;

    refreshBtn.disabled = true;
    refreshBtn.textContent = "Refreshing...";

    setTimeout(() => {
      try {
        updateDashboard(dashboardData); // Mock refresh
      } catch (err) {
        console.error("Error in updateDashboard:", err);
        alert("Error refreshing data. Check console.");
      } finally {
        refreshBtn.disabled = false;
        refreshBtn.textContent = "Refresh Data";
        refreshing = false;
      }
    }, 1500);
  });
} else {
  console.error("Refresh button (id='refreshBtn') not found in the DOM.");
}

// Initialize dashboard on DOM content loaded event
window.addEventListener("DOMContentLoaded", () => {
  updateDashboard(dashboardData);
});
