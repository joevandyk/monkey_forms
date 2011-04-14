# What's the non-stupid way of ensuring that a file isn't loaded twice,
# even if it's required using different paths?
if ! defined?(OrderForm)

  require 'monkey_forms'

  class OrderForm
    include MonkeyForms::Form
    attr_reader :poop

    # Declares a few attributes on the form.
    form_attributes :name, :email, :city, :state
    form_attributes :shipping => { :address => [:address1, :address2, :city, :state, :zip, :phone] }
    form_attributes :billing  => { :address => [:address1, :address2, :city, :state, :zip, :phone] }

    custom_attributes :user_id
    form_name :cart

    # This form serializes the submit into a gzip'd cookie with a name
    # of 'order_cookie'.
    set_form_storage MonkeyForms::Serializers::GzipCookie.new(:name => 'order_cookie')

    after_initialize :do_poop

    # We must submit an email address for the form to validate.
    validates :email, :presence => true

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

    def shipping_address
      "#{ shipping[:address][:address1] }, #{ shipping[:address][:city] }"
    end

    def billing_address
      "#{ attributes[:billing][:address][:address1] }, #{ attributes[:billing][:address][:city] }"
    end

    private

    def do_poop
      @poop = true
    end
  end

end
