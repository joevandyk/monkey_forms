$: << File.expand_path('monkey_forms/vendor/grouped_validations/lib', File.dirname(__FILE__))
$: << File.expand_path('monkey_forms/vendor/deep_merge/lib', File.dirname(__FILE__))

# Warning: This code is atrocious.
module MonkeyForms
  require 'active_model'
  require 'deep_merge' # TODO not sure if needed anymore.
  require 'virtus'

  module Form

    def self.included base
      base.send :include, ActiveModel::Validations
      base.send :extend,  ActiveModel::Callbacks
      base.send :include, Virtus
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
      base.instance_eval do
        define_model_callbacks :initialize, :save
      end
      base.send :include, ActiveModel::Validations
    end

    module ClassMethods
      def form_attribute name, klass, options={}
        options[:default] ||=
          if klass.kind_of?(Array)
            []
          elsif klass.respond_to?(:new)
            klass.new
          else
            ""
          end
        attribute name, klass, options
      end

      def validates_associated(*associations)
        validates_each(associations) do |record, associate_name, value|
          (value.respond_to?(:each) ? value : [value]).each do |rec|
            if rec && !rec.valid?
              rec.errors.each do |key, value|
                record.errors.add(key, value)
              end
            end
          end
        end
      end
    end

    module InstanceMethods
      def persisted?
        false
      end

      def to_model
        self
      end

      def to_partial_path
        "some_path" # TODO figure out what's needed here for Rails 3.2
      end

      def to_param
        nil
      end

      def to_key
        nil
      end

      def save
        run_callbacks :save do
          if !valid?
            return false
          end
        end
        self
      end

      def initialize options = {}
        _run_initialize_callbacks do
          options[:form] ||= {}
          options[:form].each do |name, value|
            self.send "#{name}=", value
          end
        end
        super
      end

      def save_to_storage!
        @options[:attributes] = attributes
        self.class.form_storage.save(@options)
      end
    end
  end
end
