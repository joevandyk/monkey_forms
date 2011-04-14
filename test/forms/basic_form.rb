if ! defined?(BasicForm)
  require 'monkey_forms'
  class BasicForm
    include MonkeyForms::Form
  end
end

