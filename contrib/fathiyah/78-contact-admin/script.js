
// Contact Admin Form Demo

const contactForm = document.getElementById("contactForm");

if (contactForm) {
    const formMessage = document.getElementById("formMessage");
    const screenshotInput = document.getElementById("screenshot");

    contactForm.addEventListener("submit", function (event) {
        event.preventDefault();

        const subject = document.getElementById("subject").value.trim();
        const message = document.getElementById("message").value.trim();
        const screenshot = screenshotInput.files[0];

        // Check required fields
        if (!subject || !message) {
            formMessage.textContent = "Please complete all required fields.";
            formMessage.style.color = "#dc2626";
            return;
        }

        // Validate optional screenshot
        if (screenshot) {
            const allowedTypes = ["image/png", "image/jpeg"];

            if (!allowedTypes.includes(screenshot.type)) {
                formMessage.textContent =
                    "Invalid screenshot. Please upload a PNG or JPG file.";
                formMessage.style.color = "#dc2626";
                return;
            }
        }

        // Display successful submission message
        formMessage.textContent =
            "Your report has been submitted successfully! (Demo only)";
        formMessage.style.color = "#16a34a";

        // Clear the form
        contactForm.reset();
    });
}
