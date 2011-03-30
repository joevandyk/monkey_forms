# From https://github.com/dasil003/validation_scopes
# JVD modified this for Rails 3

require 'delegate'

module MonkeyForms::ValidationScopes
  def self.included(base) # :nodoc:
    base.extend ClassMethods
  end

  module ClassMethods
    def validation_scope(scope)
      base_class = self
      deferred_proxy_class_declaration = Proc.new do
        proxy_class = Class.new(DelegateClass(base_class)) do
          include ActiveModel::Validations

          def initialize(record)
            @base_record = record
            super(record)
          end

          ## Hack since DelegateClass doesn't seem to be making AR::Base class methods available.
          define_method("errors") do
            @errors ||= ActiveModel::Errors.new(@base_record)
          end
        end

        yield proxy_class

        proxy_class
      end

      define_method(scope) do
        send("validation_scope_proxy_for_#{scope}").errors
      end

      define_method("no_#{scope}?") do
        send("validation_scope_proxy_for_#{scope}").valid?
      end

      define_method("has_#{scope}?") do
        send("validation_scope_proxy_for_#{scope}").invalid?
      end

      define_method("init_validation_scope_for_#{scope}") do
        unless instance_variable_defined?("@#{scope}")
          klass = deferred_proxy_class_declaration.call
          instance_variable_set("@#{scope}", klass.new(self))
        end
      end

      define_method("validation_scope_proxy_for_#{scope}") do
        send "init_validation_scope_for_#{scope}"
        instance_variable_get("@#{scope}")
      end
    end
  end
end
