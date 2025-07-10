class ScanProcessorJob < ApplicationJob
  queue_as :default

  def perform(scan_id)
    scan = Scan.find(scan_id)

    # Run vulnerability scanner
    scanner = VulnerabilityScanner.new(scan)
    scanner.scan

    # Run AI analysis if vulnerabilities found
    if scan.vulnerabilities.any?
      api_key = scan.user.api_key
      if api_key
        analyzer = if api_key.openrouter?
                     OpenrouterAnalyzer.new(scan)
                   else
                     OpenaiAnalyzer.new(scan)
                   end
        analyzer.analyze_vulnerabilities
      else
        Rails.logger.warn "No API key found for user #{scan.user.id}, skipping AI analysis"
      end
    end

    Rails.logger.info "Scan #{scan_id} completed with #{scan.vulnerabilities.count} vulnerabilities found"
  rescue => e
    Rails.logger.error "Scan processing failed for scan #{scan_id}: #{e.message}"
    scan&.update(status: "failed", scan_results: { error: e.message })
    raise e
  end
end
