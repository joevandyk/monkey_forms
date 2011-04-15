module MonkeyForms
  class AttributeContainer
    require 'active_support/hash_with_indifferent_access'
    require 'monkey_forms/active_model_name'
    include ActiveModel::Validations
    include ActiveModel::Conversion
    include ActiveModel::Naming

    attr_reader :attributes

    def initialize *args
      @attributes = ActiveSupport::HashWithIndifferentAccess.new
      if args.present?
        add(*args)
      end
    end

    def self.build name, *args
      klass = Class.new(AttributeContainer)
      eval <<-EVAL
        def klass.model_name
          @name ||= ActiveModelName.build('#{name}')
        end
      EVAL
      klass.new(*args)
    end

    def method_missing method, *args, &block
      @attributes.send method, *args, &block
    end

    def persisted?
      false
    end

    def add attribute, value = ""
      if attribute.class == String
        attribute = attribute.to_sym
      end
      if attribute.class == Symbol
        merge attribute, do_something_with_value(attribute, value)
      elsif attribute.class == Hash
        attribute.each do |key, value|
          merge key, do_something_with_value(key, value)
        end
      elsif attribute.class == Array
        attribute.each do |a|
          if a.class == Symbol
            merge a, do_something_with_value(a, value)
          elsif a.class == Hash
            a.each do |key, value|
              merge key, do_something_with_value(key, value)
            end
          else
            fail a.inspect
          end
        end
      else
        raise attribute.inspect
      end
    end

    def to_hash
      {}.tap do |h|
        @attributes.each do |key, value|
          h[key] = value.respond_to?(:to_hash) ? value.to_hash : value
        end
      end
    end

    def merge key, value
      if ! @attributes.key?(key)
        set_key key, value
      else
        if @attributes[key].class == String
          set_key key, value
        elsif @attributes[key].respond_to?(:attributes)
          # TODO figure out merge here
          @attributes[key].attributes.keys.each do |k|
            #if value.respond_to?(:attributes)
              if value.attributes[k]
                @attributes[key].merge(k, value.attributes[k])
              end
            #end
          end
        else
          fail @attributes[key].class.inspect
        end
      end
    end

    private

    def set_key key, value
      @attributes[key] = value
      class_eval do
        define_method key do
          @attributes[key]
        end

        if value.respond_to?(:attributes)
          define_method "#{key}_attributes" do
            @attributes[key]
          end

          define_method "#{key}_attributes=" do |*something|
            fail "I don't think I need to do anything, just the existence is enough for Rails."
          end
        end
      end
    end

    def do_something_with_value key, value
      if value.class == String || value.class == Symbol || value.class == TrueClass || value.class == FalseClass
        value
      elsif value.class == Array or value.class == Hash
        AttributeContainer.build(key, value)
      elsif value.respond_to?(:attributes)
        value
      else
        value
        #fail "Unknown class #{ self.inspect }"
      end
    end
  end
end
