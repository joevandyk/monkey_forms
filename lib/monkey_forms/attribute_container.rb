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
        merge attribute, do_something_with_value(value)
      elsif attribute.class == Hash
        attribute.each do |key, value|
          merge key, do_something_with_value(value)
        end
      elsif attribute.class == Array
        attribute.each do |a|
          if a.class == Symbol
            merge a, do_something_with_value(value)
          elsif a.class == Hash
            a.each do |key, value|
              merge key, do_something_with_value(value)
            end
          else
            fail a.inspect
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

    def merge key, value
      if ! @attributes.key?(key)
        @attributes[key] = value
      else
        if @attributes[key].class == String
          @attributes[key] = value
        elsif @attributes[key].class == AttributeContainer
          # TODO figure out merge here
          @attributes[key].attributes.keys.each do |k|
            if value.attributes[k]
              @attributes[key].merge(k, value.attributes[k])
            end
          end
        else
          fail @attributes[key].class.inspect
        end
      end
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
