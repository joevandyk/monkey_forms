require 'monkey_forms'

# Your controller would be something like
#
# params[:form] would be a hash like in the tests -- so your forms
# can use fields_for and it all works.
#
# def create
#   @form = BasicFormWithAssociations.new(:form => params[:form])
#   if @form.save
#     # do something
#   else
#     render 'something'
#   end

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
