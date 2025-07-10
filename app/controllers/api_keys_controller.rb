class ApiKeysController < ApplicationController
  before_action :authenticate_user!
  before_action :set_api_key, only: [:show, :edit, :update, :destroy]

  def show
    # Show the current API key
    @api_key = current_user.api_key
    if @api_key.nil?
      redirect_to new_api_key_path, notice: "You don't have an API key yet. Please create one."
    end
  end

  def new
    # If user already has an API key, redirect to edit
    if current_user.api_key
      redirect_to edit_api_key_path(current_user.api_key), 
                  notice: "You already have an API key. You can update it here."
    else
      @api_key = current_user.build_api_key
    end
  end

  def create
    # Ensure user doesn't already have an API key
    if current_user.api_key
      redirect_to edit_api_key_path(current_user.api_key),
                  alert: "You already have an API key. Please edit or delete the existing one."
      return
    end

    # Get the raw API key value before building the model
    # Use api_token to avoid Rails parameter filtering
    raw_api_key = api_key_params[:api_token] || api_key_params[:key]
    Rails.logger.info "Raw API key from params: #{raw_api_key.present? ? 'Present' : 'Blank'}"
    Rails.logger.info "API key first 10 chars: #{raw_api_key[0..9] if raw_api_key.present?}"

    # Test the API key and detect provider before saving
    provider = detect_api_provider(raw_api_key)

    if provider
      # Build params with key mapped from api_token
      build_params = api_key_params.except(:api_token)
      build_params[:key] = raw_api_key if raw_api_key.present?

      @api_key = current_user.build_api_key(build_params)
      @api_key.provider = provider

      if @api_key.save
        redirect_to api_key_path, notice: "API key was successfully created and validated as #{provider.upcase} key."
      else
        render :new, status: :unprocessable_entity
      end
    else
      @api_key = current_user.build_api_key(api_key_params.except(:api_token))
      @api_key.errors.add(:encrypted_key, "Invalid API key. Please check your key and try again.")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Edit form will be rendered
  end

  def update
    # Get the raw API key value if provided
    # Use api_token to avoid Rails parameter filtering
    raw_api_key = api_key_params[:api_token] || api_key_params[:key]

    # Build update params
    update_params = api_key_params.except(:api_token)
    if raw_api_key.present?
      update_params[:key] = raw_api_key
    else
      update_params = update_params.except(:key)
    end

    if @api_key.update(update_params)
      # Only test if a new key was provided
      if raw_api_key.present?
        provider = detect_api_provider(raw_api_key)
        if provider
          @api_key.update(provider: provider)
          redirect_to api_key_path, notice: "API key was successfully updated and validated as #{provider.upcase} key."
        else
          @api_key.errors.add(:encrypted_key, "Invalid API key. Please check your key and try again.")
          render :edit, status: :unprocessable_entity
        end
      else
        redirect_to api_key_path, notice: "API key name was successfully updated."
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @api_key.destroy
    redirect_to new_api_key_path, notice: "API key was successfully deleted."
  end

  private

  def set_api_key
    @api_key = current_user.api_key
    if @api_key.nil? && params[:action] != 'new' && params[:action] != 'create'
      redirect_to new_api_key_path, alert: "API key not found. Please create one."
    end
  end

  def api_key_params
    params.require(:api_key).permit(:name, :key, :api_token)
  end

  def detect_api_provider(key)
    return nil if key.blank?

    Rails.logger.info "Testing API key starting with: #{key[0..10]}..."

    # Try OpenRouter first (keys usually start with sk-or-)
    if key.start_with?('sk-or-') || OpenrouterAnalyzer.test_api_key(key)
      Rails.logger.info "Testing as OpenRouter key..."
      if OpenrouterAnalyzer.test_api_key(key)
        Rails.logger.info "API key validated as OpenRouter key"
        return 'openrouter'
      else
        Rails.logger.info "OpenRouter validation failed"
      end
    end

    # Fall back to OpenAI
    Rails.logger.info "Testing as OpenAI key..."
    begin
      client = OpenAI::Client.new(access_token: key)
      # Test with a simple API call
      response = client.models.list
      if response["data"].present?
        Rails.logger.info "API key validated as OpenAI key"
        return 'openai'
      end
    rescue Faraday::UnauthorizedError => e
      Rails.logger.error "OpenAI API key test failed - Unauthorized: #{e.message}"
    rescue => e
      Rails.logger.error "OpenAI API key test failed: #{e.message}"
    end

    nil
  end
end
