# Model Address Standard (MAS) — decode/encode MAS URIs.
#
# Usage:
#   MAS.decode("https://api.example.com#m=gpt-4o&k=sk-xyz")
#   # => {"m" => "gpt-4o", "k" => "sk-xyz"}
#   MAS.encode({"m" => "gpt-4o"})
#   # => "#m=gpt-4o"

require "uri"

module MAS
  # Extract MAS parameters (+m+, +k+) from an HTTP/HTTPS URI.
  #
  # @param uri [String] a valid MAS address (any HTTP(S) URI with a
  #   fragment containing at least an +m+ parameter)
  # @return [Hash] hash with key "m" (the model identifier) and
  #   optionally "k" (the API key)
  # @raise [RuntimeError] if the fragment is missing, +m+ is absent,
  #   or +m+ is empty
  def self.decode(uri)
    parsed = URI.parse(uri)
    fragment = parsed.fragment
    raise "MAS: fragment is required" unless fragment

    params = {}
    fragment.split("&").each do |part|
      key, value = part.split("=", 2)
      key = URI.decode_www_form_component(key.to_s)
      value = URI.decode_www_form_component(value.to_s)

      if key == "m"
        raise "MAS: m must not be empty" if value.nil? || value.empty?
        params["m"] = value
      elsif key == "k" && value && !value.empty?
        params["k"] = value
      end
    end

    raise "MAS: m is required" unless params.key?("m")
    params
  end

  # Build a MAS fragment string from a hash with +m+ and optional +k+.
  #
  # @param obj [Hash] hash with a non-empty "m" key and optionally a "k" key
  # @return [String] URI fragment of the form +#m=...&k=...+
  # @raise [RuntimeError] if +m+ is missing or empty
  def self.encode(obj)
    m = obj["m"]
    raise "MAS: m is required and must be non-empty" if m.nil? || m.empty?

    parts = ["m=#{URI.encode_www_form_component(m)}"]
    k = obj["k"]
    parts << "k=#{URI.encode_www_form_component(k)}" if k && !k.empty?

    "##{parts.join("&")}"
  end
end
