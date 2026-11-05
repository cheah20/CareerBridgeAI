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
const jobForm = document.getElementById("jobForm");
const msg = document.getElementById("message");

if (jobForm) {
  // 1. Submit handling with validation check
  jobForm.addEventListener("submit", (e) => {
    e.preventDefault();

    const title = document.getElementById("jobTitle").value.trim();
    const desc = document.getElementById("jobDesc").value.trim();
    const skills = document.getElementById("requiredSkills").value.trim();
    const loc = document.getElementById("location").value.trim();
    const date = document.getElementById("closingDate").value.trim();

    // Check for any missing required fields
    if (!title || !desc || !skills || !loc || !date) {
      msg.textContent = "⚠️ Please complete all required fields (*) before submitting.";
      msg.style.color = "var(--bad)";
      return;
    }

    // Success state
    msg.textContent = "✅ Job successfully submitted for Admin review!";
    msg.style.color = "var(--ok)";
  });

  // 2. Save as Draft (allows partial saves without requiring all fields)
  const draftBtn = document.getElementById("draftBtn");
  if (draftBtn) {
    draftBtn.addEventListener("click", () => {
      const title = document.getElementById("jobTitle").value.trim();
      if (!title) {
        msg.textContent = "⚠️ Enter at least a Job Title to save a draft.";
        msg.style.color = "var(--warn)";
      } else {
        msg.textContent = "💾 Draft saved successfully.";
        msg.style.color = "var(--sub)";
      }
    });
  }
}