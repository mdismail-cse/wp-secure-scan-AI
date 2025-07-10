module ScansHelper
  def risk_score_color(score)
    case score
    when 90..100
      'text-red-600'
    when 70..89
      'text-red-500'
    when 40..69
      'text-yellow-600'
    when 10..39
      'text-green-600'
    else
      'text-gray-600'
    end
  end

  def severity_header_color(severity)
    case severity
    when 'critical'
      'bg-red-100 text-red-800'
    when 'high'
      'bg-red-50 text-red-700'
    when 'medium'
      'bg-yellow-50 text-yellow-700'
    when 'low'
      'bg-blue-50 text-blue-700'
    else
      'bg-gray-50 text-gray-700'
    end
  end
end
