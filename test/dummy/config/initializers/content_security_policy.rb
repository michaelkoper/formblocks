# A strict, nonce-based policy for scripts and styles. The engine's pages have
# to work under it: its scripts are same-origin modules, its brand colors go
# through a nonced <style>, and nothing uses an inline style attribute or an
# inline handler. Tests assert the nonce shows up; the browser tests would
# stop working if anything were blocked.
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.script_src  :self
    policy.style_src   :self
    policy.img_src     :self, :data, :https
    policy.font_src    :self, :data
    policy.connect_src :self
  end
  config.content_security_policy_nonce_generator = ->(_request) { "testnonce" }
  config.content_security_policy_nonce_directives = %w[script-src style-src]
end
