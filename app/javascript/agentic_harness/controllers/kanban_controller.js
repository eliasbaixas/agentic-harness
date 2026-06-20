import { Controller } from "@hotwired/stimulus"

// Kanban drag-and-drop controller.
// Supports cross-column moves and within-column reordering.
// Column headers go sticky when dragging starts so tall columns stay navigable.
export default class extends Controller {
  static targets = ["dropzone", "cards", "count", "empty"]

  // ── Drag source (card) ──────────────────────────────────────────────────

  dragStart(event) {
    const card = event.currentTarget
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("application/json", JSON.stringify({
      slug:   card.dataset.slug,
      column: card.dataset.column,
    }))
    requestAnimationFrame(() => {
      card.classList.add("opacity-40")
      // Sticky column headers activate so any column is reachable while scrolled
      this.element.classList.add("is-dragging")
    })
  }

  dragEnd(event) {
    event.currentTarget.classList.remove("opacity-40")
    this.element.classList.remove("is-dragging")
  }

  // ── Drop zone (full column) ──────────────────────────────────────────────

  dragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"
  }

  dragEnter(event) {
    event.preventDefault()
    const zone = event.currentTarget
    zone._enterCount = (zone._enterCount || 0) + 1
    zone.classList.add("ring-2", "ring-blue-400")
  }

  dragLeave(event) {
    const zone = event.currentTarget
    zone._enterCount = Math.max(0, (zone._enterCount || 1) - 1)
    if (zone._enterCount === 0) zone.classList.remove("ring-2", "ring-blue-400")
  }

  async drop(event) {
    event.preventDefault()
    const zone = event.currentTarget
    zone._enterCount = 0
    zone.classList.remove("ring-2", "ring-blue-400")

    let data
    try {
      data = JSON.parse(event.dataTransfer.getData("application/json"))
    } catch { return }

    const { slug, column: sourceColumn } = data
    const targetColumn = zone.dataset.column
    const isSameColumn = sourceColumn === targetColumn

    const card = document.querySelector(
      `[data-slug="${CSS.escape(slug)}"][data-column="${CSS.escape(sourceColumn)}"]`
    )
    if (!card) return

    const sourceZone   = this.dropzoneTargets.find(z => z.dataset.column === sourceColumn)
    const targetCardsEl = this._cardsContainer(zone)

    // Position-aware insertion: insert before the card whose midpoint is below cursor
    const insertBefore = this._getInsertionPoint(targetCardsEl, event.clientY, card)
    this._insertCardBefore(targetCardsEl, card, insertBefore)
    card.dataset.column = targetColumn

    if (!isSameColumn) {
      this._updateEmptyStates(sourceColumn, targetColumn)
      this._updateCounts(sourceColumn, targetColumn)
    }

    // Persist ────────────────────────────────────────────────────────────────
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
    const requests = []

    if (!isSameColumn) {
      requests.push(
        fetch(`/kanban/${sourceColumn}/${encodeURIComponent(slug)}/move`, {
          method: "PATCH",
          headers: { "Content-Type": "application/json", "X-CSRF-Token": csrfToken },
          body: JSON.stringify({ target_column: targetColumn }),
        })
      )
    }

    // Always persist new card order in the target column
    const newOrder = this._columnSlugs(targetCardsEl)
    requests.push(
      fetch(`/kanban/${targetColumn}/reorder`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": csrfToken },
        body: JSON.stringify({ slugs: newOrder }),
      })
    )

    try {
      const results = await Promise.all(requests)
      if (results.some(r => !r.ok)) this._revert(card, sourceZone, sourceColumn, targetColumn, isSameColumn)
    } catch {
      this._revert(card, sourceZone, sourceColumn, targetColumn, isSameColumn)
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  _cardsContainer(zone) {
    return zone.querySelector("[data-kanban-target='cards']") || zone
  }

  // Returns the first card whose vertical midpoint is below clientY (insert before it),
  // or null (append at end).
  _getInsertionPoint(container, clientY, excludeCard) {
    const cards = Array.from(container.querySelectorAll("[data-slug]")).filter(c => c !== excludeCard)
    return cards.find(c => {
      const r = c.getBoundingClientRect()
      return clientY < r.top + r.height / 2
    }) ?? null
  }

  _insertCardBefore(container, card, insertionPoint) {
    const emptyEl = container.querySelector("[data-kanban-target='empty']")
    if (insertionPoint) {
      container.insertBefore(card, insertionPoint)
    } else if (emptyEl) {
      container.insertBefore(card, emptyEl)
    } else {
      container.appendChild(card)
    }
  }

  _columnSlugs(container) {
    return Array.from(container.querySelectorAll("[data-slug]")).map(c => c.dataset.slug)
  }

  _revert(card, sourceZone, sourceColumn, targetColumn, isSameColumn) {
    if (sourceZone) {
      const sc = this._cardsContainer(sourceZone)
      this._insertCardBefore(sc, card, null)
    }
    card.dataset.column = sourceColumn
    if (!isSameColumn) {
      this._updateEmptyStates(targetColumn, sourceColumn)
      this._updateCounts(targetColumn, sourceColumn)
    }
  }

  _updateCounts(decrementColumn, incrementColumn) {
    this.countTargets.forEach(badge => {
      const col = badge.dataset.column
      if (col === decrementColumn) badge.textContent = Math.max(0, parseInt(badge.textContent || "0") - 1)
      if (col === incrementColumn) badge.textContent = parseInt(badge.textContent || "0") + 1
    })
  }

  _updateEmptyStates(...changedColumns) {
    this.dropzoneTargets.forEach(zone => {
      if (!changedColumns.includes(zone.dataset.column)) return
      const cardsEl = this._cardsContainer(zone)
      const hasCards = !!cardsEl.querySelector("[data-slug]")
      const emptyEl  = cardsEl.querySelector("[data-kanban-target='empty']")
      if (emptyEl) emptyEl.classList.toggle("hidden", hasCards)
    })
  }
}
