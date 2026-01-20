module ApplicationHelper
  def campaign_status_badge(status)
    text = status.to_s.presence || "unknown"
    classes =
      case text
      when "pending"
        "bg-gray-100 text-gray-800 ring-gray-200"
      when "processing"
        "bg-blue-100 text-blue-800 ring-blue-200"
      when "completed"
        "bg-green-100 text-green-800 ring-green-200"
      else
        "bg-gray-100 text-gray-800 ring-gray-200"
      end

    content_tag(
      :span,
      text.humanize,
      class: "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ring-1 ring-inset #{classes}"
    )
  end

  def recipient_status_badge(status)
    text = status.to_s.presence || "unknown"
    classes =
      case text
      when "queued"
        "bg-gray-100 text-gray-800 ring-gray-200"
      when "sent"
        "bg-green-100 text-green-800 ring-green-200"
      when "failed"
        "bg-red-100 text-red-800 ring-red-200"
      else
        "bg-gray-100 text-gray-800 ring-gray-200"
      end

    content_tag(
      :span,
      text.humanize,
      class: "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ring-1 ring-inset #{classes}"
    )
  end
end
