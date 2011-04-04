require 'sinatra/base'

class SampleSinatra < Sinatra::Base
  set :show_exceptions, false

  # Sets a cookie
  # Just for testing stuff.  Will probably be removed later.
  get "/" do
    response.set_cookie("hello", "#{ request.cookies["hello"] }world!")
    "Hello world!"
  end

  post "/form" do
    form = OrderForm.new(:form     => request.params["form"],
                         :storage  => request.cookies["form_storage"],
                         :response => response)
    # TODO save to cookie
    form.save_to_storage!
    form.person
  end

end

