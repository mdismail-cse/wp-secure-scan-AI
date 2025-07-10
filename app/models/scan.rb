class Scan < ApplicationRecord
  belongs_to :user
  has_many :vulnerabilities, dependent: :destroy
  has_one_attached :plugin_file

  validates :plugin_name, presence: true
  validates :status, presence: true
  validate :plugin_file_size_limit, if: -> { plugin_file.attached? }

  enum :status, {
    pending: "pending",
    processing: "processing",
    completed: "completed",
    failed: "failed"
  }

  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }

  def error_message
    return nil unless failed? && scan_results.is_a?(Hash)
    scan_results['error']
  end

  def risk_level
    critical_count = vulnerabilities.where(severity: 'critical').count
    high_count = vulnerabilities.where(severity: 'high').count
    medium_count = vulnerabilities.where(severity: 'medium').count
    low_count = vulnerabilities.where(severity: 'low').count

    if critical_count > 0
      'critical'
    elsif high_count > 0
      'high'
    elsif medium_count > 0
      'medium'
    elsif low_count > 0
      'low'
    else
      'none'
    end
  end

  def risk_level_display
    case risk_level
    when 'critical'
      { text: 'Critical Risk', color: 'text-red-800 bg-red-100' }
    when 'high'
      { text: 'High Risk', color: 'text-red-600 bg-red-50' }
    when 'medium'
      { text: 'Medium Risk', color: 'text-yellow-600 bg-yellow-50' }
    when 'low'
      { text: 'Low Risk', color: 'text-blue-600 bg-blue-50' }
    else
      { text: 'No Risk', color: 'text-green-600 bg-green-50' }
    end
  end

  def duration_display
    return "-" unless completed?

    duration_seconds = (updated_at - created_at).to_i

    if duration_seconds < 60
      "#{duration_seconds} seconds"
    elsif duration_seconds < 3600
      "#{(duration_seconds / 60).round} minutes"
    else
      "#{(duration_seconds / 3600).round(1)} hours"
    end
  end

  def generate_report
    VulnerabilityReporter.new(self).generate_report
  end

  def vulnerability_summary
    {
      total: vulnerabilities.count,
      by_severity: vulnerabilities.group(:severity).count,
      by_type: vulnerabilities.group(:vulnerability_type).count
    }
  end

  private

  def plugin_file_size_limit
    if plugin_file.byte_size > 12.megabytes
      errors.add(:plugin_file, "File size must be less than 12MB")
    end
  end
end
