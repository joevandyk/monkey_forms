# Saves form as cookie as json+gzip
class MonkeyForms::Serializers::ActiveRecordSesssion
  def initialize options={}
    @cookie_name = options[:name]
  end

  def load options={}
  end

  def save options = {}
  end
end
