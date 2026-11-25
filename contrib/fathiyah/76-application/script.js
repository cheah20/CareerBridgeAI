// ---- My Applications: Withdraw Functionality ----

document.querySelectorAll("[data-withdraw]").forEach((button) => {

  button.addEventListener("click", () => {

    const applicationId = button.dataset.withdraw;
    const status = document.getElementById("status-" + applicationId);
    const message = document.getElementById("message");

    if (!status) return;

    const confirmed = confirm(
      "Are you sure you want to withdraw this application?"
    );

    if (confirmed) {
      status.textContent = "Withdrawn";
      status.className = "status bad";

      button.textContent = "Withdrawn";
      button.disabled = true;

      message.textContent =
        "Your application has been withdrawn successfully (demo only).";
    }

  });

});
