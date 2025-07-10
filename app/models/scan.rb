class Scan < ApplicationRecord
  belongs_to :user
  has_many :vulnerabilities, dependent: :destroy
  has_one_attached :plugin_file

  validates :plugin_name, presence: true
  validates :status, presence: true

  enum status: {
    pending: 'pending',
    processing: 'processing',
    completed: 'completed',
    failed: 'failed'
  }

  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }
end
