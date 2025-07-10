#!/usr/bin/env ruby

# Simple test script to test the vulnerability scanner
require_relative 'config/environment'

# Test the vulnerability patterns directly
class TestScanner
  VULNERABILITY_PATTERNS = {
    sql_injection: {
      patterns: [
        /\$wpdb->get_results\s*\(\s*["\'].*\$.*["\'].*\)/i,
        /\$wpdb->query\s*\(\s*["\'].*\$.*["\'].*\)/i,
        /SELECT.*FROM.*WHERE.*\$_(?:GET|POST|REQUEST)\[/i,
        /mysql_query\s*\(\s*["\'].*\$.*["\'].*\)/i
      ],
      severity: 'high',
      description: 'SQL Injection vulnerability detected'
    },
    xss: {
      patterns: [
        /echo\s+\$_(?:GET|POST|REQUEST)\[/i,
        /print\s+\$_(?:GET|POST|REQUEST)\[/i,
        /innerHTML\s*=\s*[^;]*(?:params|input|value)/i,
        /<\?php\s+echo\s+\$_/i
      ],
      severity: 'high',
      description: 'Cross-Site Scripting (XSS) vulnerability detected'
    },
    rce: {
      patterns: [
        /eval\s*\(\s*\$_(?:GET|POST|REQUEST)/i,
        /system\s*\(\s*\$_(?:GET|POST|REQUEST)/i,
        /exec\s*\(\s*\$_(?:GET|POST|REQUEST)/i,
        /shell_exec\s*\(\s*\$_(?:GET|POST|REQUEST)/i
      ],
      severity: 'high',
      description: 'Remote Code Execution vulnerability detected'
    }
  }.freeze

  def initialize(directory)
    @directory = directory
  end

  def scan_files
    vulnerabilities = []

    Dir.glob("#{@directory}/**/*.{php,js}").each do |file_path|
      content = File.read(file_path)
      relative_path = file_path.gsub(@directory + '/', '')

      VULNERABILITY_PATTERNS.each do |type, config|
        config[:patterns].each do |pattern|
          content.lines.each_with_index do |line, index|
            if line.match?(pattern)
              vulnerabilities << {
                type: type,
                file: relative_path,
                line: index + 1,
                severity: config[:severity],
                description: config[:description],
                code_snippet: line.strip
              }
            end
          end
        end
      end
    end

    vulnerabilities
  end
end

# Test the scanner
puts "Testing Vulnerability Scanner..."
puts "=" * 50

scanner = TestScanner.new('/tmp/test-plugin')
vulnerabilities = scanner.scan_files

puts "Found #{vulnerabilities.length} vulnerabilities:"
puts

vulnerabilities.each_with_index do |vuln, index|
  puts "#{index + 1}. #{vuln[:type].to_s.humanize} (#{vuln[:severity]})"
  puts "   File: #{vuln[:file]}:#{vuln[:line]}"
  puts "   Description: #{vuln[:description]}"
  puts "   Code: #{vuln[:code_snippet]}"
  puts
end

puts "Test completed!"
