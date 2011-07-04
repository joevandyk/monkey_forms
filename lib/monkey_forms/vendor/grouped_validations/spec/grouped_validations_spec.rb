require 'spec_helper'

describe GroupedValidations do
  let(:person) { Person.new }

  before do
    reset_class Person
  end

  it "should add validation_group class method" do
    Person.should respond_to(:validation_group)
  end

  describe ".validation_group" do
    it "should store defined validation group names" do
      Person.class_eval do
        validation_group(:dummy) { }
      end
      Person.validation_groups.should == [:dummy]
    end

    it "it should add group_valid? method which takes a group name param" do
      Person.class_eval do
        validation_group(:dummy) { }
      end
      
      person.group_valid?(:dummy)
    end

    context "with options" do
      context "as implicit block" do
        it 'should pass options for group to validations' do
          Person.class_eval do
            validation_group(:name, :if => lambda {|r| r.last_name.nil? }) do
              validates_presence_of :first_name
            end
          end

          person.group_valid?(:name)
          person.should have(1).errors

          person.last_name = 'smith'
          person.group_valid?(:name)
          person.should have(0).errors
        end

        it 'should not override explicit validation method options' do
          Person.class_eval do
            validation_group(:name, :if => lambda { true }) do
              validates_presence_of :first_name, :if =>  lambda { false }
            end
          end

          person.group_valid?(:name)
          person.should have(0).errors
        end
      end

      context "as block argument" do
        it 'should pass options for group to validations' do
          Person.class_eval do
            validation_group(:name, :if => lambda {|r| r.last_name.nil? }) do |options|
              options.validates_presence_of :first_name
            end
          end

          person.group_valid?(:name)
          person.should have(1).errors

          person.last_name = 'smith'
          person.group_valid?(:name)
          person.should have(0).errors
        end

        it 'should not override explicit options' do
          Person.class_eval do
            validation_group(:name, :if => lambda {|r| r.last_name.nil? }) do |options|
              options.validates_presence_of :first_name, :if => lambda { false }
            end
          end

          person.group_valid?(:name)
          person.should have(0).errors
        end

        it 'should not apply options to validations methods not using block argument' do
          Person.class_eval do
            validation_group(:name, :if => lambda { false }) do |options|
              options.validates_presence_of :first_name
              validates_presence_of :last_name
            end
          end

          person.group_valid?(:name)
          person.errors[:first_name].should be_empty
          person.errors[:last_name].should_not be_empty
        end
      end
    end
  end

  describe "#group_valid?" do
    it "should run the validations defined inside the validation group" do
      Person.class_eval do
        validation_group :name do
          validates_presence_of :first_name
          validates_presence_of :last_name
        end
      end
      
      person.group_valid?(:name)
      person.should have(2).errors

      person.first_name = 'Dave'
      person.last_name = 'Smith'
      person.group_valid?(:name)
      person.should have(0).errors
    end

    it "should raise exception if valiation group not defined" do
      expect { person.group_valid?(:dummy) }.should raise_exception
    end

    it "should run all validation groups passed to groups_valid?" do
      Person.class_eval do
        validation_group :first_name_group do
          validates_presence_of :first_name
        end
        validation_group :last_name_group do
          validates_presence_of :last_name
        end
      end
      
      person.groups_valid?(:first_name_group, :last_name_group)
      person.should have(2).errors
    end

    context "with validation context" do
      it "should run only validations for explicit context" do
        Person.class_eval do
          validation_group :name do
            validates_presence_of :last_name, :on => :update
          end
        end
        
        person.persisted = false
        person.last_name = nil
        person.group_valid?(:name, :context => :create)
        person.should have(0).errors

        person.persisted = true
        person.group_valid?(:name, :context => :update)
        person.should have(1).errors

        person.last_name = 'Smith'
        person.group_valid?(:name)
        person.should have(0).errors
      end

      it "should run only validations for implicit model context" do
        Person.class_eval do
          validation_group :name do
            validates_presence_of :first_name, :on => :create
          end
        end

        person.persisted = false
        person.group_valid?(:name)
        person.should have(1).errors

        person.first_name = 'Dave'
        person.group_valid?(:name)
        person.should have(0).errors

        person.persisted = true
        person.first_name = nil
        person.group_valid?(:name)
        person.should have(0).errors
      end

    end
  end

  describe "#valid?" do
    it "should run all validation including groups when valid? method called" do
      Person.class_eval do
        validation_group :first_name_group do
          validates_presence_of :first_name
        end
        validation_group :last_name_group do
          validates_presence_of :last_name
        end
        validates_presence_of :sex
      end
      
      person.valid?
      person.should have(3).errors
    end
  end

  describe "#grouped_errors" do
    before do
      Person.class_eval do
        validation_group :first_name_group do
          validates_presence_of :first_name
        end
        validation_group :last_name_group do
          validates_presence_of :last_name
        end
        validates_presence_of :sex
      end
    end

    it 'should return hash of error hashes with validation groups as keys' do
      errors = person.grouped_errors
      errors[:first_name_group].should == {:first_name => ["can't be blank"]}
      errors[:last_name_group].should  == {:last_name  => ["can't be blank"]}
    end

    it 'should return hash of errors for validations outside a validation group, for nil key' do
      errors = person.grouped_errors
      errors[nil][:sex].should == ["can't be blank"]
    end

    it 'should be empty if no errors' do
      person.first_name = 'Dave'
      person.last_name = 'Smith'
      person.sex = 'Male'

      person.grouped_errors.should be_empty
    end

  end

  # Can no longer be done. Unless I find a work around.
  # it "should allow a validation group to appended with subsequent blocks" do
  #   Person.class_eval do
  #     validation_group :name do
  #       validates_presence_of :first_name
  #     end
  #     validation_group :name do
  #       validates_presence_of :last_name
  #     end
  #   end

  #   
  #   person.group_valid?(:name)
  #   puts person.errors.inspect
  #   person.should have(2).errors
  # end

end
