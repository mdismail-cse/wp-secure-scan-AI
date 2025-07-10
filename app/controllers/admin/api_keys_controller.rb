class Admin::ApiKeysController < ApplicationController
  before_action :require_admin
  before_action :set_api_key, only: [:show, :edit, :update, :destroy]

  def index
    @api_keys = current_user.api_keys.order(created_at: :desc)
  end

  def new
    @api_key = current_user.api_keys.build
  end

  def create
    @api_key = current_user.api_keys.build(api_key_params)

    if @api_key.save
      # Test the API key
      if test_openai_key(@api_key.key)
        redirect_to admin_api_keys_path, notice: 'API key was successfully created and tested.'
      else
        @api_key.destroy
        @api_key = current_user.api_keys.build(api_key_params)
        @api_key.errors.add(:encrypted_key, 'Invalid OpenAI API key')
        render :new, status: :unprocessable_entity
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @api_key.update(api_key_params)
      if test_openai_key(@api_key.key)
        redirect_to admin_api_keys_path, notice: 'API key was successfully updated and tested.'
      else
        @api_key.errors.add(:encrypted_key, 'Invalid OpenAI API key')
        render :edit, status: :unprocessable_entity
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @api_key.destroy
    redirect_to admin_api_keys_path, notice: 'API key was successfully deleted.'
  end

  private

  def set_api_key
    @api_key = current_user.api_keys.find(params[:id])
  end

  def api_key_params
    params.require(:api_key).permit(:name, :key)
  end

  def test_openai_key(key)
    return false if key.blank?

    begin
      client = OpenAI::Client.new(access_token: key)
      response = client.models.list
      response['data'].present?
    rescue => e
      Rails.logger.error "OpenAI API key test failed: #{e.message}"
      false
    end
  end
end
