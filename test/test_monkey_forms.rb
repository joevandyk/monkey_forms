require 'rubygems'
require 'minitest/autorun'
require 'minitest/pride'
require 'rack/test'

require 'test/sinatra/sample_sinatra'
require 'test/forms/order_form'
require 'test/forms/basic_form'

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

  def test_form_post_with_hash_and_cookie
    shipping_hash = { "address1" => "Cocks",   "city" => "Cock City" }
    billing_hash  = { "address1" => "Billing", "city" => "City" }
    post "/form", :form => {
      :shipping => { :address => shipping_hash },
      :billing  => { :address => billing_hash }
    }

    get "/billing-address"
    assert_equal "Billing, City", last_response.body

    get "/shipping-address"
    assert_equal "Cocks, Cock City", last_response.body
  end

  def test_basic
    o = OrderForm.new :form => { :name => "Joe", :email => "joe@tanga.com" }
    assert_equal "Joe", o.name
    assert_equal "joe@tanga.com", o.email
    assert_equal "", o.city
    assert_equal 6, o.attributes.size
    assert_equal "Joe", o.attributes[:name]
    assert_equal "Joe", o.attributes["name"]
  end

  def test_arrays
    shipping_hash = { "address1" => "Cocks",   "city" => "Cock City" }
    billing_hash  = { "address1" => "Billing", "city" => "City" }
    o = OrderForm.new :form => {
      :shipping => { :address => shipping_hash } ,
      :billing  => { :address => billing_hash }
    }

    assert_equal o.billing[:address][:address1], "Billing"
    assert_equal o.shipping.address.city,        "Cock City"
  end

  def test_validation
    o = OrderForm.new :form => { :name => "Joe" }
    o.valid?
    assert_equal ["can't be blank"], o.errors[:email]
  end

  def test_validation_before_valid_called
    o = OrderForm.new
    assert_equal [], o.errors[:name]
    assert_equal [], o.errors[:email]
  end

  def test_validation_scope_after_valid_called
    o = OrderForm.new
    refute o.valid?
    assert ["can't be blank"], o.errors[:name]
    assert ["can't be blank"], o.errors[:email]
  end

  def test_group_validation
    o = OrderForm.new
    refute o.group_valid?(:cart)
    assert_equal ["can't be blank"], o.errors[:name]
    assert_equal [], o.errors[:email]

    o.valid?
    assert_equal ["can't be blank"],  o.errors[:email]
  end

  def test_after_initialize
    o = OrderForm.new
    assert o.poop
  end

  def test_set_custom_attributes
    o = OrderForm.new :user_id => 1
    assert_equal 1, o.user_id
  end

  def test_can_access_attributes
    o = OrderForm.new :form => { :email => "joe@tanga.com" , :name => "Joe" }
    assert_equal "Joe <joe@tanga.com>", o.person
  end
end

class TestMonkeyFormsActiveModelLint < MiniTest::Unit::TestCase
  include ActiveModel::Lint::Tests

  def setup
    @model = OrderForm.new
  end

  def test_form_name
    assert_equal "cart", @model.class.model_name
  end
end

class TestMonkeyFormsLintOnArray < MiniTest::Unit::TestCase
  include ActiveModel::Lint::Tests

  def setup
    form = OrderForm.new(:form => { :shipping => { :address => { :city => "Seattle " } } })
    @model = form.shipping.address
  end
end

class TestMonkeyFormsBasic < MiniTest::Unit::TestCase
  include ActiveModel::Lint::Tests

  def setup
    @model = BasicForm.new
  end

  def test_form_name
    assert_equal "basic_form", @model.class.model_name
  end

  def test_attributes
    assert_equal @model.attributes, {}
  end
end
