require 'minitest/autorun'
require 'rack/test'

require 'sinatra/sample_sinatra'
require 'forms/order_form'
require 'forms/order_form_child'
require 'forms/basic_form'

# I want to ensure this library works fine with all of ActiveSupport loaded
require 'active_support/all'

class TestMonkeyForms < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def app
    SampleSinatra.new
  end

  def test_form_post_with_cookie
    post "https://test.domain.com/form", :form => { :name => "Joe" }
    assert_equal "Joe <>", last_response.body
    post "https://test.domain.com/form", :form => { :email => "joe@tanga.com" }
    assert_equal "Joe <joe@tanga.com>", last_response.body
  end

  def test_file_upload
    file = Rack::Test::UploadedFile.new(__FILE__)
    post "https://test.domain.com/upload", :form => { :upload => file }
    assert_equal File.read(__FILE__).size.to_s, last_response.body
  end

  def test_form_post_with_bad_cookie
    post "https://test.domain.com/form", :form => { :name => "Joe" }
    set_cookie "order_cookie=bad_value; path=/; domain=test.domain.com; secure"
    post "https://test.domain.com/form", :form => { :name => "Joe" }
    assert_equal 200, last_response.status
    skip "i can't get this test to fail. :("
  end

  def test_attribute_name
    o = OrderForm.new
    o.valid?
    assert o.errors.full_messages.include?("Your Name can't be blank")
  end

  def test_form_works_without_human_names_set
    o = BasicForm.new
    o.valid?
    assert o.errors.full_messages.include?("Name can't be blank")
  end

  def test_form_cookie
    submit_form :name => "joe"
    # TODO figure out how to get test the cookie stuff properly
    assert last_response.headers["Set-Cookie"].include?("HttpOnly")
    assert last_response.headers["Set-Cookie"].include?("secure")
    assert last_response.headers["Set-Cookie"].include?("test.domain.com")
    assert last_response.headers["Set-Cookie"].include?("path=/;")
  end

  def test_setters_from_inside_form
    a = submit_form :name => 'joe'
    assert_equal 'WA', a[:state]
  end

  def test_child_form
    o = OrderFormChild.new :form => { :child => 'new', :name => 'joe' }
    assert_equal 'new',  o.child
    assert_equal 'joe',  o.name

    assert_equal 'cart', o.class.model_name
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

  def test_html_errors
    o = OrderForm.new
    o.valid?
    assert o.html_error_messages.include?("City can't be blank")
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
    assert o.an_attribute
  end

  def test_set_custom_attributes
    o = OrderForm.new :user_id => 1
    assert_equal 1, o.user_id
  end

  def test_can_access_attributes
    o = OrderForm.new :form => { :email => "joe@tanga.com" , :name => "Joe" }
    assert_equal "Joe <joe@tanga.com>", o.person
  end

  def test_can_access_attributes_stripped
    o = OrderForm.new :form => { :email => "joe@tanga.com" , :name => " Joe " }
    assert_equal "Joe <joe@tanga.com>", o.person
  end

  def test_that_values_in_arrays_are_stripped
    skip "FIX ME!"
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
    post "https://test.domain.com/form", :form => attributes
    post "https://test.domain.com/form", :form => {} # not sure why the cookies don't get set in last_request without this
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
    assert_equal @model.attributes, {"name" => ""}
  end
end
