
// ---- Interview Practice: Show and Hide Tips ----

document.querySelectorAll("[data-tip]").forEach((button) => {

  button.addEventListener("click", () => {

    const tipId = button.dataset.tip;
    const tip = document.getElementById(tipId);

    if (!tip) return;

    tip.hidden = !tip.hidden;

    button.textContent = tip.hidden
      ? "Show Interview Tip"
      : "Hide Interview Tip";

  });

});


// ---- Learning Roadmap Progress ----

const roadmapTasks = document.querySelectorAll(".roadmap-task");
const progressText = document.getElementById("roadmapProgress");
const progressBar = document.getElementById("progressBar");

function updateRoadmapProgress() {

  const totalWeeks = roadmapTasks.length;

  const completedWeeks = document.querySelectorAll(
    ".roadmap-task:checked"
  ).length;

  const percentage = (completedWeeks / totalWeeks) * 100;

  progressText.textContent =
    completedWeeks + " of " + totalWeeks + " weeks completed";

  progressBar.style.width = percentage + "%";

}

roadmapTasks.forEach((checkbox) => {
  checkbox.addEventListener("change", updateRoadmapProgress);
});

updateRoadmapProgress();
