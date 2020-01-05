# !/usr/bin/env ruby
# frozen_string_literal: true

require 'benchmark/ips'
require_relative '../lib/hanami/serializer'
require 'rom/core'
require 'oj'
require 'active_model'
require 'fast_jsonapi'

module Types
  include Dry.Types()
end

num_users = 100

class UserStruct < ROM::Struct
  attribute :id, Types::Integer
  attribute :name, Types::String
  attribute :email, Types::String
  attribute? :has_pet, Types::Bool
  attribute :created_at, Types::Time
  attribute :avatar, Types::Hash.schema(
    upload_file_name?: Types::String,
    upload_file_size?: Types::Coercible::Integer
  ).default { {}.freeze }
  attribute :articles, Types::Array.of(Types::Hash.schema(
    title: Types::String,
    posted_at: Types::Time
  ))
end
class AvatarHanamiSerializer < Hanami::Serializer::Base
  attribute :upload_file_name, Types::String
  attribute :upload_file_size, Types::Coercible::Integer
end
class ArticleHanamiSerializer < Hanami::Serializer::Base
  attribute :title, Types::String
  attribute :posted_at, Types::Time
end
class UserHanamiSerializer < Hanami::Serializer::Base
  attribute :name, Types::String
  attribute :email, Types::String
  attribute? :avatar, AvatarHanamiSerializer.default { {}.freeze }
  attribute :articles, Types::Array.of(ArticleHanamiSerializer)
end
class UsersHanamiSerializer < Hanami::Serializer::Base
  attribute :users, Types::Array.of(UserHanamiSerializer)
end
struct_users = {
  users: Array.new(num_users) { |user_id|
    UserStruct.new(
      id: user_id,
      name: 'John Doe',
      email: 'jd@example.com',
      created_at: Time.now,
      avatar: {
        id: 1,
        upload_file_name: 'test.jpg',
        upload_file_size: 10,
        upload_updated_at: Time.now
      },
      articles: [
        {
          title: '10 Ruby performance tips',
          posted_at: Time.now
        },
        {
          title: 'Ruby 2.7 pattern matching examples',
          posted_at: Time.now
        }
      ]
    )
  }
}

class ActiveModelBase
  include ::ActiveModel::Model
  include ::ActiveModel::Attributes
  include ::ActiveModel::Serializers::JSON
end
class UserActiveModel < ActiveModelBase
  attribute :id, :integer
  attribute :name, :string
  attribute :email, :string
  attribute :created_at, :time
  attribute :avatar
  attribute :articles
end
class AvatarActiveModel < ActiveModelBase
  attribute :upload_file_name, :string
  attribute :upload_file_size, :integer
end
class ArticleActiveModel < ActiveModelBase
  attribute :title, :string
  attribute :posted_at, :time
end
active_model_users = {
  users: Array.new(num_users) { |user_id|
    UserActiveModel.new(
      id: user_id,
      name: 'John Doe',
      email: 'jd@example.com',
      created_at: Time.now,
      avatar: AvatarActiveModel.new(
        upload_file_name: 'test.jpg',
        upload_file_size: 10
      ),
      articles: [
        ArticleActiveModel.new(
          title: '10 Ruby performance tips',
          posted_at: Time.now
        ),
        ArticleActiveModel.new(
          title: 'Ruby 2.7 pattern matching examples',
          posted_at: Time.now
        )
      ]
    )
  }
}

class User
  attr_accessor :id, :name, :email, :created_at, :avatar, :articles, :avatar_id, :article_ids
  def initialize(id:, name:, email:, created_at:, avatar:, articles:)
    @id, @name, @email, @created_at, @avatar, @articles = id, name, email, created_at, avatar, articles
    @avatar_id = avatar.id
    @article_ids = articles.map(&:id)
  end
end
class Avatar
  attr_accessor :id, :upload_file_name, :upload_file_size, :upload_updated_at
  def initialize(id:, upload_file_name:, upload_file_size:, upload_updated_at:)
    @id, @upload_file_name, @upload_file_size, @upload_updated_at = id, upload_file_name, upload_file_size, upload_updated_at
  end
end
class Article
  attr_accessor :id, :title, :posted_at
  def initialize(id:, title:, posted_at:)
    @id, @title, @posted_at = id, title, posted_at
  end
end
class UserSerializer
  include FastJsonapi::ObjectSerializer
  attributes :id, :name, :email, :created_at, :avatar
  has_one :avatar
  has_many :articles
end
class AvatarSerializer
  include FastJsonapi::ObjectSerializer
  attributes :id, :upload_file_name, :upload_file_size
end
class ArticleSerializer
  include FastJsonapi::ObjectSerializer
  attributes :id, :title, :posted_at
end
obj_users = Array.new(num_users) { |user_id|
  User.new(
    id: user_id,
    name: 'John Doe',
    email: 'jd@example.com',
    created_at: Time.now,
    avatar: Avatar.new(id: 1, upload_file_name: 'test.jpg', upload_file_size: 10, upload_updated_at: Time.now),
    articles: (1..3).map { |i|
      Article.new(id: i, title: "title#{i}", posted_at: Time.now)
    }
  )
}

hash_users = {
  users: Array.new(num_users) { |user_id|
    {
      id: user_id,
      name: 'John Doe',
      email: 'jd@example.com',
      created_at: Time.now,
      avatar: {
        upload_file_name: 'test.jpg',
        upload_file_size: 10,
        upload_updated_at: Time.now
      },
      articles: [
        {
          title: '10 Ruby performance tips',
          posted_at: Time.now
        },
        {
          title: 'Ruby 2.7 pattern matching examples',
          posted_at: Time.now
        }
      ]
    }
  }
}

Benchmark.ips do |x|
  x.config(warmup: 2, time: 10)
  x.config(stats: :bootstrap, confidence: 95)

  x.report('Hanami::Serializer') do
    UsersHanamiSerializer.new(struct_users).to_json
  end

  x.report('Hanami::Serializer(oj)') do
    Hanami::Serializer.config.json_engine = :oj
    UsersHanamiSerializer.new(struct_users).to_json
  end

  x.report('ActiveModel::Serializers') do
    active_model_users.to_json
  end

  x.report('FastJsonapi') do
    UserSerializer.new(obj_users, include: [:avatar, :articles]).serialized_json
  end

  x.report('Hash#to_json') do
    hash_users.to_json
  end

  x.compare!
end

__END__

Benchmark results

  Hanami::Serializer      127.028  (± 5.7%) i/s -      1.206k in  10.166371s
Hanami::Serializer(oj)    161.131  (± 1.0%) i/s -      1.608k in  10.015838s
ActiveModel::Serializers  126.964  (± 2.5%) i/s -      1.224k in  10.027166s
         FastJsonapi       75.282  (± 2.6%) i/s -        732  in  10.013214s
        Hash#to_json      107.377  (± 5.2%) i/s -      1.035k in  10.126912s
                   with 95.0% confidence

Comparison:
Hanami::Serializer(oj):        161.1 i/s
  Hanami::Serializer:          127.0 i/s - 1.27x  (± 0.07) slower
ActiveModel::Serializers:      127.0 i/s - 1.27x  (± 0.03) slower
        Hash#to_json:          107.4 i/s - 1.50x  (± 0.08) slower
         FastJsonapi:           75.3 i/s - 2.14x  (± 0.06) slower
                   with 95.0% confidence
