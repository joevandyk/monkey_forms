NOTE!  If you use the cookie serialization feature, you 
need to use this version of deep_merge for now.
https://github.com/joevandyk/deep_merge


MonkeyForms::Form is an ActiveModel-compliant interface
between your controllers and models (or whatever you are 
saving the data to).

MonkeyForms supports multi-page wizards and validation groups.

    class OrderForm
      include MonkeyForms::Form
      form_name 'cart'
      form_attributes :name, :address, :city, :state, :zip 
      
      validates :name, :presence => true

      # Save the data however you want.
      def save
        address = Address.new(:street => address, :city => city, :state => state, :zip => zip)
        OrderService.place_order(:the_name => name, :address => address)
      end
    end


    In your controller:
      def new
        @cart = OrderForm.new
      end
      def create
        @cart = OrderForm.new(:form => params[:cart])
        if @cart.valid?
          @cart.save
          redirect_to "/thanks"
        else
          render :action => 'new'
        end
      end
    end

    In your view:
      = form_for @cart do |f|
        = f.text_field :name
        = f.text_field :address
        = f.text_field :city
        = # etc
        = f.submit


A more complex multi-page order process.
State is remembered in a cookie; the form params are merged into the cookie's state on each request.

    class OrderForm
      include MonkeyForms::Form

      # Declares a few attributes on the form.
      form_attributes :name, :email, :city, :state, :line_items
      custom_attributes :user_id
      form_name :cart

      # This form serializes the submit into a gzip'd cookie with a name
      # of 'order_cookie'.
      set_form_storage(
        MonkeyForms::Serializers::GzipCookie.new(
          :name => 'order_cookie',
          :domain => 'test.domain.com',
          :secure => true,
          :httponly => true))

      after_initialize :set_default_state

      # We must submit an email address for the form to validate.
      validates :email, :presence => true

      validation_group :cart do
        # Scope some of the validation checks
        validates :name, :presence => true
      end

      validation_group :address do
        validates :city,  :presence => true
        validates :state, :presence => true
      end

      # This is a method that uses some form attributes.
      def person
        "#{ name } <#{ email }>"
      end

      private

      def set_default_state
        if state.blank?
          self.state = "WA"
        end
      end
    end


    class Controller
      before_filter :load_cart
      # Name / Email
      def page1
        if request.post?
          if group.valid?(:name)
            redirect_to "/page2"
          end
        end
      end

      # Address
      def page2
        if request.post?
          if group.valid?(:address)
            # whatever..
          end
        end
      end

      private

      def load_cart
        @cart = OrderForm::Form.new(:form => params[:cart]
      end
    end


The validation_group code is modified from 
https://github.com/adzap/grouped_validations


This is pretty similar to the Presenter Pattern as described
by Jay Fields, by the way. http://blog.jayfields.com/2007/03/rails-presenter-pattern.html



There is a sample sinatra application in test/sinatra.  Run with:
cd test/sinatra
rackup config.ru



??? WHY ???

Moving the form logic to a separate class has a ton of advantages:

* Keeps the controller really simple.  
* Makes it easier to test. You can write tests directly against the form handling class.
* Classes should do one thing.
* You can have complex validations.
* Your ActiveRecord models can probably become simpler.
* Since the form handling logic is encapsulated into one class, you can use inheritance, modules, etc.
* You want to move away from ActiveRecord? It's no problem -- just change how the form values are saved in the #save method.
