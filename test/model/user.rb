# frozen_string_literal: true

ActiveRecord::Base.connection.create_table(:users, force: true) do |t|
  t.text    :options
  t.text    :json_options
  t.text    :extras
  t.string  :name, unique: true
  t.string  :email
  t.integer :status, default: 0
  t.integer :books_count, default: 0
  t.integer :images_count, default: 0
  t.datetime :deleted_at
  t.timestamps null: false, precision: 6
end

ActiveRecord::Base.connection.create_table(:forked_user_links, force: true) do |t|
  t.integer :forked_to_user_id
  t.integer :forked_from_user_id
  t.timestamps null: false
end

ActiveRecord::Base.connection.create_table(:namespaces, force: true) do |t|
  t.integer :user_id
  t.string  :kind
  t.string  :name
  t.timestamps null: false
end

class User < ApplicationRecord
  CACHE_VERSION = 3
  second_level_cache(version: CACHE_VERSION, expires_in: 3.days)
  acts_as_paranoid

  serialize :options, Array
  serialize :json_options, JSON if ::ActiveRecord::VERSION::STRING >= "4.1.0"
  store :extras, accessors: %i[tagline gender]

  has_one  :account, inverse_of: :user
  has_one  :forked_user_link, foreign_key: "forked_to_user_id"
  has_one  :forked_from_user, through: :forked_user_link
  has_many :namespaces
  has_one  :namespace, -> { where(kind: nil) }
  has_many :books
  has_many :images, as: :imagable

  enum status: %i[active archived]
end

class Namespace < ApplicationRecord
  second_level_cache version: 1, expires_in: 3.days

  belongs_to :user
end

class ForkedUserLink < ApplicationRecord
  second_level_cache version: 1, expires_in: 1.day, unique_indexes: [:forked_to_user_id]

  belongs_to :forked_from_user, class_name: "User"
  belongs_to :forked_to_user, class_name: "User"
end
