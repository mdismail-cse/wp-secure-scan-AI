class HomeController < ApplicationController
  def index
    @recent_scans = current_user.scans.recent.limit(5)
    @total_scans = current_user.scans.count
    @critical_vulnerabilities = current_user.vulnerabilities.critical_and_high.count
    @pending_scans = current_user.scans.pending.count
  end
end
