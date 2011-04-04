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
    OrderForm.new(:form => request.params["form"])
    # TODO save to cookie
    # save_form(form)
    form.person
  end

  def load_form
  end

  def save_form(form)
    # TODO write me
  end
end

