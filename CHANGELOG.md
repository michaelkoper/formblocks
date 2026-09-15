# Changelog

## 0.1.1 — 2026-09-15

- Responses: a URL answer that points at an image (an image file extension, or
  a Cloudinary-style `/image/upload/` path) is shown as a small thumbnail that
  links to the full image, on the response page and in the responses table.

## 0.1.0 — 2026-09-15

Initial release.

- Forms with pages of blocks, a builder with drag-and-drop, autosave and an
  in-place editable submit button.
- Block kinds: heading, paragraph, image, name, email, phone, URL, short
  text, long text, hidden, checkbox, radio group; a registry for host blocks.
- Templates (contact, lead capture, feedback) and form duplication.
- Public form pages with steps, browser and server validation, honeypot,
  per-IP rate limiting, hidden-field prefill from the query string, a
  thank-you page.
- Requires Rails 8.0 or newer and Ruby 3.2 or newer.
- Responses dashboard with CSV export and an `on_submit` hook.
- `bin/rails formblocks:seed_demo` for demo forms and responses.
- Per-form and global branding (logo, primary color, button text color).
- `config.storage_service`: store every upload on a named Active Storage
  service from the host's `config/storage.yml` — a dedicated bucket or
  folder, or a service entry with provider options such as Cloudinary's
  `folder:`/`tags:` — instead of the environment default.
- Admin gate, host base controller / layout, multi-tenancy, configurable
  admin and public paths, self-served assets, `config.app_name` for titles.
