module MonkeyForms
  require 'monkey_forms/serializers'
  require 'active_model'
  require 'active_support/hash_with_indifferent_access'
  require 'active_support/core_ext/object/try'
  require 'active_support/inflector'
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

    class AttributeContainer < ActiveSupport::HashWithIndifferentAccess
      include ActiveModel::Validations
      include ActiveModel::Conversion

      def self.object_for_attribute attribute, object
        class_name = attribute.to_s.camelize
        klass = Class.new(AttributeContainer) do
          @_name = class_name
          %w( singular human i18n_key partial_path plural ).each do |method|
            @_name.class_eval do
              define_method method do
                self.underscore
              end
            end
          end
          def self.model_name() @_name end
        end

        if object.class == Array
          object.map { |o| klass.new(o) }
        else
          obj = klass.new(object)
          if object.class == Hash
            object.keys.each do |key|
              obj.class_eval do
                define_method "#{key}_attributes" do
                  send key
                end
                define_method "#{key}_attributes=" do
                  # What goes here?
                  fail
                end
              end
            end
          end
          obj
        end
      end

      def method_missing method, *args, &block
        if key?(method)
          a = self[method]
          if a.class == ActiveSupport::HashWithIndifferentAccess
            AttributeContainer.object_for_attribute(method, a)
          else
            a
          end
        else
          super
        end
      end

      def persisted?
        false
      end
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
              hash = self.class.form_storage.load(@options)
            else
              {}
            end

          # Merge in this form's params
          hash.merge!(form_params.stringify_keys)

          @attributes = ActiveSupport::HashWithIndifferentAccess.new

          # Unsure if this is needed
          self.class.attributes.each do |a|
            @attributes[a] = ""
          end

          hash.each do |key, value|
            value.strip! if value.respond_to?(:strip!)
            if value.class == Hash || value.class == Array
              obj = AttributeContainer.object_for_attribute(key, value)
              @attributes[key] = obj
            else
              @attributes[key] = value
            end
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

          if attr.class == String or attr.class == Symbol
            @attributes << attr
          elsif attr.class == Hash
            attr.keys.each do |a|
              @attributes << a
            end
          else
            raise "unknown arg type"
          end

          name =
            if attr.class == Hash
              attr.keys.first
            else
              attr.to_s
            end

          if attr.class == Hash
            define_method "#{name}_attributes=" do |a|
              # what goes here?
              fail
            end

            define_method "#{name}_attributes" do
              send name
            end
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
