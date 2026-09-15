Rails.application.routes.draw do
  mount_formblocks at: "/forms", public_at: "/f"

  root to: redirect("/forms")
end
