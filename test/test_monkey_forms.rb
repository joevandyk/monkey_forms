require 'rubygems'
require 'minitest/autorun'
require 'minitest/pride'
require 'rack/test'

require 'test/sinatra/sample_sinatra'
require 'test/forms/order_form'
require 'test/forms/basic_form'

# I want to ensure this library works fine with all of ActiveSupport loaded
# require 'active_support/all'

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
    assert_equal 5, o.attributes.size
    assert_equal "Joe", o.attributes[:name]
    assert_equal "Joe", o.attributes["name"]
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

  def test_array
    submit_form(:line_items => [ {:id => "previous"}])
    attributes = submit_form(:line_items => [ {:id => "new"}])

    assert_equal 2, attributes[:line_items].size
    assert_equal "previous", attributes[:line_items].first[:id]
    assert_equal "new",      attributes[:line_items].last[:id]
  end

  def test_array_update
    submit_form(:line_items => [ {:id => "first", :quantity => 1}])
    attributes = submit_form(:line_items => [ {:id => "first", :quantity => 3}])
    assert_equal "3", attributes[:line_items].last[:quantity]
  end

  def test_submit_blank
    a = submit_form(:name => "Joe", :city => "Seattle")
    assert_equal "Joe", a[:name]

    a = submit_form(:name => "", :city => "Seattle")
    assert_equal "", a[:name]
  end


  def extract_attributes request
    serializer = MonkeyForms::Serializers::GzipCookie.new(:name => "order_cookie")
    serializer.load(:request => request)
  end

  def submit_form attributes
    post "/form", :form => attributes
    post "/form", :form => {} # not sure why the cookies don't get set in last_request without this
    extract_attributes last_request
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
