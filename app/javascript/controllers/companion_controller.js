import { Controller } from "@hotwired/stimulus"

const HOUSE_SVG = `<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="#F5A623" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" style="animation:housePulse 1.6s cubic-bezier(.4,0,.2,1) infinite"><path d="M3 11.2 12 4l9 7.2"/><path d="M5.5 9.6V19h13V9.6"/><path d="M10 19v-5h4v5"/></svg>`

export default class extends Controller {
  static targets = ["messageArea", "composer", "grid", "homeTab", "chatTab", "tabDot"]
  static values  = { messagesUrl: String, selectionsUrl: String, orgName: String }

  sending = false
  selectedOccupants = new Set()
  selectedStyles    = new Set()

  connect() {
    this.scrollToBottom()
  }

  // ── Tab navigation ──────────────────────────────────────────────

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

  // ── Free-text input ─────────────────────────────────────────────

  send() {
    const text = this.composerTarget.value.trim()
    if (!text) return
    this.composerTarget.value = ""
    this.sendMessage(text)
  }

  composerKeydown(e) {
    if (e.key === "Enter") { e.preventDefault(); this.send() }
  }

  sendText(e) {
    this.sendMessage(e.currentTarget.dataset.text)
  }

  sendMessage(text) {
    if (this.sending || !text.trim()) return
    this.sending = true
    this.appendUserBubble(text)
    const typingEl = this.appendTypingIndicator()
    this.scrollToBottom()

    this.postTo(this.messagesUrlValue, { content: text })
      .then(data => this.handleResponse(data, typingEl))
      .catch(() => {
        typingEl.remove()
        this.appendCompanionBubble("That's a great question for Megan at your design meeting — I've noted it. Shall we keep going?")
        this.scrollToBottom()
      })
      .finally(() => { this.sending = false })
  }

  // ── Component interactions → SelectionsController ───────────────

  sendSelection(e) {
    const type = e.currentTarget.dataset.selectionType
    this.postSelection({ type })
  }

  selectPurpose(e) {
    const { purposeKey, roomKey } = e.currentTarget.dataset
    const component = e.currentTarget.closest("[data-component='room_purpose']")

    if (purposeKey === "other") {
      const input = component.querySelector("#purpose-other-input")
      if (input) { input.style.display = "flex" }
      return
    }

    this.lockComponent(component)
    const label = e.currentTarget.textContent.trim()
    this.postSelection({ type: "room_purpose", room_key: roomKey, purpose: purposeKey, purpose_label: label })
  }

  confirmPurposeOther(e) {
    const component = e.currentTarget.closest("[data-component='room_purpose']")
    const input = component.querySelector("[data-purpose-other-input]")
    const label = input?.value.trim()
    if (!label) { input?.focus(); return }
    const roomKey = e.currentTarget.dataset.roomKey
    this.lockComponent(component)
    this.postSelection({ type: "room_purpose", room_key: roomKey, purpose: "other", purpose_label: label })
  }

  toggleOccupant(e) {
    const { occupantKey } = e.currentTarget.dataset
    const btn = e.currentTarget
    if (this.selectedOccupants.has(occupantKey)) {
      this.selectedOccupants.delete(occupantKey)
      btn.classList.remove("chat-component-btn--selected")
    } else {
      this.selectedOccupants.add(occupantKey)
      btn.classList.add("chat-component-btn--selected")
    }
  }

  confirmOccupants(e) {
    const component = e.currentTarget.closest("[data-component='occupant_selector']")
    const roomKey = component?.dataset.roomKey
    if (this.selectedOccupants.size === 0) return
    this.lockComponent(component)
    this.postSelection({ type: "occupants", room_key: roomKey, occupants: [...this.selectedOccupants] })
    this.selectedOccupants.clear()
  }

  toggleStyle(e) {
    const { styleKey } = e.currentTarget.dataset
    const tile = e.currentTarget
    const checkEl = tile.querySelector(".style-tile__check")

    if (styleKey === "not_sure") {
      this.selectedStyles.clear()
      tile.closest("[data-component]").querySelectorAll(".style-tile").forEach(t => {
        t.classList.remove("style-tile--selected")
        const c = t.querySelector(".style-tile__check"); if (c) c.style.display = "none"
      })
      this.selectedStyles.add("not_sure")
      tile.classList.add("style-tile--selected")
      if (checkEl) checkEl.style.display = "flex"
      return
    }

    this.selectedStyles.delete("not_sure")
    tile.closest("[data-component]").querySelector("[data-style-key='not_sure']")
        ?.classList.remove("style-tile--selected")
    const notSureCheck = tile.closest("[data-component]").querySelector("[data-style-key='not_sure'] .style-tile__check")
    if (notSureCheck) notSureCheck.style.display = "none"

    if (this.selectedStyles.has(styleKey)) {
      this.selectedStyles.delete(styleKey)
      tile.classList.remove("style-tile--selected")
      if (checkEl) checkEl.style.display = "none"
    } else {
      this.selectedStyles.add(styleKey)
      tile.classList.add("style-tile--selected")
      if (checkEl) checkEl.style.display = "flex"
    }
  }

  confirmStyles(e) {
    const component = e.currentTarget.closest("[data-component='style_picker']")
    if (this.selectedStyles.size === 0) return
    this.lockComponent(component)
    this.postSelection({ type: "design_styles", styles: [...this.selectedStyles] })
    this.selectedStyles.clear()
  }

  selectOption(e) {
    const { optionKey, optionLabel, roomKey, selectionType } = e.currentTarget.dataset
    const component = e.currentTarget.closest("[data-component='option_selector']")
    const isMulti = component?.dataset.multi === "true"

    if (!isMulti) {
      component?.querySelectorAll(".option-tile").forEach(t => t.classList.remove("option-tile--selected"))
    }
    e.currentTarget.classList.add("option-tile--selected")

    this.lockComponent(component)
    this.postSelection({ type: "option", room_key: roomKey, selection_type: selectionType,
                         option_key: optionKey, option_label: optionLabel })
  }

  skipOption(e) {
    const { roomKey, selectionType } = e.currentTarget.dataset
    const component = e.currentTarget.closest("[data-component='option_selector']")
    this.lockComponent(component)
    this.postSelection({ type: "pending", room_key: roomKey, selection_type: selectionType })
  }

  progressNext(e) {
    const component = e.currentTarget.closest("[data-component='progress_card']")
    this.lockComponent(component)
    this.postSelection({ type: "progress_next" })
  }

  editRoom(e) {
    const { roomKey } = e.currentTarget.dataset
    const component = e.currentTarget.closest("[data-component='summary_card']")
    this.lockComponent(component)
    this.postSelection({ type: "summary_edit", room_key: roomKey })
  }

  summaryDone(e) {
    const component = e.currentTarget.closest("[data-component='summary_card']")
    this.lockComponent(component)
    this.postSelection({ type: "summary_done" })
  }

  copyEmail(e) {
    const text = e.currentTarget.dataset.copyText
    navigator.clipboard?.writeText(text).then(() => {
      const btn = e.currentTarget
      const orig = btn.textContent
      btn.textContent = "Copied!"
      setTimeout(() => { btn.textContent = orig }, 2000)
    })
  }

  // ── HTTP helpers ─────────────────────────────────────────────────

  postSelection(data) {
    if (this.sending) return
    this.sending = true
    const typingEl = this.appendTypingIndicator()
    this.scrollToBottom()

    this.postTo(this.selectionsUrlValue, data)
      .then(result => this.handleResponse(result, typingEl))
      .catch(() => {
        typingEl.remove()
        this.appendCompanionBubble("Something went wrong — let's try that again.")
        this.scrollToBottom()
      })
      .finally(() => { this.sending = false })
  }

  postTo(url, data) {
    const token = document.querySelector('meta[name="csrf-token"]').content
    const body  = new FormData()
    Object.entries(data).forEach(([k, v]) => {
      if (Array.isArray(v)) { v.forEach(item => body.append(`${k}[]`, item)) }
      else { body.append(k, v ?? "") }
    })
    return fetch(url, {
      method: "POST",
      headers: { "X-CSRF-Token": token, "Accept": "application/json" },
      body
    }).then(r => r.json())
  }

  handleResponse(data, typingEl) {
    typingEl.remove()
    if (data.message) this.appendCompanionBubble(data.message)
    if (data.component_html) this.appendComponent(data.component_html)
    this.scrollToBottom()
    this._notifyIfHidden()
    if (data.rooms_complete !== undefined) this.updateProgress(data.rooms_complete, data.total_rooms)
  }

  // ── DOM helpers ──────────────────────────────────────────────────

  appendUserBubble(text) {
    const div = document.createElement("div")
    div.style.cssText = "display:flex;margin:0 0 11px;justify-content:flex-end"
    div.innerHTML = `<div style="max-width:84%;overflow-wrap:break-word;background:#1A1A2E;color:#fff;padding:11px 15px;border-radius:16px 16px 5px 16px;font:400 14.5px/1.5 'Sora',system-ui;animation:scRise .3s ease both">${this.escapeHtml(text)}</div>`
    this.messageAreaTarget.appendChild(div)
  }

  appendCompanionBubble(text) {
    const div = document.createElement("div")
    div.style.cssText = "display:flex;margin:0 0 8px;justify-content:flex-start"
    div.innerHTML = `<div style="max-width:88%;overflow-wrap:break-word;background:#fff;color:#1A1A1A;padding:11px 15px;border-radius:16px 16px 16px 5px;font:400 14.5px/1.52 'Sora',system-ui;border:1px solid #E5E7EB;box-shadow:0 1px 6px rgba(0,0,0,.04);animation:scRise .3s ease both">${this.escapeHtml(text)}</div>`
    this.messageAreaTarget.appendChild(div)
  }

  appendComponent(html) {
    const wrapper = document.createElement("div")
    wrapper.style.cssText = "margin:0 0 14px;animation:scRise .35s ease both"
    wrapper.innerHTML = html
    this.messageAreaTarget.appendChild(wrapper)
  }

  appendTypingIndicator() {
    const div = document.createElement("div")
    div.style.cssText = "display:flex;margin:0 0 11px;justify-content:flex-start"
    div.innerHTML = `<div style="max-width:88%;background:#fff;color:#1A1A1A;padding:11px 15px;border-radius:16px 16px 16px 5px;border:1px solid #E5E7EB;box-shadow:0 1px 6px rgba(0,0,0,.04)"><span style="display:inline-flex;align-items:center;gap:8px">${HOUSE_SVG}<span style="font:500 9.5px 'IBM Plex Mono',ui-monospace,monospace;letter-spacing:.1em;text-transform:uppercase;color:#9aa0ac">Thinking</span></span></div>`
    this.messageAreaTarget.appendChild(div)
    return div
  }

  lockComponent(component) {
    if (!component) return
    component.querySelectorAll("button").forEach(btn => {
      btn.disabled = true
      btn.style.opacity = "0.5"
      btn.style.cursor = "not-allowed"
    })
  }

  updateProgress(roomsComplete, totalRooms) {
    // Trigger a page partial refresh for the design brief progress tracker.
    // Simplest approach: reload the left panel via fetch and innerHTML swap.
    const panel = document.querySelector(".companion-main")
    if (!panel) return
    fetch(window.location.href, { headers: { "Accept": "text/html" } })
      .then(r => r.text())
      .then(html => {
        const parser = new DOMParser()
        const doc    = parser.parseFromString(html, "text/html")
        const fresh  = doc.querySelector(".companion-main")
        if (fresh) panel.innerHTML = fresh.innerHTML
      })
      .catch(() => {}) // silent — progress panel update is cosmetic
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
