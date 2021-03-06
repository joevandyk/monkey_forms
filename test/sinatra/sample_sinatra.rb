require 'sinatra/base'
require 'forms/order_form'

class SampleSinatra < Sinatra::Base
  #set :show_exceptions, false

  before do
    load_form
  end

  get "/" do
    @page = 1
    haml :form
  end

  get "/2" do
    @page = 2
    haml :form
  end

  get "/3" do
    @page = 3
    haml :form
  end

  post "/upload" do
    @form.upload[:tempfile].read.size.to_s
  end

  post "/haml_form" do
    # We could probably do something with the form object here, maybe
    # Tells the form to serialize itself.
    @form.save_to_storage!
    redirect "/"
  end

  # Only used in unit tests
  post "/form" do
    # Tells the form to serialize itself.
    @form.save_to_storage!

    # Renders something (used in tests)
    @form.person
  end

  private

  def load_form
    @form = OrderForm.new(:form     => request.params["form"],
                          :request  => request,
                          :response => response)
  end
end

