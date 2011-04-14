module MonkeyForms
  require 'monkey_forms/serializers'
  require 'active_model'
  require 'active_support/hash_with_indifferent_access'
  require 'active_support/core_ext/object/try'
  require 'grouped_validations'

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
      attr_reader :attributes

      def persisted?
        false
      end

      def to_model
        self
      end

      def to_param
        nil
      end

      def to_key
        nil
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
              hash = self.class.form_storage.load(@options)
            else
              {}
            end

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
      attr_reader :form_storage

      def attributes
        @attributes ||= {}
      end

      # Compatibility with ActiveModel::Naming
      def model_name
        if !defined?(@_model_name)
          @_model_name = (@_form_name.try(:to_s) || name.underscore).try(:underscore)
          %w( singular human i18n_key partial_path plural ).each do |method|
            @_model_name.class_eval do
              define_method method do
                self
              end
            end
          end
        end
        @_model_name
      end

      def form_name name
        @_form_name = name
      end

      def set_form_storage storage_object
        @form_storage = storage_object
      end

      def form_attributes *attrs
        @attributes ||= []
        attrs.each do |attr|
          @attributes << attr

          name =
            if attr.class == Hash
              attr.keys.first
            else
              attr.to_s
            end

          define_method name do
            @attributes[name]
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
