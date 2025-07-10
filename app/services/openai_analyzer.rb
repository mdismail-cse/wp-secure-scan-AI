class OpenaiAnalyzer
  def initialize(scan)
    @scan = scan
    @client = get_openai_client
  end

  def analyze_vulnerabilities
    return unless @client && @scan.vulnerabilities.any?

    vulnerabilities_by_type = @scan.vulnerabilities.group_by(&:vulnerability_type)

    analysis_results = {}

    vulnerabilities_by_type.each do |vuln_type, vulnerabilities|
      analysis_result = analyze_vulnerability_type(vuln_type, vulnerabilities)
      analysis_results[vuln_type] = analysis_result

      # Update individual vulnerabilities with AI analysis
      update_individual_vulnerabilities(vulnerabilities, analysis_result)
    end

    @scan.update(ai_analysis: analysis_results.to_json)
  end

  private

  def get_openai_client
    api_key_record = @scan.user.api_key
    return nil unless api_key_record

    OpenAI::Client.new(access_token: api_key_record.key)
  end

  def analyze_vulnerability_type(vuln_type, vulnerabilities)
    code_snippets = vulnerabilities.map do |vuln|
      {
        file: vuln.file_path,
        line: vuln.line_number,
        code: vuln.code_snippet,
        severity: vuln.severity
      }
    end

    prompt = build_analysis_prompt(vuln_type, code_snippets)

    begin
      response = @client.chat(
        parameters: {
          model: "gpt-4",
          messages: [
            {
              role: "system",
              content: "You are a WordPress security expert. Analyze the provided code snippets for security vulnerabilities and provide detailed explanations and remediation suggestions."
            },
            {
              role: "user",
              content: prompt
            }
          ],
          max_tokens: 1500,
          temperature: 0.3
        }
      )

      {
        analysis: response.dig("choices", 0, "message", "content"),
        risk_level: calculate_risk_level(vulnerabilities),
        remediation_priority: calculate_priority(vulnerabilities),
        affected_files: vulnerabilities.map(&:file_path).uniq
      }
    rescue => e
      Rails.logger.error "OpenAI analysis failed: #{e.message}"
      {
        analysis: "AI analysis unavailable: #{e.message}",
        risk_level: calculate_risk_level(vulnerabilities),
        remediation_priority: calculate_priority(vulnerabilities),
        affected_files: vulnerabilities.map(&:file_path).uniq
      }
    end
  end

  def build_analysis_prompt(vuln_type, code_snippets)
    prompt = <<~PROMPT
      Analyze the following #{vuln_type} vulnerabilities found in a WordPress plugin:

      Plugin: #{@scan.plugin_name}
      Vulnerability Type: #{vuln_type}

      Code Snippets:
    PROMPT

    code_snippets.each_with_index do |snippet, index|
      prompt += <<~SNIPPET

        #{index + 1}. File: #{snippet[:file]} (Line #{snippet[:line]})
           Severity: #{snippet[:severity]}
           Code: #{snippet[:code]}
      SNIPPET
    end

    prompt += <<~QUESTIONS

      Please provide:
      1. A detailed explanation of why this code is vulnerable
      2. The potential impact if exploited
      3. Specific remediation steps for WordPress development
      4. Code examples showing the secure implementation
      5. Any WordPress-specific functions that should be used instead

      Focus on practical, actionable advice for WordPress plugin developers.
    QUESTIONS

    prompt
  end

  def calculate_risk_level(vulnerabilities)
    severity_scores = {
      "critical" => 4,
      "high" => 3,
      "medium" => 2,
      "low" => 1
    }

    total_score = vulnerabilities.sum { |v| severity_scores[v.severity] || 0 }
    avg_score = total_score.to_f / vulnerabilities.count

    case avg_score
    when 3.5..4.0
      "Critical"
    when 2.5..3.4
      "High"
    when 1.5..2.4
      "Medium"
    else
      "Low"
    end
  end

  def calculate_priority(vulnerabilities)
    critical_count = vulnerabilities.count { |v| v.severity == "critical" }
    high_count = vulnerabilities.count { |v| v.severity == "high" }

    if critical_count > 0
      "Immediate"
    elsif high_count > 2
      "High"
    elsif high_count > 0
      "Medium"
    else
      "Low"
    end
  end

  def update_individual_vulnerabilities(vulnerabilities, analysis_result)
    return unless analysis_result[:analysis].present?

    # Parse the AI analysis to extract individual explanations and fixes
    analysis_text = analysis_result[:analysis]

    vulnerabilities.each_with_index do |vulnerability, index|
      # Skip if this vulnerability already has AI analysis
      next if vulnerability.ai_explanation.present?

      # For now, assign the same analysis to all vulnerabilities of this type
      # In a more sophisticated implementation, you could parse the analysis
      # to extract specific explanations for each vulnerability
      vulnerability.update(
        ai_explanation: analysis_text,
        fix_suggestion: extract_fix_suggestion(analysis_text)
      )
    end
  end

  def extract_fix_suggestion(analysis_text)
    # Extract fix suggestions from the analysis text
    # Look for common patterns like "Fix:", "Solution:", "Remediation:", etc.
    fix_patterns = [
      /(?:Fix|Solution|Remediation|Recommendation):\s*(.+?)(?:\n\n|\z)/mi,
      /(?:To fix|To resolve|To prevent):\s*(.+?)(?:\n\n|\z)/mi,
      /(?:Use|Replace with|Instead):\s*(.+?)(?:\n\n|\z)/mi
    ]

    fix_patterns.each do |pattern|
      match = analysis_text.match(pattern)
      return match[1].strip if match
    end

    # If no specific fix pattern found, return a generic suggestion
    "Please review the AI analysis above for specific remediation steps."
  end
end
