require 'monkey_forms'

class OrderForm
  include MonkeyForms::Form
  form_attributes :name, :email
  form_storage    :cookie, :name => 'order_cookie'
  # TODO add other tests for other form_storages options.

  validates :email, :presence => true

  validation_scope :cart_errors do |scope|
    scope.validates :name, :presence => true
  end

  # This is a method that uses the form attributes.
  def person
    "#{ attributes[:name] } <#{ attributes[:email] }>"
  end
end

