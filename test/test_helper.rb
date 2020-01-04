$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'dry-types'
require 'dry-struct'
require 'rom/core'
require 'oj'

require 'hanami/serializer'

require 'minitest/spec'
require 'minitest/autorun'

module Types
  include Dry.Types()
end

class User < ROM::Struct
  attribute :id,         Types::Integer
  attribute :name,       Types::String
  attribute :email,      Types::String
  attribute? :has_pet,         Types::Bool
  attribute :created_at, Types::Time
end

class AnonymizableUserSerializer < Hanami::Serializer::Base
  attribute :name, Types::String.default { nil }
end

class UserSerializer < Hanami::Serializer::Base
  attribute :name,  Types::String.default { ''.freeze }
  attribute :email, Types::String
  attribute? :subscribed, Types::Bool.default { false }
end

class UserWithAvatarSerializer < Hanami::Serializer::Base
  attribute :name, Types::String

  attribute :avatar, Types::Hash.schema(
    upload_file_name?: Types::String,
    upload_file_size?: Types::Coercible::Integer
  ).default { {}.freeze }
end

class UserWithSelectedFieldsSerializer < Hanami::Serializer::Base
  attribute :id,         Types::Integer
  attribute :name,       Types::String
  attribute :email,      Types::String
  attribute :created_at, Types::Time

  serialized_fields [:name]
end

class AvatarSerializer < Hanami::Serializer::Base
  attribute :upload_file_name, Types::String
  attribute :upload_file_size, Types::Coercible::Integer
end

class NestedUserSerializer < Hanami::Serializer::Base
  attribute :name, Types::String
  attribute? :avatar,    AvatarSerializer.default { {}.freeze }
end
