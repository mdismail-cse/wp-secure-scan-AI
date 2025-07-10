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
      analysis_results[vuln_type] = analyze_vulnerability_type(vuln_type, vulnerabilities)
    end

    @scan.update(ai_analysis: analysis_results.to_json)
  end

  private

  def get_openai_client
    api_key = @scan.user.api_keys.first&.key
    return nil unless api_key

    OpenAI::Client.new(access_token: api_key)
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
      'critical' => 4,
      'high' => 3,
      'medium' => 2,
      'low' => 1
    }

    total_score = vulnerabilities.sum { |v| severity_scores[v.severity] || 0 }
    avg_score = total_score.to_f / vulnerabilities.count

    case avg_score
    when 3.5..4.0
      'Critical'
    when 2.5..3.4
      'High'
    when 1.5..2.4
      'Medium'
    else
      'Low'
    end
  end

  def calculate_priority(vulnerabilities)
    critical_count = vulnerabilities.count { |v| v.severity == 'critical' }
    high_count = vulnerabilities.count { |v| v.severity == 'high' }

    if critical_count > 0
      'Immediate'
    elsif high_count > 2
      'High'
    elsif high_count > 0
      'Medium'
    else
      'Low'
    end
  end
end