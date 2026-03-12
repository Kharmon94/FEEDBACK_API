# frozen_string_literal: true

class LocationIdObfuscator
  DEFAULT_ALPHABET = "FxnXM1kBN6cuhsAvjW3Co7l2RePyY8DwaU04Tzt9fHQrqSVKdpimLGIJOgb5ZE"
  ALPHABET = (ENV["SQIDS_ALPHABET"].presence || DEFAULT_ALPHABET).freeze

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
