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


// ---- Resume Profile Edit Functionality ----

document.querySelectorAll("[data-edit]").forEach((button) => {

  button.addEventListener("click", () => {

    const sectionId = button.dataset.edit;
    const section = document.getElementById(sectionId);

    if (!section) return;

    const isEditing = section.isContentEditable;

    if (!isEditing) {

      section.contentEditable = "true";
      section.style.background = "#F9FAFB";
      section.style.padding = "10px";
      section.style.borderRadius = "10px";

      button.textContent = "Save";

      document.getElementById("message").textContent =
        "You can now edit the " + sectionId + " information.";

    } else {

      section.contentEditable = "false";
      section.style.background = "";
      section.style.padding = "";
      section.style.borderRadius = "";

      button.textContent = "Edit";

      document.getElementById("message").textContent =
        sectionId + " information updated successfully (demo only).";
    }

  });

});

