# frozen_string_literal: true

require "test_helper"

# TODO: subscribed cache
class MixinTest < ActiveSupport::TestCase
  def setup
    @old_second_level_cache_options = User.second_level_cache_options
    User.second_level_cache(@old_second_level_cache_options.merge(unique_indexes: ["id", "email", ["name", "status"]]))
    @user = User.create(name: "foobar", email: "foobar@test.com")
  end

  def teardown
    User.second_level_cache(@old_second_level_cache_options)
  end

  def test_second_level_cache_unique_indexes
    assert_equal User.second_level_cache_unique_indexes(id: 1), { "id" => 1 }
    assert_equal User.second_level_cache_unique_indexes(id: 1, email: "foobar@test.com"), { "id" => 1 }
    assert_equal User.second_level_cache_unique_indexes(name: "foobar", email: "foobar@test.com"), { "email" => "foobar@test.com" }
    assert_equal User.second_level_cache_unique_indexes(name: "foobar", status: :active), { "name" => "foobar", "status" => :active }
  end

  def test_second_level_cache_key
    table_digest = Digest::SHA1.hexdigest(User.base_class.inspect).first(7)
    assert_equal @user.second_level_cache_key(:id), "slc/users/id=#{@user.id}/#{User::CACHE_VERSION}/#{table_digest}"
    assert_equal @user.second_level_cache_key(:email, :name), "slc/users/email=#{@user.email}&name=#{@user.name}/#{User::CACHE_VERSION}/#{table_digest}"
    assert_equal @user.second_level_cache_key(:name, :email), "slc/users/email=#{@user.email}&name=#{@user.name}/#{User::CACHE_VERSION}/#{table_digest}"
  end

  def test_read_second_level_cache
    assert_equal User.read_second_level_cache(id: @user.id), @user
    assert_equal User.read_second_level_cache(email: @user.email), @user
    assert_nil User.read_second_level_cache(email: @user.email, name: @user.name)
  end

  def test_expire_second_level_cache
    User.expire_second_level_cache(email: @user.email)
    assert_nil User.read_second_level_cache(id: @user.id)
    assert_nil User.read_second_level_cache(email: @user.email)
    assert_nil User.read_second_level_cache(name: @user.name, status: @user.status)
  end

  def test_write_second_level_cache
    @user.expire_second_level_cache
    @user.write_second_level_cache
    assert_equal User.read_second_level_cache(id: @user.id), @user
    assert_equal User.read_second_level_cache(email: @user.email), @user
    assert_equal User.read_second_level_cache(name: @user.name, status: @user.status), @user
  end

  def test_update_second_level_cache
    old_email = @user.email
    old_name = @user.name
    @user.update_columns(email: "changed@test.com", name: "changed")
    assert_nil User.read_second_level_cache(email: old_email)
    assert_nil User.read_second_level_cache(name: old_name, status: @user.status)
    assert_equal User.read_second_level_cache(email: @user.email), @user
    assert_equal User.read_second_level_cache(name: @user.name, status: @user.status), @user
  end
end
