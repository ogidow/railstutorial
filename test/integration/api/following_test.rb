require 'test_helper'

class Api::FollowingTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:michael)
    @other = users(:archer)
    token = @user.generate_jwt
    @headers = {"Authorization" => "Bearer #{token}"}
  end

  test "フォローできること" do
    assert_difference '@user.following.count', 1 do
      post api_relationships_path, {relationship: {followed_id: @other.id}}, @headers
    end
    assert_response :created
  end

  test "フォローする人を正しく指定しなければエラーを返すこと" do
    assert_no_difference "@user.following.count" do
      post api_relationships_path, {relationship: {followed_id: ""}}, @headers
    end
    assert_response :unprocessable_entity
  end

  test "既にフォロー済みの人をフォローしようとしたときはエラーを返すこと" do
    @user.follow(@other)
    assert_no_difference "@user.following.count" do
      post api_relationships_path, {relationship: {followed_id: @other.id}}, @headers
    end
    assert_response :unprocessable_entity

    assert_equal response_json[:errors][:followed_id], ["has already been taken"]
  end

  test "アンフォローできること" do
    @user.follow(@other)
    relationship = @user.active_relationships.find_by(followed_id: @other.id)
    assert_difference '@user.following.count', -1 do
      delete api_relationship_path(relationship), {}, @headers
    end
    assert_response :ok
  end

  test "ユーザidでアンフォロー" do
    @user.follow(@other)

    assert_difference '@user.following.count', -1 do
      delete '/api/relationship', {relationship: {followed_id: @other.id}}, @headers
    end
    assert_response :ok
  end

  test "アンフォローできなければエラーを返すこと" do
    @user.follow(@other)
    relationship = @user.active_relationships.find_by(followed_id: @other.id)
    delete api_relationship_path(relationship), {}, @headers

    assert_no_difference '@user.following.count' do
      delete api_relationship_path(relationship), {}, @headers
    end
    assert_response :unprocessable_entity
  end

  test "フォローリストを取得できること" do
    get api_user_following_path(@user), {}, @headers
    assert_response :ok

    following = response_json[:following]
    assert_equal following[:count], @user.following.count
    following[:users].each do |user|
      assert_nil user[:email]
      %i(id name).each do |element|
        assert_not_nil user[element]
      end
    end
  end

  test "フォロワーリストを取得できること" do
    get api_user_followers_path(@user), {}, @headers
    assert_response :ok

    followers = response_json[:followers]
    assert_equal followers[:count], @user.followers.count
    followers[:users].each do |user|
      assert_nil user[:email]
      %i(id name).each do |element|
        assert_not_nil user[element]
      end
    end
  end
end
