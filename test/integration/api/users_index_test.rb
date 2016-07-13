require 'test_helper'

class ApiUsersIndexTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:michael)
    token = auth_as(@user)
    @headers = {"Authorization" => "Bearer #{token}"}
  end

  test "user一覧の取得(認証付き)" do
    get api_users_path, {}, @headers
    assert_response :success

    params = api_params
    users_names = params[:users].map{|user| user[:name]}

    first_page_users = User.where(activated: true).paginate(page: 1)
    first_page_users.each do |user|
      assert users_names.include?(user[:name])
    end
  end
  
end
