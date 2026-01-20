import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template", "row"]

  add(event) {
    event.preventDefault()

    const uniqueKey = Date.now().toString()
    const html = this.templateTarget.innerHTML.replaceAll("NEW_RECORD", uniqueKey)
    this.containerTarget.insertAdjacentHTML("beforeend", html)
  }

  remove(event) {
    event.preventDefault()

    const row = event.target.closest("[data-nested-form-target='row']")
    if (!row) return

    const idInput = row.querySelector("input[name*='[id]']")
    const destroyInput = row.querySelector("input[name*='[_destroy]']")

    if (idInput && idInput.value && destroyInput) {
      destroyInput.value = "1"
      row.classList.add("hidden")
      return
    }

    row.remove()
  }
}

