module MonkeyForms
  require 'monkey_forms/validation_scope'
  require 'active_model'
  require 'active_support/json'
  require 'zlib'

  module Form

    def self.included base
      base.send :include, InstanceMethods
      base.send :extend,  ClassMethods
      base.send :include, ActiveModel::Validations
      base.send :include, MonkeyForms::ValidationScopes
    end

    module InstanceMethods
      def initialize options = {}
        attrs     = options.delete(:form)    || {}
        @response = options.delete(:response)
        cookie   = options.delete(:storage) || {}

        @attributes = {}

        if cookie.present?
          cookie_hash = ActiveSupport::JSON.decode(Zlib::Inflate.inflate(cookie))
          cookie_hash.each do |key, value|
            @attributes[key.to_s] = value
          end
        end

        attrs.each do |name, value|
          @attributes[name.to_s] = value
        end
      end

      def save_to_storage!
        cookie_json = @attributes.to_json
        cookie_json = Zlib::Deflate.deflate(cookie_json, Zlib::BEST_COMPRESSION)
        cookie_hash = { :value => cookie_json }
        @response.set_cookie("form_storage", cookie_hash)
      end
    end

    module ClassMethods
      attr_reader :cookie_name

      def form_storage storage_type, options={}
        case storage_type
        when :cookie
          @cookie_name = options.delete(:name) || 'monkey_form_cookie'
        else
          raise ArgumentError.new "Unknown storage type picked"
        end
      end

      def form_attributes *attrs
        attrs.each do |attr|

          # Defines public method
          define_method attr do
            @attributes[attr.to_s]
          end
        end
      end
    end
  end
end
