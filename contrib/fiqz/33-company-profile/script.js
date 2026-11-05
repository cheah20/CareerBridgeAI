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

const editBtn = document.getElementById("editProfileBtn");
    if (editBtn) {
      editBtn.addEventListener("click", (e) => {
        e.preventDefault();
        document.querySelectorAll(".tabs button").forEach((b) => {
          b.classList.toggle("active", b.dataset.tab === "edit");
        });
        document.querySelectorAll("[data-panel]").forEach((panel) => {
          panel.hidden = panel.dataset.panel !== "edit";
        });
      });
    }

    const modal = document.getElementById("saveProfileModal");
    const closeBtn = document.getElementById("closeProfileModalBtn");
    const profileForm = document.getElementById("editProfileForm");

    if (profileForm && modal) {
      profileForm.addEventListener("submit", (e) => {
        e.preventDefault();
        modal.showModal(); 
      });
    }

    if (closeBtn && modal) {
      closeBtn.addEventListener("click", () => {
        modal.close();
      });
    }