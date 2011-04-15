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

  def test_boolean
    o = OrderForm.new :form => { :cool => true }
    assert_equal true, o.cool
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

    get "/shipping-address"
    assert_equal "Cocks, Cock City", last_response.body

    get "/billing-address"
    assert_equal "Billing, City", last_response.body
  end

  def test_basic_form
    o = OrderForm.new :form => { :name => "Joe", :email => "joe@tanga.com" }
    assert_equal "Joe", o.name
    assert_equal "joe@tanga.com", o.email
    assert_equal "", o.city
    assert_equal "Joe", o.attributes.name
  end

  class RealBasic
    include MonkeyForms::Form
    form_attributes :name, :email, :age
    form_attributes :gender
    form_attributes :address => [:city, :state, {:phone => [:area, :number]}]
  end

  def test_null
    o = RealBasic.new
    assert_equal "", o.name
    assert_equal "", o.email
    assert_equal "", o.gender
    assert_equal "", o.address.city
    assert_equal "", o.address.state
    assert_equal "", o.address.phone.area
    assert_equal "", o.address.phone.number
  end

  def test_basic
    o = RealBasic.new :form => { "name" => "Joe", "gender" => "male", "age" => "30" }
    assert_equal "Joe",  o.name
    assert_equal "",     o.email
    assert_equal "30",   o.age
    assert_equal "male", o.gender
  end

  def test_basic1
    o = RealBasic.new :form => {
      :address => { "city" => "Seattle",
                    "state" => "WA",
                    "phone" => { "area" => "206", "number" => "8010737" } }
    }

    assert_equal "Seattle", o.address.city
    assert_equal "WA",      o.address.state
    assert_equal "206",     o.address.phone.area
    assert_equal "8010737", o.address.phone.number
  end

  # Updating part of an object, rest should still exist
  def test_basic_partial
    o = RealBasic.new :form => { "address" => { "city" => "Seattle"  } }
    assert_equal "Seattle", o.address.city
    assert_equal "", o.address.state
    assert_equal "", o.address.phone.area
    assert_equal "", o.address.phone.number
  end

  def test_arrays
    o = OrderForm.new :form => {
      "products" => [
        {"quantity"   => "1", "product_id" => "1"},
        {"product_id" => "2"} ]}

    skip
    assert_equal 2, o.products.size
    assert_equal 1, o.products.first.product_id
    assert_equal 2, o.products.last.product_id
  end
end

=begin
  def test_hashes
    shipping_hash = { "address1" => "Cocks",   "city" => "Cock City" }
    billing_hash  = { "address1" => "Billing", "city" => "City" }
    o = OrderForm.new :form => {
      :shipping => { :address => shipping_hash } ,
      :billing  => { :address => billing_hash }
    }

    assert_equal "Billing", o.billing.address.address1
    assert_equal "Cock City", o.shipping.address.city

    # Compatability with rails nested forms
    assert_equal o.billing_attributes, o.billing
    assert_equal o.billing.address_attributes, o.billing.address
    assert o.billing.respond_to?(:address_attributes=)
    assert o.respond_to?("billing_attributes=")
  end

  def test_initialization
    o = OrderForm.new
    refute_nil o.shipping
    refute_nil o.shipping.address
    refute_nil o.shipping.address.city
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

class TestMonkeyFormsLintOnHash < MiniTest::Unit::TestCase
  include ActiveModel::Lint::Tests

  def setup
    @form  = OrderForm.new(:form => { :shipping => { :address => { :city => "Seattle " } } })
    @model = @form.shipping.address
  end

  def test_name
    assert_equal "Address",  @model.class.model_name
    assert_equal "Shipping", @form.shipping.class.model_name
    assert_equal "String",   @form.shipping.address.city.class.to_s
    assert_equal "address",  @model.class.model_name.human
  end
end

class TestMonkeyFormsLintOnArray < MiniTest::Unit::TestCase
  include ActiveModel::Lint::Tests

  def setup
    o = OrderForm.new :form => { :products => [ {:product_id => 1}, {:product_id => 2}]}
    @model = o.products.first
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
=end
