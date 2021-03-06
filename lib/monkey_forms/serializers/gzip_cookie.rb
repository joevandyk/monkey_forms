# encoding: UTF-8
require 'zlib'

# Saves form as cookie as json+gzip
class MonkeyForms::Serializers::GzipCookie
  def initialize options={}
    @cookie_name = options[:name].to_s
    @domain      = options[:domain].to_s
    @secure      = options[:secure]
    @httponly    = options[:httponly]
    @path        = (options[:path] || '/').to_s
  end

  def load options={}
    request = options[:request]
    result = ActiveSupport::HashWithIndifferentAccess.new
    return result if request.blank?
    cookie = request.cookies[@cookie_name]
    return result if cookie.nil? or cookie.empty?
    begin
      result.merge!(ActiveSupport::JSON.decode(Zlib::Inflate.inflate(cookie)).stringify_keys)
    rescue Zlib::DataError
      return result
    end
  end

  def save options = {}
    attributes = options[:attributes]
    response   = options[:response]

    cookie_json = ActiveSupport::JSON.encode(attributes)
    cookie_json = Zlib::Deflate.deflate(cookie_json, Zlib::BEST_COMPRESSION)
    cookie_hash = { :value    => cookie_json,
                    :httponly => @httponly,
                    :secure   => @secure,
                    :domain   => @domain,
                    :path     => @path }
    response.set_cookie(@cookie_name, cookie_hash)
  end
end
