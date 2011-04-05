require 'rubygems'
require 'minitest/autorun'
require 'rack/test'

require 'test/sinatra/sample_sinatra'
require 'test/order_form'

class TestMonkeyForms < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def app
    SampleSinatra.new
  end

  def test_form_post_with_cookie
    post "/form", :form => { :name => "Joe" }
    assert_equal "Joe <>", last_response.body
    post "/form", :form => { :email => "joe@tanga.com" }
    assert_equal "Joe <joe@tanga.com>", last_response.body
  end

  def test_basic
    o = OrderForm.new :form => { :name => "Joe", :email => "joe@tanga.com" }
    assert_equal "Joe", o.name
    assert_equal "joe@tanga.com", o.email
    assert_equal "", o.city
    assert_equal 4, o.attributes.size
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

  def test_can_access_attributes
    o = OrderForm.new :form => { :email => "joe@tanga.com" , :name => "Joe" }
    assert_equal "Joe <joe@tanga.com>", o.person
  end
end
