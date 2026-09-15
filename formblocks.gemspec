# frozen_string_literal: true

require_relative 'lib/formblocks/version'

Gem::Specification.new do |spec|
  spec.name = 'formblocks'
  spec.version = Formblocks::VERSION
  spec.authors = ['Michael Koper']
  spec.email = ['hello@michaelkoper.com']

  spec.summary = 'Block-based form builder for Rails: multi-page forms, a builder UI, ' \
                 'public form pages, responses and CSV export — as a mountable engine.'
  spec.description = <<~DESC
    A mountable Rails engine that gives your app a form builder. Build forms
    from blocks (headings, paragraphs, images, and inputs like name, email,
    phone, URL, text, textarea, hidden, checkbox and radio group), spread them
    over pages, brand them with a logo and colors, publish them at a public
    URL, and read the responses in a dashboard or as CSV. Every block is a
    Ruby class you can subclass. Framework-agnostic: no CSS or JS framework
    required, and no asset pipeline needed.
  DESC
  spec.homepage = 'https://github.com/michaelkoper/formblocks'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = "#{spec.homepage}/tree/main"
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['bug_tracker_uri'] = "#{spec.homepage}/issues"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir[
    'app/**/*',
    'config/**/*',
    'lib/**/*',
    'MIT-LICENSE',
    'Rakefile',
    'README.md',
    'CHANGELOG.md',
    'AGENTS.md'
  ]
  spec.require_paths = ['lib']

  spec.add_dependency 'csv'
  spec.add_dependency 'rails', '>= 7.1', '< 9'
  # The engine serves Turbo and Stimulus itself, straight from these gems, so
  # it works in hosts with importmap, a JS bundler, or no JavaScript setup at all.
  spec.add_dependency 'stimulus-rails', '>= 1.2'
  spec.add_dependency 'turbo-rails', '>= 1.4'
end
