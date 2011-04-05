# What's the non-stupid way of ensuring that a file isn't loaded twice,
# even if it's required using different paths?
if ! defined?(OrderForm)

  require 'monkey_forms'

  class OrderForm
    include MonkeyForms::Form

    # Declares a few attributes on the form.
    form_attributes :name, :email, :city, :state

    # This form serializes the submit into a gzip'd cookie with a name
    # of 'order_cookie'.
    set_form_storage MonkeyForms::GzipCookie.new(:name => 'order_cookie')

    # We must submit an email address for the form to validate.
    validates :email, :presence => true

    validation_scope :cart_errors do |scope|
      # Scope some of the validation checks
      scope.validates :name, :presence => true
    end

    validation_scope :address_errors do |scope|
      validates :city,  :presence => true
      validates :state, :presence => true
    end

    # This is a method that uses some form attributes.
    def person
      "#{ name } <#{ email }>"
    end
  end

end
