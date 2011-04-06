module MonkeyForms
  require 'monkey_forms/validation_scope'
  require 'monkey_forms/serializers'
  require 'active_model'
  require 'active_support/hash_with_indifferent_access'

  module Form

    def self.included base
      base.send :include, ActiveModel::Validations
      base.send :extend,  ActiveModel::Callbacks
      base.send :include, InstanceMethods
      base.send :extend,  ClassMethods
      base.send :include, MonkeyForms::ValidationScopes

      base.instance_eval do
        define_model_callbacks :initialize
      end
    end

    module InstanceMethods
      attr_reader :attributes

      def initialize options = {}
        _run_initialize_callbacks do
          form_params = options.delete(:form) || {}
          @options    = options

          @options.each do |key, value|
            instance_variable_set "@#{key}", value
          end

          # Load the saved form from storage
          hash = self.class.form_storage.load(@options)

          # Merge in this form's params
          hash.merge!(form_params.stringify_keys)

          @attributes = ActiveSupport::HashWithIndifferentAccess.new

          self.class.attributes.each do |a|
            @attributes[a] = ""
          end

          hash.each do |key, value|
            value.strip! if value.respond_to?(:strip!)
            @attributes[key] = value
          end
        end
      end

      def save_to_storage!
        @options[:attributes] = @attributes
        self.class.form_storage.save(@options)
      end

    end

    module ClassMethods
      attr_reader :form_storage, :attributes

      def set_form_storage storage_object
        @form_storage = storage_object
      end

      def form_attributes *attrs
        @attributes ||= []
        attrs.each do |attr|
          @attributes << attr

          # Defines public method
          define_method attr do
            @attributes[attr.to_s]
          end
        end
      end

      def custom_attributes *attrs
        attrs.each do |attr|
          instance_eval do
            attr_reader attr
          end
        end
      end
    end
  end
end
