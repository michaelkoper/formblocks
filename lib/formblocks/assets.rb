# frozen_string_literal: true

require 'digest'

module Formblocks
  # The engine's CSS and JavaScript, served by the engine itself rather than
  # the host's asset pipeline — so the builder works in a host with Sprockets,
  # Propshaft, a JS bundler, importmap, or nothing at all. The files live
  # under lib/ so a host that does run a pipeline never ingests them either.
  #
  # Turbo and Stimulus come straight from the turbo-rails and stimulus-rails
  # gems the engine depends on, so the host's bundle decides their versions.
  module Assets
    OWN = {
      'admin.css' => ['admin.css', 'text/css'],
      'admin.js' => ['admin.js', 'text/javascript'],
      'public.css' => ['public.css', 'text/css'],
      'public.js' => ['public.js', 'text/javascript']
    }.freeze

    class << self
      def names
        OWN.keys + %w[turbo.js stimulus.js]
      end

      # [source, content_type] or nil for an unknown name.
      def lookup(name)
        case name
        when 'turbo.js' then [read(turbo_path), 'text/javascript']
        when 'stimulus.js' then [read(stimulus_path), 'text/javascript']
        else
          file, type = OWN[name]
          file && [link(read(File.expand_path("assets/#{file}", __dir__))), type]
        end
      end

      # Content fingerprint for cache-busting URLs: a changed file is a changed
      # URL, so no browser can ever run stale code.
      def fingerprint(name)
        fingerprints[name] ||= Digest::MD5.hexdigest(lookup(name).first)
      end

      def path(name)
        "#{Formblocks.config.mount_path.chomp('/')}/assets/#{name}?v=#{fingerprint(name)}"
      end

      private

      # Our modules import Turbo and Stimulus by URL. The `{{turbo.js}}`
      # tokens become fingerprinted paths here, so those imports get the same
      # long-lived caching as everything else.
      def link(source)
        source.gsub(/\{\{(turbo\.js|stimulus\.js)\}\}/) do
          "#{Regexp.last_match(1)}?v=#{fingerprint(Regexp.last_match(1))}"
        end
      end

      def read(path)
        Rails.env.development? ? File.read(path) : (cache[path] ||= File.read(path))
      end

      def cache
        @cache ||= {}
      end

      def fingerprints
        Rails.env.development? ? {} : (@fingerprints ||= {})
      end

      def turbo_path
        require 'turbo-rails'
        Turbo::Engine.root.join('app/assets/javascripts/turbo.min.js').to_s
      end

      def stimulus_path
        require 'stimulus-rails'
        Stimulus::Engine.root.join('app/assets/javascripts/stimulus.min.js').to_s
      end
    end
  end
end
