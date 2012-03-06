require 'minitest/autorun'
require 'forms/basic_form'

class TestNewMonkeyForms < MiniTest::Unit::TestCase
  def test_basic
    f = BasicForm.new
    assert !f.valid?

    f.email = "joe@tanga.com"
    assert f.valid?
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
      :line_items => [{:product_id => 1, :quantity => 2}],
      :shipping_address => { :name => 'Joe', :city => "Seattle"}
    )
    assert_equal 2, f.line_items.first.quantity
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
    f = BasicFormSaving.new(:name => 'joe', :email => 'joe@tanga.com').tap(&:save)
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
