class ScansController < ApplicationController
  before_action :set_scan, only: [ :show, :download_report ]

  def index
    @scans = current_user.scans.recent.includes(:vulnerabilities)
    @scans = @scans.by_status(params[:status]) if params[:status].present?
    @scans = @scans.page(params[:page])
  end

  def show
    @vulnerabilities = @scan.vulnerabilities.includes(:scan)
  end

  def new
    @scan = current_user.scans.build
    @has_api_key = current_user.api_key.present?
  end

  def create
    # Rate limiting: max 5 scans per hour per user (disabled in development)
    if Rails.env.production?
      recent_scans = current_user.scans.where(created_at: 1.hour.ago..Time.current).count
      if recent_scans >= 5
        redirect_to new_scan_path, alert: "Rate limit exceeded. Please wait before submitting another scan."
        return
      end
    end

    @scan = current_user.scans.build(scan_params)
    @scan.status = "pending"

    if @scan.save
      # Process scan in background
      ScanProcessorJob.perform_later(@scan.id)
      redirect_to @scan, notice: "Plugin uploaded successfully. Scan is being processed."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def download_report
    respond_to do |format|
      format.html { render "reports/html_report", layout: "report" }
      format.pdf do
        pdf = ReportGenerator.new(@scan).generate_pdf
        send_data pdf, filename: "#{@scan.plugin_name}_security_report.pdf", type: "application/pdf"
      end
      format.md do
        markdown = ReportGenerator.new(@scan).generate_markdown
        send_data markdown, filename: "#{@scan.plugin_name}_security_report.md", type: "text/markdown"
      end
    end
  end

  private

  def set_scan
    @scan = current_user.scans.find(params[:id])
  end

  def scan_params
    params.require(:scan).permit(:plugin_name, :plugin_file)
  end
end
