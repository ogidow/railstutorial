class Api::ListsController < Api::ApplicationController
  before_action :check_auth_token
  before_action :correct_user, only: [:destroy, :update]

  def show
    @list = List.find(params[:id])
  end

  def create
    @list = current_user.lists.build(list_params)
    if @list.save
      render status: :created
    else
      build_json = Jbuilder.encode do |json|
        json.message "Validation Failed"
        json.errors = @list.errors.messages 
      end
      render json: build_json, status: :unprocessable_entity
    end
  end

  def update
    @list = List.find(params[:id])
    if @list.update_attributes(list_params)
      render status: :ok
    else
      render json: "{}", status: :unprocessable_entity
    end
  end

  def destroy
    list = List.find(params[:id])
    list.destroy
    render json: "{}", status: :ok
  end

  def feed
    list = List.find_by(id: params[:id])
    @feed = list.feed.restrict(request_microposts_params.to_h.symbolize_keys)

    render status: :ok
  end

  private

  def list_params
    params.require(:list).permit(:name)
  end

  def correct_user
    list = current_user.lists.find_by(id: params[:id])
    render json: "{}", status: :forbidden and return if list.nil?
  end

  def request_microposts_params
    params.fetch(:request_microposts, {}).permit(:since_id, :max_id, :count)
  end
end
