import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["intakeScreen", "loadingScreen", "firstName", "lastName", "company", "email",
                    "firstNameError", "lastNameError", "companyError", "emailError",
                    "submitBtn", "brandedAs"]
  static values = { leadsUrl: String, homeUrl: String }

  clearError() {
    // errors clear on any input
  }

  emailKeydown(e) {
    if (e.key === "Enter") { e.preventDefault(); this.submit() }
  }

  submit() {
    const first = this.firstNameTarget.value.trim()
    const last = this.lastNameTarget.value.trim()
    const company = this.companyTarget.value.trim()
    const email = this.emailTarget.value.trim()

    let valid = true

    if (!first) { this.firstNameErrorTarget.style.display = "block"; valid = false }
    else { this.firstNameErrorTarget.style.display = "none" }

    if (!last) { this.lastNameErrorTarget.style.display = "block"; valid = false }
    else { this.lastNameErrorTarget.style.display = "none" }

    if (!company) { this.companyErrorTarget.style.display = "block"; valid = false }
    else { this.companyErrorTarget.style.display = "none" }

    const emailOk = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
    if (!emailOk) { this.emailErrorTarget.style.display = "block"; valid = false }
    else { this.emailErrorTarget.style.display = "none" }

    if (!valid) return

    // Show loading screen
    this.intakeScreenTarget.style.display = "none"
    this.loadingScreenTarget.style.display = "flex"
    this.brandedAsTarget.textContent = `Branded as ${company}`

    // Submit to server
    const body = new FormData()
    body.append("lead[first_name]", first)
    body.append("lead[last_name]", last)
    body.append("lead[company]", company)
    body.append("lead[email]", email)

    const token = document.querySelector('meta[name="csrf-token"]').content

    fetch(this.leadsUrlValue, {
      method: "POST",
      headers: { "X-CSRF-Token": token, "Accept": "application/json" },
      body
    })
    .then(r => r.json())
    .then(data => {
      if (data.success) {
        setTimeout(() => { window.location.href = this.homeUrlValue }, 1500)
      } else {
        this.loadingScreenTarget.style.display = "none"
        this.intakeScreenTarget.style.display = "block"
      }
    })
    .catch(() => {
      this.loadingScreenTarget.style.display = "none"
      this.intakeScreenTarget.style.display = "block"
    })
  }
}
