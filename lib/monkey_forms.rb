module MonkeyForms
  require 'monkey_forms/validation_scope'
  require 'active_model'

  autoload :GzipCookie, 'monkey_forms/gzip_cookie'

  module Form

    def self.included base
      base.send :include, InstanceMethods
      base.send :extend,  ClassMethods
      base.send :include, ActiveModel::Validations
      base.send :include, MonkeyForms::ValidationScopes
    end

    module InstanceMethods
      def initialize options = {}
        form_params = options.delete(:form) || {}
        @options    = options

        # Load the saved form from storage
        hash = self.class.form_storage.load(@options)

        # Merge in this form's params
        hash.merge!(form_params.stringify_keys)

        @attributes = {}
        hash.each do |key, value|
          @attributes[key.to_s] = value
        end
      end

      def save_to_storage!
        @options[:attributes] = @attributes
        self.class.form_storage.save(@options)
      end
    end

    module ClassMethods
      attr_reader :form_storage
      def set_form_storage storage_object
        @form_storage = storage_object
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
