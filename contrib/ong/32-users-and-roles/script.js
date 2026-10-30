// Example 1: tabs. Buttons with data-tab show the matching <section data-panel>.
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

// Example 2: a button that shows a message instead of saving.
document.querySelectorAll("[data-demo]").forEach((button) => {
  button.addEventListener("click", () => {
    document.getElementById("message").textContent = button.dataset.demo;
  });
});

// ---- Your own code below this line ----
/*
  This script manages a user management table with:
  - Loading CSV data from users.csv
  - Live summary KPI statistics (Total, Active, Recruiters, Admins)
  - Search and role filtering
  - Pagination with Prev, Next, and page numbers
  - Edit user details, Enable/Disable toggle, Role change, and Delete user
*/

// Global variables to store users and pagination state
let allUsers = [];
let filteredUsers = [];
const pageSize = 20;
let currentPage = 1;

// DOM selectors for table and controls
const tbody = document.querySelector("#usersTableBody");
const paginationDiv = document.getElementById("paginationControls");
const searchInput = document.getElementById("searchInput");
const roleFilter = document.getElementById("roleFilter");

// Escape special HTML characters to prevent rendering glitches or XSS
function escapeHTML(str) {
  return String(str || "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

// Parse CSV text into an array of user objects
function parseCSV(text) {
  if (!text || !text.trim()) return [];

  // Handle both Windows (\r\n) and Unix (\n) line endings cleanly
  const lines = text
    .trim()
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line.length > 0);

  if (lines.length < 2) return [];

  // Normalize headers to lowercase and remove extra whitespace
  const headers = lines.shift().split(",").map((h) => h.trim().toLowerCase());

  return lines.map((line, index) => {
    const parts = line.split(",");
    const obj = {};
    headers.forEach((header, i) => {
      obj[header] = parts[i] !== undefined ? parts[i].trim() : "";
    });

    // Assign a fallback unique ID if the CSV does not include an id column
    if (!obj.id) {
      obj.id = `user_${index + 1}`;
    }
    if (!obj.status) {
      obj.status = "Active";
    }
    if (!obj.role) {
      obj.role = "Job Seeker";
    }
    return obj;
  });
}

// Load CSV file asynchronously and initialize user data
async function loadCSVUsers() {
  try {
    const response = await fetch("users.csv"); // Ensure users.csv is accessible in the same folder
    if (!response.ok) {
      throw new Error(`HTTP error! Status: ${response.status}`);
    }
    const text = await response.text();
    allUsers = parseCSV(text);
    applyFiltersAndRender(true);
  } catch (err) {
    console.error("Failed to load users.csv:", err);
  }
}

// Update the top summary KPI cards based on current allUsers state
function updateSummaryStats() {
  const totalEl = document.getElementById("statTotal");
  const activeEl = document.getElementById("statActive");
  const recruitersEl = document.getElementById("statRecruiters");
  const adminsEl = document.getElementById("statAdmins");

  if (totalEl) totalEl.textContent = allUsers.length;
  if (activeEl) activeEl.textContent = allUsers.filter((u) => u.status === "Active").length;
  if (recruitersEl) recruitersEl.textContent = allUsers.filter((u) => u.role === "Recruiter").length;
  if (adminsEl) adminsEl.textContent = allUsers.filter((u) => u.role === "Admin").length;
}

// Render user rows into the table body
function renderTable(usersToShow) {
  tbody.innerHTML = "";
  if (usersToShow.length === 0) {
    tbody.innerHTML = `<tr><td colspan="5" style="text-align:center; padding:20px;">No users found</td></tr>`;
    return;
  }

  usersToShow.forEach((user) => {
    const tr = document.createElement("tr");

    // Actions section differs for Admins (System Restricted prevents accidental admin lockout/deletion)
    const actionsHTML =
      user.role === "Admin"
        ? '<span class="muted">System Restricted</span>'
        : `
        <button type="button" class="btn edit-btn" style="margin-right:6px;">Edit</button>
        <button type="button" class="btn toggle-status-btn" style="margin-right:6px;">${
          user.status === "Active" ? "Disable" : "Enable"
        }</button>
        <select class="role-select" style="margin-right:6px;">
          <option value="Job Seeker"${user.role === "Job Seeker" ? " selected" : ""}>Job Seeker</option>
          <option value="Recruiter"${user.role === "Recruiter" ? " selected" : ""}>Recruiter</option>
          <option value="Admin"${user.role === "Admin" ? " selected" : ""}>Admin</option>
        </select>
        <button type="button" class="btn danger delete-btn">Delete</button>
      `;

    tr.innerHTML = `
      <td>${escapeHTML(user.name)}</td>
      <td>${escapeHTML(user.email)}</td>
      <td>${escapeHTML(user.role)}</td>
      <td><span class="status ${escapeHTML(user.status ? user.status.toLowerCase() : "")}">${escapeHTML(user.status)}</span></td>
      <td>${actionsHTML}</td>
    `;

    tbody.appendChild(tr);

    // Bind event listeners for non-admin users
    if (user.role !== "Admin") {
      tr.querySelector(".edit-btn").addEventListener("click", () => editUser(user));
      tr.querySelector(".toggle-status-btn").addEventListener("click", () => toggleUserStatus(user));
      tr.querySelector(".role-select").addEventListener("change", (e) => changeUserRole(user, e.target.value));
      tr.querySelector(".delete-btn").addEventListener("click", () => deleteUser(user));
    }
  });
}

// Function to edit user details using prompts
function editUser(user) {
  const newName = prompt("Edit user's name:", user.name);
  if (newName === null) return; // Exit if user clicked Cancel

  const newEmail = prompt("Edit user's email:", user.email);
  if (newEmail === null) return; // Exit if user clicked Cancel

  if (newName.trim() !== "") user.name = newName.trim();
  if (newEmail.trim() !== "") user.email = newEmail.trim();

  alert("User information updated.");
  applyFiltersAndRender(false); // Re-render while staying on the current page
}

// Toggle user status Active <-> Disabled
function toggleUserStatus(user) {
  user.status = user.status === "Active" ? "Disabled" : "Active";
  applyFiltersAndRender(false); // Re-render while staying on the current page
}

// Change user role; Admin accounts are always set to Active
function changeUserRole(user, newRole) {
  user.role = newRole;
  if (newRole === "Admin") user.status = "Active";
  applyFiltersAndRender(false); // Re-render while staying on the current page
}

// Delete user with confirmation prompt
function deleteUser(user) {
  if (confirm(`Are you sure you want to delete "${user.name}"? This action cannot be undone.`)) {
    const index = allUsers.findIndex((u) => (user.id !== undefined ? u.id === user.id : u === user));
    if (index !== -1) {
      allUsers.splice(index, 1);
      alert(`User "${user.name}" deleted.`);
      applyFiltersAndRender(false); // Re-render while staying on the current page
    }
  }
}

// Filter and paginate users, then render
// Pass resetPage = true when search/filter changes; pass false when editing/toggling/deleting a row
function applyFiltersAndRender(resetPage = false) {
  const searchTerm = (searchInput.value || "").trim().toLowerCase();
  const roleTerm = roleFilter.value || "";

  filteredUsers = allUsers.filter((user) => {
    const userName = (user.name || "").toLowerCase();
    const userEmail = (user.email || "").toLowerCase();
    const matchesSearch = userName.includes(searchTerm) || userEmail.includes(searchTerm);
    const matchesRole = !roleTerm || roleTerm === "" || roleTerm === "All Roles" || user.role === roleTerm;
    return matchesSearch && matchesRole;
  });

  const totalPages = Math.max(1, Math.ceil(filteredUsers.length / pageSize));
  if (resetPage) {
    currentPage = 1;
  } else if (currentPage > totalPages) {
    currentPage = totalPages;
  }

  updateSummaryStats();
  renderCurrentPage();
  renderPagination();
}

// Render users in the current page slice
function renderCurrentPage() {
  const startIdx = (currentPage - 1) * pageSize;
  const pageUsers = filteredUsers.slice(startIdx, startIdx + pageSize);
  renderTable(pageUsers);
}

// Render pagination buttons with event bindings
function renderPagination() {
  paginationDiv.innerHTML = "";
  const totalPages = Math.ceil(filteredUsers.length / pageSize);
  if (totalPages <= 1) return;

  const prevBtn = document.createElement("button");
  prevBtn.type = "button";
  prevBtn.textContent = "Prev";
  prevBtn.disabled = currentPage === 1;
  prevBtn.onclick = () => {
    if (currentPage > 1) {
      currentPage--;
      renderCurrentPage();
      renderPagination();
    }
  };
  paginationDiv.appendChild(prevBtn);

  const maxDisplay = 7;
  let startPage = Math.max(1, currentPage - 3);
  let endPage = Math.min(totalPages, currentPage + 3);

  if (currentPage <= 4) endPage = Math.min(totalPages, maxDisplay);
  if (currentPage > totalPages - 4) startPage = Math.max(1, totalPages - maxDisplay + 1);

  for (let i = startPage; i <= endPage; i++) {
    const pageBtn = document.createElement("button");
    pageBtn.type = "button";
    pageBtn.textContent = i;
    if (i === currentPage) {
      pageBtn.disabled = true;
      pageBtn.style.fontWeight = "bold";
    }
    pageBtn.onclick = () => {
      currentPage = i;
      renderCurrentPage();
      renderPagination();
    };
    paginationDiv.appendChild(pageBtn);
  }

  const nextBtn = document.createElement("button");
  nextBtn.type = "button";
  nextBtn.textContent = "Next";
  nextBtn.disabled = currentPage === totalPages;
  nextBtn.onclick = () => {
    if (currentPage < totalPages) {
      currentPage++;
      renderCurrentPage();
      renderPagination();
    }
  };
  paginationDiv.appendChild(nextBtn);
}

// Bind search and role filter input event listeners (reset to page 1 on filter change)
searchInput.addEventListener("input", () => applyFiltersAndRender(true));
roleFilter.addEventListener("change", () => applyFiltersAndRender(true));

// Load CSV once when the DOM is fully ready
window.addEventListener("DOMContentLoaded", () => {
  loadCSVUsers();
});