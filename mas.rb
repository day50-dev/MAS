require "uri"

module MAS
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

  def self.encode(obj)
    m = obj["m"]
    raise "MAS: m is required and must be non-empty" if m.nil? || m.empty?

    parts = ["m=#{URI.encode_www_form_component(m)}"]
    k = obj["k"]
    parts << "k=#{URI.encode_www_form_component(k)}" if k && !k.empty?

    "##{parts.join("&")}"
  end
end
