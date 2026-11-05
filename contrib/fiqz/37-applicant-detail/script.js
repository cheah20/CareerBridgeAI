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
