require 'rubygems'
require 'minitest/autorun'
require 'monkey_forms'
require 'rack/test'
require 'sinatra/base'

ENV['RACK_ENV'] = 'test'


=begin
 # Sample Controller class that uses this.
 # TODO add a test for this.
 class OrdersController < ActionController::Base
   before_filter :load_form
   after_filter  :save_form

   def cart
   end

   def shipping
   end

   private

   def load_form
     @form = OrderForm.new(:form    => params[:form],
                           :storage => cookies['order_cookie'])
   end

   def save_form
     @form.save_to_storage!
   end
 end
=end

class TestApp < Sinatra::Base
  set :show_exceptions, false

  # Sets a cookie
  # Just for testing stuff.  Will probably be removed later.
  get "/" do
    response.set_cookie("hello", "#{ request.cookies["hello"] }world!")
    "Hello world!"
  end

  post "/form" do
    form = load_form
    save_form(form)
    form.person
  end

  def load_form
    OrderForm.new(:form => request.params["form"])
  end

  def save_form(form)
    # TODO write me
  end
end

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

class TestMonkeyForms < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def app
    TestApp.new
  end

  # Sanity test, make sure all this rack cookie nonsense works properly.
  def test_sample_get_with_cookie
    get "/"
    assert_equal "world!", rack_mock_session.cookie_jar["hello"]

    get "/"
    assert_equal "world!" * 2, rack_mock_session.cookie_jar["hello"]

    get "/"
    assert_equal "world!" * 3, rack_mock_session.cookie_jar["hello"]
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

