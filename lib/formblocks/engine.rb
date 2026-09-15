# frozen_string_literal: true

module Formblocks
  class Engine < ::Rails::Engine
    isolate_namespace Formblocks

    rake_tasks do
      load File.expand_path('../tasks/formblocks_tasks.rake', __dir__)
    end

    # The public form pages are drawn on the HOST's route set, not the
    # engine's, so they can live at a path of the host's choosing that is
    # separate from the admin mount. `mount_formblocks` does both in one line.
    #
    # The mount is named `formblocks` on purpose: the engine's views reach
    # their own assets through that proxy even when a request came in through
    # a host route (the public pages) or a host layout.
    initializer 'formblocks.routing' do
      ActionDispatch::Routing::Mapper.include(Module.new do
        def mount_formblocks(at: Formblocks.config.mount_path, public_at: Formblocks.config.public_path, **options)
          Formblocks.config.mount_path = at
          Formblocks.config.public_path = public_at
          mount Formblocks::Engine, at:, as: :formblocks, **options

          public_at = public_at.to_s.chomp('/')
          get "#{public_at}/:slug", to: 'formblocks/public/forms#show', as: :formblocks_form
          post "#{public_at}/:slug", to: 'formblocks/public/forms#create'
          get "#{public_at}/:slug/thanks", to: 'formblocks/public/forms#thanks', as: :formblocks_form_thanks
        end
      end)
    end
  end
end
