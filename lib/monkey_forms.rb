module MonkeyForms
  require 'monkey_forms/validation_scope'
  require 'active_model'

  module Form

    def self.included base
      base.send :include, InstanceMethods
      base.send :extend,  ClassMethods
      base.send :include, ActiveModel::Validations
      base.send :include, MonkeyForms::ValidationScopes
    end

    module InstanceMethods
      def initialize attrs={}
        # TODO handle properly (encode, gzip, etc)
        @cookie     = attrs.delete(self.class.cookie_name.to_sym) || {}
        @attributes = @cookie

        attrs.each do |name, value|
          @attributes[name.to_sym] = value
        end
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
          define_method attr do
            @attributes[attr]
          end
        end
      end
    end
  end
end
