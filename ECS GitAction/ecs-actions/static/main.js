console.log("Hostel Manager loaded");

// Fade alerts automatically
document.addEventListener("DOMContentLoaded", () => {
    document.querySelectorAll(".fade-alert").forEach(alert => {
        setTimeout(() => alert.remove(), 4000);
    });

    // Live search filter
    const searchInput = document.getElementById("searchInput");
    if (searchInput) {
        searchInput.addEventListener("keyup", function() {
            const filter = this.value.toLowerCase();
            const rows = document.querySelectorAll("#studentsTable tbody tr");
            rows.forEach(row => {
                row.style.display = [...row.cells].some(cell =>
                    cell.textContent.toLowerCase().includes(filter)
                ) ? "" : "none";
            });
        });
    }

    // Add interactive hover glow for cards
    document.querySelectorAll(".card").forEach(card => {
        card.addEventListener("mouseenter", () => {
            card.style.boxShadow = "0 20px 40px rgba(30,144,255,0.6)";
            card.style.transform = "translateY(-5px) scale(1.02)";
        });
        card.addEventListener("mouseleave", () => {
            card.style.boxShadow = "0 15px 25px rgba(30,144,255,0.5)";
            card.style.transform = "translateY(0px) scale(1)";
        });
    });
});

// Sort table by column
function sortTable(n) {
    const table = document.getElementById("studentsTable");
    if (!table) return;
    let rows, switching, i, x, y, shouldSwitch, dir, switchcount = 0;
    switching = true; dir = "asc";
    while (switching) {
        switching = false;
        rows = table.rows;
        for (i = 1; i < rows.length - 1; i++) {
            shouldSwitch = false;
            x = rows[i].cells[n].innerText.toLowerCase();
            y = rows[i + 1].cells[n].innerText.toLowerCase();
            if (dir === "asc" ? x > y : x < y) { shouldSwitch = true; break; }
        }
        if (shouldSwitch) {
            rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
            switching = true;
            switchcount++;
        } else if (switchcount === 0 && dir === "asc") { dir = "desc"; switching = true; }
    }
}

// Show spinner on Mark Paid button
function markPaid(button) {
    const spinner = button.querySelector(".spinner-border");
    button.disabled = true;
    spinner.classList.remove("d-none");
    // Simulate server request
    setTimeout(() => {
        button.innerHTML = '<i class="bi bi-check-circle me-1"></i>Paid';
        button.classList.replace('btn-outline-danger', 'btn-success');
    }, 1000);
}
