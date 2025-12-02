import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "modalContent", "loading", "error", "storiesList"]
  static values = {
    url: String,
    projectId: String,
    epicId: String
  }

  connect() {
    console.log("Story Generator connected")
  }

  generate(event) {
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
      this.showStoriesModal(data.stories)
    })
    .catch(error => {
      this.showError(error.message)
    })
    .finally(() => {
      this.hideLoading()
    })
  }

  showStoriesModal(stories) {
    const storiesHtml = stories.map((story, index) => `
      <div class="border border-gray-200 rounded-md p-4 mb-4 bg-white story-item" data-index="${index}">
        <div class="flex justify-between items-start mb-2">
          <div class="flex-1 mr-4">
            <label class="block text-xs font-medium text-gray-500">Story Name</label>
            <input type="text" name="stories[${index}][name]" value="${story.name}" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm story-name-input">
          </div>
          <div class="w-24">
            <label class="block text-xs font-medium text-gray-500">Points</label>
            <select name="stories[${index}][points]" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm story-points-input">
              ${[1, 2, 3, 5, 8, 13, 21].map(p => `<option value="${p}" ${p == story.points ? 'selected' : ''}>${p}</option>`).join('')}
            </select>
          </div>
        </div>

        <div class="mb-2">
          <label class="block text-xs font-medium text-gray-500">Description</label>
          <textarea name="stories[${index}][description]" rows="3" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm story-description-input">${story.description}</textarea>
        </div>

        <div class="flex justify-between items-center">
          <div class="w-1/3">
            <label class="block text-xs font-medium text-gray-500">Task Type</label>
            <select name="stories[${index}][task_type]" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm story-type-input">
              ${["Backend", "Frontend", "Full-stack", "Testing", "Design", "Research", "Infra", "UI", "Test"].map(t => `<option value="${t}" ${t.toLowerCase() == (story.task_type || 'backend').toLowerCase() ? 'selected' : ''}>${t}</option>`).join('')}
            </select>
          </div>
          <button type="button" class="text-red-600 hover:text-red-800 text-sm font-medium" onclick="this.closest('.story-item').remove()">Remove</button>
        </div>
      </div>
    `).join('')

    const content = `
      <div class="space-y-4">
        <div class="flex justify-between items-center">
          <h3 class="text-lg font-medium text-gray-900">Generated Stories</h3>
          <span class="text-sm text-gray-500">${stories.length} stories found</span>
        </div>

        <div class="max-h-[60vh] overflow-y-auto bg-gray-50 p-4 rounded-md" id="stories-container">
          ${storiesHtml}
        </div>

        <div class="flex justify-between items-center mt-6 pt-4 border-t border-gray-200">
          <button type="button" class="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50" data-action="click->story-generator#addStory">Add Empty Story</button>
          <div class="flex space-x-3">
            <button type="button" class="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50" data-action="click->story-generator#closeModal">Cancel</button>
            <button type="button" class="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700" data-action="click->story-generator#saveStories">Save All Stories</button>
          </div>
        </div>
      </div>
    `

    this.modalContentTarget.innerHTML = content
    this.modalTarget.classList.remove("hidden")
  }

  addStory() {
    const container = this.modalContentTarget.querySelector("#stories-container")
    const index = container.children.length
    const newStoryHtml = `
      <div class="border border-gray-200 rounded-md p-4 mb-4 bg-white story-item" data-index="${index}">
        <div class="flex justify-between items-start mb-2">
          <div class="flex-1 mr-4">
            <label class="block text-xs font-medium text-gray-500">Story Name</label>
            <input type="text" name="stories[${index}][name]" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm story-name-input">
          </div>
          <div class="w-24">
            <label class="block text-xs font-medium text-gray-500">Points</label>
            <select name="stories[${index}][points]" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm story-points-input">
              ${[1, 2, 3, 5, 8, 13, 21].map(p => `<option value="${p}">${p}</option>`).join('')}
            </select>
          </div>
        </div>

        <div class="mb-2">
          <label class="block text-xs font-medium text-gray-500">Description</label>
          <textarea name="stories[${index}][description]" rows="3" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm story-description-input"></textarea>
        </div>

        <div class="flex justify-between items-center">
          <div class="w-1/3">
            <label class="block text-xs font-medium text-gray-500">Task Type</label>
            <select name="stories[${index}][task_type]" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm story-type-input">
              ${["Backend", "Frontend", "Full-stack", "Testing", "Design", "Research", "Infra", "UI", "Test"].map(t => `<option value="${t}">${t}</option>`).join('')}
            </select>
          </div>
          <button type="button" class="text-red-600 hover:text-red-800 text-sm font-medium" onclick="this.closest('.story-item').remove()">Remove</button>
        </div>
      </div>
    `
    container.insertAdjacentHTML('beforeend', newStoryHtml)
    container.scrollTop = container.scrollHeight
  }

  saveStories() {
    this.showLoading()
    const stories = []
    const items = this.modalContentTarget.querySelectorAll(".story-item")

    items.forEach(item => {
      stories.push({
        name: item.querySelector(".story-name-input").value,
        description: item.querySelector(".story-description-input").value,
        points: item.querySelector(".story-points-input").value,
        task_type: item.querySelector(".story-type-input").value
      })
    })

    // Create CSV content for bulk upload
    const headers = ["Story Name", "Story Points", "Story Description", "Story Task Type"]
    const csvContent = [
      headers.join(","),
      ...stories.map(s => `"${s.name.replace(/"/g, '""')}","${s.points}","${s.description.replace(/"/g, '""')}","${s.task_type}"`)
    ].join("\n")

    // Create a file object
    const file = new File([csvContent], "generated_stories.csv", { type: "text/csv" })
    const formData = new FormData()
    formData.append("csv_file", file)

    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    // Use the existing bulk upload endpoint
    const bulkUploadUrl = `/projects/${this.projectIdValue}/epics/${this.epicIdValue}/process_bulk_upload`

    fetch(bulkUploadUrl, {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrfToken
      },
      body: formData
    })
    .then(response => {
      if (response.ok) {
        window.location.reload()
      } else {
        throw new Error("Failed to save stories")
      }
    })
    .catch(error => {
      this.showError(error.message)
      this.hideLoading()
    })
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
}
