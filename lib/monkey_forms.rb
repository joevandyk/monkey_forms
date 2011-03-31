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
      def initialize options = {}
        attrs   = options.delete(:form)    || {}
        @cookie = options.delete(:storage) || {}

        # TODO handle properly (encode, gzip, etc)
        @attributes = @cookie

        attrs.each do |name, value|
          @attributes[name.to_sym] = value
        end
      end

      private

      def attributes
        @attributes
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
            @attributes[attr]
          end
        end
      end
    end
  end
end
