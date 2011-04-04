require 'zlib'

# Saves form as cookie as json+gzip
class MonkeyForms::GzipCookie
  def initialize options={}
    @cookie_name = options[:name]
  end

  def load options={}
    request = options[:request]
    return {} if request.blank?
    cookie = request.cookies[@cookie_name]
    return {} if cookie.blank?
    ActiveSupport::JSON.decode(Zlib::Inflate.inflate(cookie)).stringify_keys
  end

  def save options = {}
    attributes = options[:attributes]
    response   = options[:response]

    cookie_json = ActiveSupport::JSON.encode(attributes)
    cookie_json = Zlib::Deflate.deflate(cookie_json, Zlib::BEST_COMPRESSION)
    cookie_hash = { :value => cookie_json }
    response.set_cookie(@cookie_name, cookie_hash)
  end
end
