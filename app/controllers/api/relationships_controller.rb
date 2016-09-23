class Api::RelationshipsController < Api::ApplicationController
  before_action :check_auth_token

  def create
    @user = User.find_by(id: relationship_params[:followed_id])
    render nothing: true, status: :unprocessable_entity and return if @user.nil?

    @follow = current_user.follow(@user)
    if @follow.persisted?
      render nothing: true, status: :created
    else
      build_json = Jbuilder.encode do |json|
        json.message "Validation Failed"
        json.errors @follow.errors.messages
      end
      render json: build_json, status: :unprocessable_entity
    end
  end

  def destroy
    @relation = Relationship.find_by(id: params[:id])
    render nothing: true, status: :unprocessable_entity and return if @relation.nil?

    current_user.unfollow(@relation.followed)
    render nothing: true, status: :ok
  end

  private
    def relationship_params
      params.require(:relationship).permit(:followed_id)
    end
end
