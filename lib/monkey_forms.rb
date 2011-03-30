require 'active_model'

module MonkeyForms
  require 'validation_scope'

  module Form

    def self.included base
      base.send :include, InstanceMethods
      base.send :extend,  ClassMethods
      base.send :include, ActiveModel::Validations
      base.send :include, MonkeyForms::ValidationScopes
    end

    module InstanceMethods
      def initialize attrs={}
        @attributes = {}
        attrs.each do |name, value|
          @attributes[name.to_sym] = value
        end
      end
    end

    module ClassMethods
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
