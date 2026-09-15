/*
 * Formblocks public form — one Stimulus controller that turns the page's
 * <fieldset>s into steps. Without JavaScript every step is visible and the
 * form still submits as one; with it, one step shows at a time, "Next"
 * validates the current step with the browser's own constraint validation,
 * and a server-side error opens the step it belongs to.
 *
 * Stimulus is imported from the engine (it ships with stimulus-rails); no
 * Turbo here — a plain form post and redirect is all a visitor needs.
 */
const base = new URL(".", import.meta.url);
const { Application, Controller } = await import(new URL("{{stimulus.js}}", base));

document.documentElement.classList.add("fb-js");

class Pager extends Controller {
  static targets = ["step", "nav", "progress"];
  static values = { stepLabel: { type: String, default: "Step %{current} of %{total}" } };

  connect() {
    if (this.stepTargets.length < 2) return;
    const errored = this.stepTargets.findIndex((step) => step.hasAttribute("data-fb-pager-errors"));
    this.index = Math.max(0, errored);
    this.onKeydown = (event) => this.keydown(event);
    this.element.addEventListener("keydown", this.onKeydown);
    this.render();
  }

  disconnect() {
    if (this.onKeydown) this.element.removeEventListener("keydown", this.onKeydown);
  }

  render() {
    this.stepTargets.forEach((step, i) => { step.hidden = i !== this.index; });
    this.navTargets.forEach((button) => { button.hidden = false; });
    if (this.hasProgressTarget) {
      this.progressTarget.hidden = false;
      this.progressTarget.textContent = this.stepLabelValue
        .replace("%{current}", this.index + 1)
        .replace("%{total}", this.stepTargets.length);
    }
  }

  next() {
    if (!this.valid() || this.index >= this.stepTargets.length - 1) return;
    this.index += 1;
    this.render();
    this.focusStep();
  }

  back() {
    if (this.index === 0) return;
    this.index -= 1;
    this.render();
    this.focusStep();
  }

  valid() {
    const fields = this.stepTargets[this.index].querySelectorAll("input, textarea, select");
    for (const field of fields) {
      if (!field.checkValidity()) {
        field.reportValidity();
        return false;
      }
    }
    return true;
  }

  // Enter in a text field on a non-final step means "next", not "submit".
  keydown(event) {
    if (event.key !== "Enter" || event.target.tagName === "TEXTAREA" || event.target.type === "submit") return;
    if (this.index < this.stepTargets.length - 1) {
      event.preventDefault();
      this.next();
    }
  }

  focusStep() {
    this.element.scrollIntoView({ block: "start", behavior: "smooth" });
    const first = this.stepTargets[this.index].querySelector("input:not([type=hidden]), textarea, select");
    first?.focus({ preventScroll: true });
  }
}

const application = Application.start();
application.register("fb-pager", Pager);
