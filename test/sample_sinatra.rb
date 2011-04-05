require 'sinatra/base'

class SampleSinatra < Sinatra::Base
  set :show_exceptions, false

  post "/form" do
    # Creates the form
    form = OrderForm.new(:form     => request.params["form"],
                         :request  => request,
                         :response => response)

    # We could probably do something with the form object here, maybe
    if form.valid?
       # something
    end

    if form.no_cart_errors?
      # something else
    end

    # Tells the form to serialize itself.
    form.save_to_storage!

    # Returns something.
    form.person # This returns "name <email>"
  end

end

