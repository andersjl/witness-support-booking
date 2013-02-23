secret = ENV[ "WITNESS_SUPPORT_BOOKING_SECRET"].to_s
if secret.length < 30
  raise "Secret token #{ secret.inspect} cannot be loaded"
else
  WitnessSupportBooking::Application.config.secret_token = secret
end

