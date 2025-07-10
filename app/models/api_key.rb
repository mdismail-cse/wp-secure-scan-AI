class ApiKey < ApplicationRecord
  belongs_to :user

  encrypts :encrypted_key

  validates :name, presence: true
  validates :encrypted_key, presence: true
  validates :user_id, uniqueness: { message: "can only have one API key" }
  validates :provider, inclusion: { in: %w[openai openrouter] }, allow_nil: true

  before_validation :set_default_provider

  private

  def set_default_provider
    self.provider ||= 'openai'
  end

  public

  def key=(value)
    self.encrypted_key = value
  end

  def key
    encrypted_key
  end

  def openai?
    provider == 'openai'
  end

  def openrouter?
    provider == 'openrouter'
  end
end
