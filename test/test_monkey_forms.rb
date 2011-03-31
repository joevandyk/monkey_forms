require 'rubygems'
require 'minitest/autorun'
require 'monkey_forms'

class OrderForm
  include MonkeyForms::Form
  form_attributes :name, :email
  form_storage :cookie, :name => 'order_cookie'

  validates :email, :presence => true

  validation_scope :cart_errors do |scope|
    scope.validates :name, :presence => true
  end
end

class TestMonkeyForms < MiniTest::Unit::TestCase
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

  def test_unknown_storage_type

  end

  def test_basic_cookie
    # Some Rails cookie thingy w/ email set
    # TODO figure out how to properly test this with ActionPack's cookies
    cookie = create_cookie :email => "joe@tanga.com"
    o = OrderForm.new :name => "Joe", :order_cookie => cookie

    assert_equal "Joe", o.name
    assert_equal "joe@tanga.com", o.email
  end

  def test_form_overrides_cookie
    cookie = create_cookie :email => "joe@tanga.com"
    o = OrderForm.new :email => "joe@domain.com", :order_cookie => cookie

    assert_equal "joe@domain.com", cookie[:email]
    assert_equal "joe@domain.com", o.email
  end

  # TODO this should create an actual cookie
  def create_cookie options
    {}.merge!(options)
  end
end

