# What's the non-stupid way of ensuring that a file isn't loaded twice,
# even if it's required using different paths?
if ! defined?(OrderForm)

  require 'monkey_forms'

  class OrderForm
    include MonkeyForms::Form
    attr_reader :an_attribute

    # Declares a few attributes on the form.
    form_attributes :name, :email, :city, :state, :line_items
    custom_attributes :user_id
    form_name :cart

    # This form serializes the submit into a gzip'd cookie with a name
    # of 'order_cookie'.
    set_form_storage(
      MonkeyForms::Serializers::GzipCookie.new(
        :name => 'order_cookie',
        :domain => 'test.domain.com',
        :secure => true,
        :httponly => true))

    after_initialize :set_attribute, :set_default_state

    # We must submit an email address for the form to validate.
    validates :email, :presence => true

    set_form_attribute_human_names :name => "Your Name"

    validation_group :cart do
      # Scope some of the validation checks
      validates :name, :presence => true
    end

    validation_group :address do
      validates :city,  :presence => true
      validates :state, :presence => true
    end

    # This is a method that uses some form attributes.
    def person
      "#{ name } <#{ email }>"
    end

    private

    def set_attribute
      @an_attribute = true
    end

    def set_default_state
      if state.blank?
        self.state = "WA"
      end
    end
  end

end
