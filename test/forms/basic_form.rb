require 'monkey_forms'

class BasicForm
  include MonkeyForms::Form
  form_attributes :name
  validates :name, :presence => true
end

