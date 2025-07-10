class ScanProcessorJob < ApplicationJob
  queue_as :default

  def perform(scan_id)
    scan = Scan.find(scan_id)

    # Run vulnerability scanner
    scanner = VulnerabilityScanner.new(scan)
    scanner.analyze

    # Run AI analysis if vulnerabilities found
    if scan.vulnerabilities.any?
      analyzer = OpenaiAnalyzer.new(scan)
      analyzer.analyze_vulnerabilities
    end

    Rails.logger.info "Scan #{scan_id} completed with #{scan.vulnerabilities.count} vulnerabilities found"
  rescue => e
    Rails.logger.error "Scan processing failed for scan #{scan_id}: #{e.message}"
    scan&.update(status: "failed", scan_results: { error: e.message })
    raise e
  end
end
