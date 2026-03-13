# frozen_string_literal: true

class ContactMailer < ApplicationMailer
  def contact_submission(name:, email:, phone: nil, subject:, message:, source: "contact")
    to_email = AdminSetting.instance.support_email
    @name = name.presence || "Not provided"
    @email = email
    @phone = phone.presence || "Not provided"
    @subject_label = subject_label(subject)
    @message = message
    @source = source

    mail(to: to_email, subject: "[Feedback Page Contact] #{@subject_label} - #{@email}") do |format|
      format.html { render html: contact_html, layout: false }
      format.text { render plain: contact_text }
    end
  end

  private

  def subject_label(val)
    labels = {
      "general" => "General Question",
      "technical" => "Technical Support",
      "billing" => "Billing & Payment",
      "feature" => "Feature Request",
      "bug" => "Report a Bug",
      "account" => "Account Issue",
      "integration" => "Integration Help",
      "support" => "Technical Support",
      "partnership" => "Partnership Opportunity",
      "other" => "Other"
    }
    labels[val.to_s] || val.to_s.presence || "General Inquiry"
  end

  def contact_html
    <<~HTML.html_safe
      <div style="font-family: sans-serif; max-width: 600px;">
        <h2 style="color: #111;">New Contact Form Submission</h2>
        <p><strong>Source:</strong> #{@source}</p>
        <p><strong>Name:</strong> #{ERB::Util.html_escape(@name)}</p>
        <p><strong>Email:</strong> #{ERB::Util.html_escape(@email)}</p>
        <p><strong>Phone:</strong> #{ERB::Util.html_escape(@phone)}</p>
        <p><strong>Subject:</strong> #{ERB::Util.html_escape(@subject_label)}</p>
        <p><strong>Message:</strong></p>
        <pre style="background: #f5f5f5; padding: 12px; border-radius: 6px; white-space: pre-wrap;">#{ERB::Util.html_escape(@message)}</pre>
      </div>
    HTML
  end

  def contact_text
    <<~TEXT
      New Contact Form Submission (#{@source})
      --------------------------------------
      Name: #{@name}
      Email: #{@email}
      Phone: #{@phone}
      Subject: #{@subject_label}

      Message:
      #{@message}
    TEXT
  end
end
