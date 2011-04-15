module MonkeyForms
  class AttributeContainer
    include ActiveModel::Validations
    include ActiveModel::Conversion

    attr_reader :attributes

    def initialize *args
      @attributes = {}
      if args.present?
        add(*args)
      end
    end

    def add attribute, value = ""
      if attribute.class == String
        raise ArgumentError.new("form attributes must be symbols! (was #{ attribute }")
      elsif attribute.class == Symbol
        @attributes[attribute] = do_something_with_value(value)
      elsif attribute.class == Hash
        attribute.each do |key, value|
          @attributes[key] = do_something_with_value(value)
        end
      elsif attribute.class == Array
        attribute.each do |a|
          if a.class == Symbol
            @attributes[a] = do_something_with_value(value)
          else
            fail
          end
        end
      else
        raise attribute.inspect
      end
    end

    def respond_to? method, *args
      @attributes[method] || super
    end

    def method_missing method, *args, &block
      @attributes[method] || super
    end

    private

    def do_something_with_value value
      if value.class == String || value.class == Symbol
        value
      elsif value.class == Array or value.class == Hash
        AttributeContainer.new(value)
      else
        fail "Unknown class #{ self.inspect }"
      end
    end
  end
end
