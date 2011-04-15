module MonkeyForms::ActiveModelName
  # Because ActiveModel::Name is annoying
  def self.build name
    name = name.to_s
    %w( singular human i18n_key partial_path plural ).each do |method|
      name.class_eval do
        define_method method do
          name.underscore
        end
      end
    end
    name
  end
end

