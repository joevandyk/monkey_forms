require 'rubygems'
require 'minitest/autorun'
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

=begin
 # Sample Controller class that uses this.
 # TODO add a test for this.
 class OrdersController < ActionController::Base
   before_filter :load_form

   def cart
   end

   def shipping
   end

   private

   def load_form
     @form = OrderForm.new(:form    => params[:form],
                           :storage => cookies['order_cookie'])
   end
 end
=end

class TestMonkeyForms < MiniTest::Unit::TestCase
  def test_basic
    o = OrderForm.new :form => { :name => "Joe", :email => "joe@tanga.com" }
    assert_equal "Joe", o.name
    assert_equal "joe@tanga.com", o.email
  end

  def test_validation
    o = OrderForm.new :form => { :name => "Joe" }
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

  def test_basic_cookie
    # Some Rails cookie thingy w/ email set
    # TODO figure out how to properly test this with ActionPack's cookies
    cookie = create_cookie :email => "joe@tanga.com"
    o = OrderForm.new :form => { :name => "Joe" }, :storage => cookie

    assert_equal "Joe", o.name
    assert_equal "joe@tanga.com", o.email
  end

  def test_form_overrides_cookie
    cookie = create_cookie :email => "joe@tanga.com"
    o = OrderForm.new :form => { :email => "joe@domain.com" }, :storage => cookie

    assert_equal "joe@domain.com", cookie[:email]
    assert_equal "joe@domain.com", o.email
  end

  # TODO this should create an actual cookie
  def create_cookie options
    {}.merge!(options)
  end

  def test_can_access_attributes
    o = OrderForm.new :form => { :email => "joe@tanga.com" , :name => "Joe" }
    assert_equal "Joe <joe@tanga.com>", o.person
  end
end

