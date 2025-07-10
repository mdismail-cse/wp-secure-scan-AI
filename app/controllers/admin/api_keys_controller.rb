class Admin::ApiKeysController < ApplicationController
  before_action :require_admin
  before_action :set_api_key, only: [ :edit, :update, :destroy ]

  def index
    @api_key = current_user.api_key
    redirect_to new_admin_api_key_path unless @api_key
  end

  def new
    # If user already has an API key, redirect to edit
    if current_user.api_key
      redirect_to edit_admin_api_key_path(current_user.api_key)
    else
      @api_key = current_user.build_api_key
    end
  end

  def create
    # Ensure user doesn't already have an API key
    if current_user.api_key
      redirect_to edit_admin_api_key_path(current_user.api_key),
                  alert: "You already have an API key. Please edit or delete the existing one."
      return
    end

    @api_key = current_user.build_api_key(api_key_params)

    if @api_key.save
      # Test the API key
      if test_openai_key(@api_key.key)
        redirect_to admin_api_keys_path, notice: "API key was successfully created and tested."
      else
        @api_key.destroy
        @api_key = current_user.build_api_key(api_key_params)
        @api_key.errors.add(:encrypted_key, "Invalid OpenAI API key")
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
        redirect_to admin_api_keys_path, notice: "API key was successfully updated and tested."
      else
        @api_key.errors.add(:encrypted_key, "Invalid OpenAI API key")
        render :edit, status: :unprocessable_entity
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @api_key.destroy
    redirect_to admin_api_keys_path, notice: "API key was successfully deleted."
  end

  private

  def set_api_key
    @api_key = current_user.api_key
    redirect_to new_admin_api_key_path, alert: "API key not found" unless @api_key
  end

  def api_key_params
    params.require(:api_key).permit(:name, :key)
  end

  def test_openai_key(key)
    return false if key.blank?

    begin
      client = OpenAI::Client.new(access_token: key)
      response = client.models.list
      response["data"].present?
    rescue => e
      Rails.logger.error "OpenAI API key test failed: #{e.message}"
      false
    end
  end
end
