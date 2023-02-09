class UserSerializer < ActiveModel::Serializer
  attributes :id, :email, :name, :authentication_token
  #
  # def authentication_token
  #   puts "entering authentication_token #{resource.authentication_token}"
  #   object&.authentication_token
  # end
end
