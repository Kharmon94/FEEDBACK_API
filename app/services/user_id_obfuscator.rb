# frozen_string_literal: true

class UserIdObfuscator
  # Must have unique chars (Sqids requirement). Replaced duplicate T with i.
  DEFAULT_ALPHABET = "k3G5QA7m9BxpqR2sT4vW6yZ8cD0eF1hJaLbMnPoSriuVwX"
  ALPHABET = (ENV["SQIDS_USER_ALPHABET"].presence || DEFAULT_ALPHABET).freeze

  def self.encode(id)
    sqids.encode([id.to_i])
  end

  def self.decode(public_id)
    ids = sqids.decode(public_id.to_s)
    ids.first if ids.size == 1
  end

  def self.sqids
    @sqids ||= Sqids.new(alphabet: ALPHABET, min_length: 6)
  end
end
