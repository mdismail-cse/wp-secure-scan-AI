class ApiKey < ApplicationRecord
  belongs_to :user

  encrypts :encrypted_key

  validates :name, presence: true
  validates :encrypted_key, presence: true

  def key=(value)
    self.encrypted_key = value
  end

  def key
    encrypted_key
  end
end
