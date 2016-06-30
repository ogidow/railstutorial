require 'test_helper'

class PasswordResetsTest < ActionDispatch::IntegrationTest

  def setup
    ActionMailer::Base.deliveries.clear
    @user = users(:michael)
  end

  test "password resets" do
    get new_password_reset_path
    assert_template 'password_resets/new'

    #存在しないメールアドレスでリセットにトライ
    post password_resets_path, password_reset: {email: ""}
    assert_not flash.empty?
    assert_template 'password_resets/new'

    #存在するメールアドレスでリセットにトライ
    post password_resets_path, password_reset: {email: @user.email}
    assert_not_equal @user.reset_digest, @user.reload.reset_digest
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_not flash.empty?
    assert_redirected_to root_url

    user = assigns(:user)

    #間違ったメールアドレスでパスワードのアップデートにトライ
    get edit_password_reset_path(user.reset_token, email: "")
    assert_redirected_to root_url

    #アクティブじゃないユーザでパスワードのアップデートにトライ
    user.toggle!(:activated)
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_redirected_to root_url
    user.toggle!(:activated)

    #間違ったトークンでパスワードのアップデートにトライ
    get edit_password_reset_path("wrong token", email: user.email)
    assert_redirected_to root_url

    #正しいメールアドレス・トークンでアップデートにトライ
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_template 'password_resets/edit'
    assert_select "input[name=email][type=hidden][value=?]", user.email

    #新しいパスワードと確認用パスワードが一致しない
    patch password_reset_path(user.reset_token),  
      email: user.email,
      user: {
            password: "foobaz",
            password_confirmation: "barquux"
      }
    assert_select 'div#error_explanation'

    #空のパスワード
    patch password_reset_path(user.reset_token),
      email: user.email,
      user: {
        password: "",
        password_confirmation: ""
      }
    assert_select 'div#error_explanation'

    #成功
    patch password_reset_path(user.reset_token),
      email: user.email,
      user: {
        password: "foobaz",
        password_confirmation: "foobaz"
      }

    assert is_logged_in?
    assert_not flash.empty?
    assert_redirected_to user
  end
end
