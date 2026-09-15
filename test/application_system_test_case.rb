# frozen_string_literal: true

require 'test_helper'

# A chromedriver on PATH that is older than the installed Chrome (Homebrew's
# often lags) fails every session. With no driver on PATH, Selenium Manager
# fetches one that matches the browser, so drop those directories here —
# for this process only.
ENV['PATH'] = ENV['PATH'].split(File::PATH_SEPARATOR)
                         .reject { |dir| File.exist?(File.join(dir, 'chromedriver')) }
                         .join(File::PATH_SEPARATOR)

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1200, 900]
end
