$: << File.expand_path('monkey_forms/vendor/grouped_validations/lib', File.dirname(__FILE__))
$: << File.expand_path('monkey_forms/vendor/deep_merge/lib', File.dirname(__FILE__))
module MonkeyForms
  require 'monkey_forms/serializers'
  require 'active_model'
  require 'active_support/hash_with_indifferent_access'
  require 'active_support/core_ext/object/try'

  require 'grouped_validations'
  require 'deep_merge'

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

      # TODO not sure what's best here
      def html_error_messages
        errors.full_messages.join("<br />")
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
          @attributes =
            if self.class.form_storage
              self.class.form_storage.load(@options)
            else
              ActiveSupport::HashWithIndifferentAccess.new
            end

          # Merge in this form's params
          DeepMerge.deep_merge!(form_params, @attributes)

          self.class.attributes.each do |a|
            @attributes[a] ||= ""
            if self.class.strip_attributes?
              @attributes[a].strip! if @attributes[a].class == String
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
          # EWWWW
          @_model_name = (@_form_name.try(:to_s) ||
                          superclass.instance_variable_get(:@_form_name).try(:to_s) ||
                          name.underscore).try(:underscore)
          %w( singular human i18n_key partial_path plural param_key).each do |method|
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

      def dont_strip_form_attributes!
        @_strip_attributes = false
      end

      def strip_attributes?
        return true if !defined?(@_strip_attributes)
        return @_strip_attributes
      end

      def set_form_attribute_human_names options
        @_form_attribute_names ||= {}
        @_form_attribute_names.merge!(options)
      end

      def human_attribute_name name, *options
        @_form_attribute_names ||= {}
        @_form_attribute_names[name] || super
      end

      def form_attributes *attrs
        @attributes ||= []
        attrs.each do |attr|
          @attributes << attr

          # Defines public method
          define_method attr do
            @attributes[attr.to_s]
          end
          define_method "#{attr}=" do |value|
            @attributes[attr.to_s] = value
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
