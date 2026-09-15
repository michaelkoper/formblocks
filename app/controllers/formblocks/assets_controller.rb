# frozen_string_literal: true

module Formblocks
  # Serves the engine's CSS and JavaScript as plain same-origin files (see
  # Formblocks::Assets). Same-origin matters: under a `script-src 'self'`
  # CSP an external script from the app's own host is always allowed.
  class AssetsController < ApplicationController
    # Static, no user data; without this Rails' cross-origin JavaScript
    # guard refuses to serve a script to a plain <script src> request.
    skip_forgery_protection

    # The URLs carry a content fingerprint (?v=<md5>), so stale code is
    # structurally impossible: new code means a new URL. The canonical
    # fingerprinted URL gets long-lived caching; anything else only
    # ETag-revalidates.
    def show
      source, content_type = Assets.lookup(params[:name])
      return head :not_found unless source

      fingerprint = Assets.fingerprint(params[:name])
      expires_in 1.year, public: true if params[:v] == fingerprint
      return unless stale?(etag: [Formblocks::VERSION, fingerprint])

      render plain: source, content_type:
    end
  end
end
