require 'msgpack'

# Saves form as cookie as json+gzip
class MonkeyForms::Serializers::MessagePackJson
  def initialize options={}
    @cookie_name = options[:name]
    @domain      = options[:domain]
    @secure      = options[:secure]
    @httponly    = options[:httponly]
  end

  def load options={}
    request = options[:request]
    result = ActiveSupport::HashWithIndifferentAccess.new
    return result if request.blank?
    cookie = request.cookies[@cookie_name]
    return result if cookie.blank?
    result.merge!(ActiveSupport::JSON.decode(MessagePack.unpack(cookie)).stringify_keys)
  end

  def save options = {}
    attributes = options[:attributes]
    response   = options[:response]

    cookie_json = ActiveSupport::JSON.encode(attributes).to_msgpack
    cookie_hash = { :value    => cookie_json,
                    :httponly => @httponly,
                    :secure   => @secure,
                    :domain   => @domain }
    response.set_cookie(@cookie_name, cookie_hash)
  end
end
