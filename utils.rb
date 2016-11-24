require "uri"

def valid_uri?(str)
  URI.parse(str).kind_of? URI::HTTP
rescue URI::InvalidURIError
  false
end
