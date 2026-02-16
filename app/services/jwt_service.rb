# frozen_string_literal: true

class JwtService
  SECRET = Rails.application.secret_key_base
  ALG = "HS256"
  EXP = 7.days

  def self.encode(payload, exp: 7.days.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET, ALG)
  end

  def self.decode(token)
    body = JWT.decode(token, SECRET, true, { algorithm: ALG })[0]
    ActiveSupport::HashWithIndifferentAccess.new(body)
  rescue JWT::DecodeError
    nil
  end
end
