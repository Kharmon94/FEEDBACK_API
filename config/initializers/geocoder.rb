# frozen_string_literal: true

# Geocoder configuration for IP geolocation (feedback analytics).
# Uses ip-api.com - free: 45 req/min, no API key. For higher volume, use MaxMind GeoLite2 (maxmind_local).
Geocoder.configure(
  ip_lookup: :ipapi_com,
  use_https: true,
  timeout: 3,
  cache: Rails.cache
)
