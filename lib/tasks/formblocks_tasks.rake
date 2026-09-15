# frozen_string_literal: true

namespace :formblocks do
  desc 'Create or refresh formblocks demo data: three template forms and a few responses'
  task seed_demo: :environment do
    result = Formblocks::Seeds.load!
    puts "Seeded #{result[:forms].size} forms and #{result[:responses].size} responses."
    result[:forms].each { |form| puts "  #{form.status.ljust(9)} #{form.title} (#{form.slug})" }
  end
end
