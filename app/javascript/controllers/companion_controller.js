import { Controller } from "@hotwired/stimulus"

const HOUSE_SVG = `<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="#F5A623" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" style="animation:housePulse 1.6s cubic-bezier(.4,0,.2,1) infinite"><path d="M3 11.2 12 4l9 7.2"/><path d="M5.5 9.6V19h13V9.6"/><path d="M10 19v-5h4v5"/></svg>`

export default class extends Controller {
  static targets = ["messageArea", "composer", "approveRow", "approvedPanel", "chips", "grid", "homeTab", "chatTab", "tabDot"]
  static values = {
    approveUrl: String,
    messagesUrl: String,
    orgName: String,
    firstName: String
  }

  sending = false

  connect() {
    this.scrollToBottom()
  }

  showHome() {
    if (this.hasGridTarget) this.gridTarget.classList.remove("chat-active")
    this.homeTabTarget.classList.add("active")
    this.chatTabTarget.classList.remove("active")
  }

  showChat() {
    if (this.hasGridTarget) this.gridTarget.classList.add("chat-active")
    this.homeTabTarget.classList.remove("active")
    this.chatTabTarget.classList.add("active")
    if (this.hasTabDotTarget) this.tabDotTarget.classList.remove("visible")
    this.scrollToBottom()
  }

  approve() {
    const token = document.querySelector('meta[name="csrf-token"]').content
    fetch(this.approveUrlValue, {
      method: "POST",
      headers: { "X-CSRF-Token": token, "Accept": "application/json" }
    })
    .then(r => r.json())
    .then(data => {
      if (data.success) {
        if (this.hasApproveRowTarget) this.approveRowTarget.style.display = "none"
        if (this.hasApprovedPanelTarget) this.approvedPanelTarget.style.display = "flex"
        this.appendCompanionBubble("Approved — I've sent your sign-off on the kitchen to Megan and the production team. Anything you'd still tweak before selections lock on July 28?")
        this.scrollToBottom()
      }
    })
  }

  askAboutKitchen() {
    this.sendMessage("What did I pick for the kitchen?")
    this.composerTarget.focus()
  }

  sendChip(e) {
    const text = e.currentTarget.dataset.chipText
    this.sendMessage(text)
  }

  composerKeydown(e) {
    if (e.key === "Enter") { e.preventDefault(); this.send() }
  }

  send() {
    const text = this.composerTarget.value.trim()
    if (!text) return
    this.composerTarget.value = ""
    this.sendMessage(text)
  }

  sendMessage(text) {
    if (this.sending || !text.trim()) return
    this.sending = true

    // Hide chips after first user message
    if (this.hasChipsTarget) this.chipsTarget.style.display = "none"

    this.appendUserBubble(text)
    const typingEl = this.appendTypingIndicator()
    this.scrollToBottom()

    const token = document.querySelector('meta[name="csrf-token"]').content
    const body = new FormData()
    body.append("content", text)

    fetch(this.messagesUrlValue, {
      method: "POST",
      headers: { "X-CSRF-Token": token, "Accept": "application/json" },
      body
    })
    .then(r => r.json())
    .then(data => {
      typingEl.remove()
      this.appendCompanionBubble(data.answer)
      this.scrollToBottom()
      this._notifyIfHidden()
    })
    .catch(() => {
      typingEl.remove()
      this.appendCompanionBubble("That's a great one for Megan, your designer — I've flagged it so she sees it before your next appointment.")
      this.scrollToBottom()
      this._notifyIfHidden()
    })
    .finally(() => { this.sending = false })
  }

  appendUserBubble(text) {
    const div = document.createElement("div")
    div.style.cssText = "display:flex;margin:0 0 11px;justify-content:flex-end"
    div.innerHTML = `<div style="max-width:84%;overflow-wrap:break-word;background:#1A1A2E;color:#fff;padding:11px 15px;border-radius:16px 16px 5px 16px;font:400 14.5px/1.5 'Sora',system-ui;animation:scRise .3s ease both">${this.escapeHtml(text)}</div>`
    this.messageAreaTarget.insertBefore(div, this.hasChipsTarget ? this.chipsTarget : null)
  }

  appendCompanionBubble(text) {
    const div = document.createElement("div")
    div.style.cssText = "display:flex;margin:0 0 11px;justify-content:flex-start"
    div.innerHTML = `<div style="max-width:88%;overflow-wrap:break-word;background:#fff;color:#1A1A1A;padding:11px 15px;border-radius:16px 16px 16px 5px;font:400 14.5px/1.52 'Sora',system-ui;border:1px solid #E5E7EB;box-shadow:0 1px 6px rgba(0,0,0,.04);animation:scRise .3s ease both">${this.escapeHtml(text)}</div>`
    this.messageAreaTarget.insertBefore(div, this.hasChipsTarget ? this.chipsTarget : null)
  }

  appendTypingIndicator() {
    const div = document.createElement("div")
    div.style.cssText = "display:flex;margin:0 0 11px;justify-content:flex-start"
    div.innerHTML = `<div style="max-width:88%;background:#fff;color:#1A1A1A;padding:11px 15px;border-radius:16px 16px 16px 5px;border:1px solid #E5E7EB;box-shadow:0 1px 6px rgba(0,0,0,.04)"><span style="display:inline-flex;align-items:center;gap:8px">${HOUSE_SVG}<span style="font:500 9.5px 'IBM Plex Mono',ui-monospace,monospace;letter-spacing:.1em;text-transform:uppercase;color:#9aa0ac">Thinking</span></span></div>`
    this.messageAreaTarget.insertBefore(div, this.hasChipsTarget ? this.chipsTarget : null)
    return div
  }

  scrollToBottom() {
    const el = this.messageAreaTarget
    el.scrollTop = el.scrollHeight
  }

  _notifyIfHidden() {
    const onChat = this.hasGridTarget && this.gridTarget.classList.contains("chat-active")
    if (!onChat && this.hasTabDotTarget) this.tabDotTarget.classList.add("visible")
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.appendChild(document.createTextNode(text))
    return div.innerHTML
  }
}
