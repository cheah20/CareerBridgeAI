
// ---- Job Seeker resume upload demo ----

const resumeForm = document.getElementById("resumeForm");

if (resumeForm) {
  resumeForm.addEventListener("submit", function(event) {
    event.preventDefault();

    const resumeFile = document.getElementById("resumeFile");
    const uploadMessage = document.getElementById("uploadMessage");

    if (!resumeFile.files.length) {
      uploadMessage.textContent = "Please select a resume first.";
      return;
    }

    const file = resumeFile.files[0];
    const allowedTypes = [
      "application/pdf",
      "image/png",
      "image/jpeg"
    ];

    if (!allowedTypes.includes(file.type)) {
      uploadMessage.textContent =
        "Please upload a PDF, PNG or JPG file.";
      return;
    }

    uploadMessage.textContent =
      file.name + " selected successfully. Demo upload only.";
  });
}
