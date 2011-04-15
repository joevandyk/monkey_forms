module MonkeyForms
  require 'active_model'
  require 'active_support/hash_with_indifferent_access'
  require 'active_support/core_ext/object/try'
  require 'active_support/inflector'
  require 'grouped_validations'
  require 'monkey_forms/serializers'
  require 'monkey_forms/attribute_container'

  module Form
    def self.included base
      base.send :include, ActiveModel::Validations
      base.send :extend,  ActiveModel::Callbacks
      base.send :include, InstanceMethods
      base.send :extend,  ClassMethods
      base.instance_eval do
        define_model_callbacks :initialize
      end
      base.send :include, ActiveModel::Validations
    end

    module InstanceMethods
      include ActiveModel::Conversion
      attr_reader :attributes

      def persisted?
        false
      end

      def initialize options = {}
        _run_initialize_callbacks do
          form_params = options.delete(:form) || {}
          @options    = options

          @options.each do |key, value|
            instance_variable_set "@#{key}", value
          end

          # Load the saved form from storage
          hash =
            if self.class.form_storage
              self.class.form_storage.load(@options)
            else
              {}
            end

          # Merge in this form's params
          hash.merge!(form_params.stringify_keys)

          @attribute_container = AttributeContainer.build "base"
          self.class.attributes.each do |attribute|
            accessor = @attribute_container.add attribute
          end

          hash.each do |key, value|
            @attribute_container.add(key, value)
          end
        end
      end

      # Debug
      attr_accessor :attribute_container

      def attributes
        @attribute_container
      end

      def respond_to? *args
        @attribute_container.respond_to?(*args) || super
      end

      def method_missing method, *args, &block
        if @attribute_container.respond_to?(method)
          @attribute_container.send(method, *args, &block)
        else
          super
        end
      end

      def save_to_storage!
        @options[:attributes] = @attribute_container.to_hash
        self.class.form_storage.save(@options)
      end

    end

    module ClassMethods
      attr_reader :form_storage

      def attributes
        @attributes ||= []
      end

      # Compatibility with ActiveModel::Naming
      def model_name
        @_model_name ||= ActiveModelName.build(@_form_name.try(:to_s) || name.underscore.try(:underscore))
      end

      def form_name name
        @_form_name = name
      end

      def set_form_storage storage_object
        @form_storage = storage_object
      end

      def form_attributes *attrs
        attrs.each do |attr|
          attributes << attr
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
