Rails.application.config.session_store :cookie_store,
  key: "_briefly_session",
  expire_after: 12.hours,
  secure: Rails.env.production?,
  httponly: true,
  same_site: :lax
