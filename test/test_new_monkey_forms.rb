require 'monkey_forms'
require 'minitest/autorun'

class Address
  include MonkeyForms::Form
  form_attribute :name, String
  form_attribute :city, String
  validates :name, :city, :presence => true
end

class LineItem
  include MonkeyForms::Form
  form_attribute :product_id, Integer
  form_attribute :quantity, Integer
end

class BasicForm
  include MonkeyForms::Form
  form_name :cart

  form_attribute :email, String
  form_attribute :age, Integer
  validates :email, :presence => true
end

class BasicFormWithAssociations < BasicForm
  form_attribute :line_items, Array[LineItem]
  form_attribute :shipping_address, Address
  form_attribute :billing_address, Address
  form_attribute :age, Integer, :default => 18
  validates_associated :shipping_address
end

class BasicFormSaving < BasicForm
  attr_accessor :i_got_saved
  after_save :save_success

  private
  def save_success
    @i_got_saved = true
  end
end

class TestNewMonkeyForms < MiniTest::Unit::TestCase
  def test_basic
    f = BasicForm.new
    assert !f.valid?

    f.email = "joe@tanga.com"
    assert f.valid?
  end

  # In general, you want form inputs to have the extra whitespace
  # at the start and end stripped out.
  def test_strips_form_inputs
    f = BasicForm.new(:form => { :age => " 3 \r\n", :email => ' joe@tanga.com '})
    assert_equal 3, f.age
    assert_equal 'joe@tanga.com', f.email
  end

  # For stuff not provided through a form, we don't strip any of the values.
  def test_doesnt_strips_non_form_inputs
    f = BasicForm.new(:age => " 3 \r\n", :email => ' joe@tanga.com ')
    assert_equal " 3 \r\n", f.age
    assert_equal ' joe@tanga.com ', f.email
  end

  def test_conversion
    f = BasicForm.new(:age => '3')
    assert_equal 3, f.age
  end

  def test_init_with_form_hash
    f = BasicForm.new(:form => { :age => '3' })
    assert_equal 3, f.age
  end

  def test_children_empty
    f = BasicFormWithAssociations.new
    assert_equal [], f.line_items
    assert_equal "", f.shipping_address.name
  end

  def test_children
    f = BasicFormWithAssociations.new(
      :age => '3',
      :line_items => [{:product_id => "1", :quantity => "2"}],
      :shipping_address => { :name => 'Joe', :city => "Seattle"}
    )
    assert_equal 2, f.line_items.first.quantity
    assert_equal 1, f.line_items.first.product_id
    assert_equal "Seattle", f.shipping_address.city
  end

  def test_children_validations
    f = BasicFormWithAssociations.new(:email => 'joe@tanga.com')
    refute f.valid?
    refute f.shipping_address.valid?
    assert_equal [:name, :city], f.errors.keys
    assert_equal [:name, :city], f.shipping_address.errors.keys

    f.shipping_address.name = "Joe"
    refute f.valid?
    refute f.shipping_address.valid?
    assert_equal [:city], f.shipping_address.errors.keys

    f.shipping_address.city = "Seattle"
    assert f.valid?
    assert f.shipping_address.valid?
  end

  def test_default
    assert_equal 18, BasicFormWithAssociations.new.age
    assert_equal "", BasicForm.new.age
  end

  def test_saving_failure
    f = BasicFormSaving.new
    assert_equal false, f.save
    refute f.i_got_saved
  end

  def test_saving_success
    f = BasicFormSaving.new(:name => 'joe', :email => 'joe@tanga.com')
    f.save
    assert_equal true, f.i_got_saved
  end
end

class TestMonkeyFormsActiveModelLint < MiniTest::Unit::TestCase
  include ActiveModel::Lint::Tests

  def setup
    @model = BasicFormWithAssociations.new
  end

  def test_form_name
    assert_equal "cart", @model.class.model_name
  end
end
