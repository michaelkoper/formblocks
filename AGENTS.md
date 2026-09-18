# Formblocks — notes for agents

This file is for an AI agent (or a person in a hurry) that is either
installing the gem into a Rails app or working on the gem itself. The
README has the full story; this is the short version.

## Installing into a host app

1. `gem "formblocks"` in the Gemfile, `bundle install`.
2. `bin/rails generate formblocks:install` — writes the initializer, one
   migration (five `formblocks_*` tables, no Active Storage tables) and
   `mount_formblocks at: "/forms", public_at: "/f"` in routes.rb.
3. `bin/rails db:migrate`.
4. Set `config.authorize_admin` in `config/initializers/formblocks.rb`; the
   default allows the admin in development only.
5. Optional: `config.tenant` for multi-tenant apps, `config.on_submit` to
   react to responses, `config.base_controller_class` or
   `config.admin_layout` to put the admin inside an existing one.

Active Storage is optional. If the host has it, logos and image blocks work;
if not, those features are hidden. Never run `active_storage:install` on the
host's behalf without asking — most apps already have the tables.

Reach the admin at the mount path and published forms at
`#{public_path}/#{slug}`. The public URL helper in the host is
`formblocks_form_path(slug)`; the engine's own helpers are under the
`formblocks` route proxy (`formblocks.root_path`).

To link to a form with fields filled in advance, hidden or visible, pass the
answers by key through `Formblocks.prefill`:
`formblocks_form_path(slug, Formblocks.prefill(slug, user_id: user.id))`. The
URL then carries each field's opaque ID, not its key. Do not hard-code IDs
copied from the builder into host code — they differ per database.

## Working on the gem

- `bin/rails server` runs the dummy app in `test/dummy` (admin at
  http://localhost:3000/forms, allowed because it is development);
  `bin/rails app:formblocks:seed_demo` fills it with demo forms (`app:`
  because the gem's `bin/rails` drives the dummy app; a host runs
  `bin/rails formblocks:seed_demo`).
- `bundle exec rake test` runs models, integration and generator tests;
  `bundle exec rake test:system` runs the browser tests (headless Chrome);
  `bundle exec rubocop` lints.
- Layout of the code:
  - `lib/formblocks/configuration.rb` — every host option.
  - `lib/formblocks/engine.rb` — `mount_formblocks`, which mounts the admin
    engine and draws the public routes on the host's route set.
  - `lib/formblocks/assets/` — the CSS and Stimulus controllers, served by
    `Formblocks::AssetsController`; `lib/formblocks/assets.rb` fingerprints
    them and fills the `{{turbo.js}}` / `{{stimulus.js}}` import tokens.
  - `app/models/formblocks/block.rb` and `blocks/` — the STI hierarchy and
    the registry of kinds the palette offers.
  - `app/controllers/formblocks/dashboard_controller.rb` — the admin root,
    inheriting from `config.base_controller_class`;
    `public/forms_controller.rb` — the visitor-facing pages, always on
    `ActionController::Base`.
  - Admin views wrap themselves in `fb_admin_shell` so the assets and nav
    survive a host layout; public views live under
    `app/views/formblocks/public/`.
- Every user-facing string is in `config/locales/formblocks.en.yml`; views
  use lazy `t('.key')` lookups.
- Keep the split: nothing public may inherit the host's base controller.
