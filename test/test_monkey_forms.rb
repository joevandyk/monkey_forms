require 'rubygems'
require 'minitest/autorun'
require 'monkey_forms'

class TestMonkeyForms < MiniTest::Unit::TestCase
  class OrderForm
    include MonkeyForms::Form
    form_attributes :name, :email

    validates :email, :presence => true

    validation_scope :cart_errors do |scope|
      scope.validates :name, :presence => true
    end
  end

  def test_basic
    o = OrderForm.new :name => "Joe", :email => "joe@tanga.com"
    assert_equal "Joe", o.name
    assert_equal "joe@tanga.com", o.email
  end

  def test_validation
    o = OrderForm.new :name => "Joe"
    o.valid?
    assert_equal ["can't be blank"], o.errors[:email]
  end

  def test_validation_scope
    o = OrderForm.new
    # validations get ran on no_cart_errors call
    assert_equal [], o.cart_errors[:name]

    refute o.no_cart_errors?
    assert_equal ["can't be blank"], o.cart_errors[:name]

    # Email is fine, valid? wasn't called
    assert_equal [], o.errors[:email]
  end
end
