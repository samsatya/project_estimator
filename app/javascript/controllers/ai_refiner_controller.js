import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["name", "description", "points", "taskType", "modal", "modalContent", "loading", "error"]
  static values = {
    url: String,
    type: String // "epic" or "story"
  }

  connect() {
    console.log("AI Refiner connected")
  }

  refine(event) {
    event.preventDefault()
    this.showLoading()

    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    fetch(this.urlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken
      }
    })
    .then(response => {
      if (!response.ok) throw new Error("Network response was not ok")
      return response.json()
    })
    .then(data => {
      this.showRefinementModal(data)
    })
    .catch(error => {
      this.showError(error.message)
    })
    .finally(() => {
      this.hideLoading()
    })
  }

  suggestPoints(event) {
    event.preventDefault()
    this.showLoading()

    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    fetch(this.urlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken
      }
    })
    .then(response => {
      if (!response.ok) throw new Error("Network response was not ok")
      return response.json()
    })
    .then(data => {
      this.showPointsModal(data)
    })
    .catch(error => {
      this.showError(error.message)
    })
    .finally(() => {
      this.hideLoading()
    })
  }

  showRefinementModal(data) {
    const content = `
      <div class="space-y-4">
        <h3 class="text-lg font-medium text-gray-900">AI Suggestions</h3>

        <div class="bg-gray-50 p-4 rounded-md">
          <h4 class="text-sm font-medium text-gray-500 mb-1">Refined Name</h4>
          <p class="text-gray-900 font-medium" id="refined-name">${data.refined_name}</p>
        </div>

        <div class="bg-gray-50 p-4 rounded-md">
          <h4 class="text-sm font-medium text-gray-500 mb-1">Refined Description</h4>
          <div class="prose prose-sm max-w-none text-gray-900" id="refined-description">
            ${this.formatDescription(data.refined_description)}
          </div>
        </div>

        ${data.suggestions ? `
          <div class="bg-blue-50 p-4 rounded-md">
            <h4 class="text-sm font-medium text-blue-700 mb-1">Suggestions</h4>
            <ul class="list-disc pl-5 text-sm text-blue-800">
              ${data.suggestions.map(s => `<li>${s}</li>`).join('')}
            </ul>
          </div>
        ` : ''}

        ${data.suggested_points ? `
          <div class="bg-indigo-50 p-4 rounded-md flex justify-between items-center">
            <div>
              <h4 class="text-sm font-medium text-indigo-700">Suggested Points</h4>
              <p class="text-indigo-900 font-bold text-xl" id="suggested-points">${data.suggested_points}</p>
            </div>
            ${data.suggested_task_type ? `
              <div>
                <h4 class="text-sm font-medium text-indigo-700">Task Type</h4>
                <p class="text-indigo-900 font-bold" id="suggested-task-type">${data.suggested_task_type}</p>
              </div>
            ` : ''}
          </div>
        ` : ''}

        <div class="flex justify-end space-x-3 mt-6">
          <button type="button" class="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50" data-action="click->ai-refiner#closeModal">Cancel</button>
          <button type="button" class="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700" data-action="click->ai-refiner#applyChanges">Apply Changes</button>
        </div>
      </div>
    `

    this.modalContentTarget.innerHTML = content
    this.modalTarget.classList.remove("hidden")
  }

  showPointsModal(data) {
    const content = `
      <div class="space-y-4">
        <h3 class="text-lg font-medium text-gray-900">Story Point Suggestion</h3>

        <div class="bg-indigo-50 p-6 rounded-md text-center">
          <h4 class="text-sm font-medium text-indigo-700 mb-2">Recommended Points</h4>
          <p class="text-5xl font-bold text-indigo-600" id="suggested-points">${data.suggested_points}</p>
        </div>

        <div class="bg-gray-50 p-4 rounded-md">
          <h4 class="text-sm font-medium text-gray-500 mb-1">Reasoning</h4>
          <p class="text-gray-900 text-sm">${data.reasoning}</p>
        </div>

        <div class="flex justify-end space-x-3 mt-6">
          <button type="button" class="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50" data-action="click->ai-refiner#closeModal">Close</button>
          <button type="button" class="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700" data-action="click->ai-refiner#applyPoints">Apply Points</button>
        </div>
      </div>
    `

    this.modalContentTarget.innerHTML = content
    this.modalTarget.classList.remove("hidden")
  }

  applyChanges() {
    const refinedName = this.modalContentTarget.querySelector("#refined-name").textContent
    const refinedDescription = this.modalContentTarget.querySelector("#refined-description").innerText // Use innerText to preserve newlines

    if (this.hasNameTarget) this.nameTarget.value = refinedName
    if (this.hasDescriptionTarget) this.descriptionTarget.value = refinedDescription

    const suggestedPoints = this.modalContentTarget.querySelector("#suggested-points")
    if (suggestedPoints && this.hasPointsTarget) {
      this.pointsTarget.value = suggestedPoints.textContent
    }

    const suggestedTaskType = this.modalContentTarget.querySelector("#suggested-task-type")
    if (suggestedTaskType && this.hasTaskTypeTarget) {
      this.taskTypeTarget.value = suggestedTaskType.textContent
    }

    this.closeModal()
  }

  applyPoints() {
    const suggestedPoints = this.modalContentTarget.querySelector("#suggested-points").textContent
    if (this.hasPointsTarget) {
      this.pointsTarget.value = suggestedPoints
    }
    this.closeModal()
  }

  closeModal() {
    this.modalTarget.classList.add("hidden")
  }

  showLoading() {
    this.loadingTarget.classList.remove("hidden")
  }

  hideLoading() {
    this.loadingTarget.classList.add("hidden")
  }

  showError(message) {
    alert(`Error: ${message}`)
  }

  formatDescription(text) {
    return text.replace(/\n/g, '<br>')
  }
}
