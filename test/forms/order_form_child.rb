if ! defined?(OrderFormChild)
  require 'monkey_forms'
  class OrderFormChild < OrderForm
    form_attributes :child
  end
end
