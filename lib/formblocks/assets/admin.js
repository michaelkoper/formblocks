/*
 * Formblocks admin — the Stimulus controllers behind the builder.
 *
 * Served by the engine as an ES module. Turbo and Stimulus are imported from
 * the engine as well (they ship with the turbo-rails and stimulus-rails gems
 * the engine depends on), so no host build step or importmap is involved.
 * A host that already runs Turbo keeps its own; a second Turbo would start a
 * second session.
 *
 * Every identifier is prefixed `fb-`, so a host's own Stimulus application
 * (which also scans the document) ignores them, and ours ignores the host's.
 * The double-brace tokens below are filled in with fingerprinted URLs when served.
 */
const base = new URL(".", import.meta.url);
if (!window.Turbo) await import(new URL("{{turbo.js}}", base));
const { Application, Controller } = await import(new URL("{{stimulus.js}}", base));

document.documentElement.classList.add("fb-js");

const csrfToken = () => document.querySelector('meta[name="csrf-token"]')?.content || "";

// Saves a form on input (debounced) or change (immediately) through Turbo,
// and reports the outcome in a status target. Text edits answer 204, so the
// field being typed in is never re-rendered under the cursor.
class Autosave extends Controller {
  static targets = ["status"];
  static values = {
    saving: { type: String, default: "Saving…" },
    saved: { type: String, default: "Saved" },
    failed: { type: String, default: "Could not save" },
  };

  connect() {
    this.dirty = false;
    this.submitting = false;
    this.pending = false;
  }

  disconnect() {
    clearTimeout(this.timer);
    clearTimeout(this.fadeTimer);
  }

  queue() {
    this.dirty = true;
    clearTimeout(this.timer);
    this.timer = setTimeout(() => this.save(), 700);
  }

  save() {
    clearTimeout(this.timer);
    if (!this.dirty) return;
    if (this.submitting) {
      this.pending = true;
      return;
    }
    this.dirty = false;
    this.submitting = true;
    this.show(this.savingValue, false);
    this.element.requestSubmit();
  }

  finished(event) {
    this.submitting = false;
    const ok = event.detail?.success;
    this.show(ok ? this.savedValue : this.failedValue, !ok);
    if (ok) this.fade();
    if (this.pending) {
      this.pending = false;
      this.save();
    }
  }

  show(text, error) {
    if (!this.hasStatusTarget) return;
    clearTimeout(this.fadeTimer);
    this.statusTarget.textContent = text;
    this.statusTarget.classList.toggle("is-error", error);
    this.statusTarget.style.opacity = 1;
  }

  fade() {
    this.fadeTimer = setTimeout(() => {
      if (this.hasStatusTarget) this.statusTarget.style.opacity = 0;
    }, 1500);
  }
}

// Drag-and-drop ordering with the browser's own drag events — no library.
// Only the grip handle starts a drag, so text in the inputs stays selectable.
// The new order is PATCHed as JSON; the move buttons remain for keyboards.
class Sortable extends Controller {
  static targets = ["item"];
  static values = { url: String };

  connect() {
    this.handlers = {
      mousedown: (event) => this.arm(event),
      dragstart: (event) => this.dragstart(event),
      dragover: (event) => this.dragover(event),
      drop: (event) => this.drop(event),
      dragend: () => this.dragend(),
    };
    for (const [name, handler] of Object.entries(this.handlers)) this.element.addEventListener(name, handler);
  }

  disconnect() {
    for (const [name, handler] of Object.entries(this.handlers)) this.element.removeEventListener(name, handler);
  }

  arm(event) {
    const handle = event.target.closest?.("[data-fb-sortable-handle]");
    const item = handle?.closest("[data-fb-sortable-target='item']");
    if (item) item.draggable = true;
  }

  dragstart(event) {
    const item = event.target.closest?.("[data-fb-sortable-target='item']");
    if (!item || !item.draggable) return;
    this.dragging = item;
    event.dataTransfer.effectAllowed = "move";
    try { event.dataTransfer.setData("text/plain", item.dataset.id); } catch (_) { /* IE */ }
    requestAnimationFrame(() => item.classList.add("fb-dragging"));
  }

  dragover(event) {
    if (!this.dragging) return;
    event.preventDefault();
    event.dataTransfer.dropEffect = "move";
    const over = event.target.closest?.("[data-fb-sortable-target='item']");
    if (!over || over === this.dragging || over.parentNode !== this.element) return;
    const rect = over.getBoundingClientRect();
    const before = event.clientY < rect.top + rect.height / 2;
    this.element.insertBefore(this.dragging, before ? over : over.nextSibling);
  }

  drop(event) {
    if (this.dragging) event.preventDefault();
  }

  dragend() {
    if (!this.dragging) return;
    this.dragging.classList.remove("fb-dragging");
    this.dragging.draggable = false;
    this.dragging = null;
    this.persist();
  }

  persist() {
    const ids = this.itemTargets.map((item) => item.dataset.id);
    fetch(this.urlValue, {
      method: "PATCH",
      credentials: "same-origin",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken(),
        Accept: "text/vnd.turbo-stream.html, text/html",
      },
      body: JSON.stringify({ ids }),
    });
  }
}

// Copies the public URL on the "published" page.
class Clipboard extends Controller {
  static targets = ["source", "label"];
  static values = { copied: { type: String, default: "Copied!" } };

  async copy() {
    const text = this.sourceTarget.value ?? this.sourceTarget.textContent;
    try {
      await navigator.clipboard.writeText(text);
    } catch (_) {
      this.sourceTarget.select?.();
      document.execCommand?.("copy");
    }
    if (!this.hasLabelTarget) return;
    const original = this.labelTarget.textContent;
    this.labelTarget.textContent = this.copiedValue;
    setTimeout(() => (this.labelTarget.textContent = original), 1500);
  }
}

// Keeps a hex text field and a native color picker in sync. The text field
// is the value that is saved: blank means "inherit".
class Color extends Controller {
  static targets = ["picker", "text"];

  pick() {
    this.textTarget.value = this.pickerTarget.value;
    this.textTarget.dispatchEvent(new Event("input", { bubbles: true }));
  }

  type() {
    const value = this.textTarget.value.trim();
    if (/^#[0-9a-f]{6}$/i.test(value)) this.pickerTarget.value = value;
  }
}

// Sizes the page-button input to its text, so it looks like the button it is.
class Autosize extends Controller {
  connect() { this.resize(); }

  resize() {
    const length = this.element.value.length || this.element.placeholder?.length || 4;
    this.element.style.width = `calc(${length + 1}ch + 36px)`;
  }
}

const application = Application.start();
application.register("fb-autosave", Autosave);
application.register("fb-sortable", Sortable);
application.register("fb-clipboard", Clipboard);
application.register("fb-color", Color);
application.register("fb-autosize", Autosize);
