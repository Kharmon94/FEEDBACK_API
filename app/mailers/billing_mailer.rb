# frozen_string_literal: true

# Billing/subscription emails. Call from Stripe webhooks or billing logic.
# Example: BillingMailer.payment_successful_first(user, plan_name: "Starter", amount: "$29").deliver_later
class BillingMailer < ApplicationMailer
  def payment_successful_first(user, plan_name:, price:, billing_cycle: "month", **opts)
    variables = billing_base(user).merge(
      plan_name: plan_name,
      price: price,
      billing_cycle: billing_cycle,
      next_billing_date: opts[:next_billing_date] || "",
      invoice_number: opts[:invoice_number] || "",
      payment_date: opts[:payment_date] || Date.current.strftime("%B %d, %Y"),
      payment_method: opts[:payment_method] || "",
      amount: opts[:amount] || price,
      invoice_url: opts[:invoice_url] || "#{frontend_origin}/dashboard?tab=billing",
      billing_url: "#{frontend_origin}/dashboard?tab=billing"
    )
    send_design_mail(user, "billing/payment-successful-first", variables, "Payment successful! 🎉")
  end

  def payment_successful_recurring(user, plan_name:, **opts)
    variables = billing_base(user).merge(
      plan_name: plan_name,
      invoice_number: opts[:invoice_number] || "",
      payment_date: opts[:payment_date] || Date.current.strftime("%B %d, %Y"),
      payment_method: opts[:payment_method] || "",
      billing_period: opts[:billing_period] || "",
      amount: opts[:amount] || "",
      next_billing_date: opts[:next_billing_date] || "",
      invoice_url: opts[:invoice_url] || "#{frontend_origin}/dashboard?tab=billing",
      billing_url: "#{frontend_origin}/dashboard?tab=billing"
    )
    send_design_mail(user, "billing/payment-successful-recurring", variables, "Payment received")
  end

  def payment_failed(user, amount:, payment_method:, failure_reason:, **opts)
    variables = billing_base(user).merge(
      amount: amount,
      payment_method: payment_method,
      failure_reason: failure_reason,
      grace_period_end: opts[:grace_period_end] || "",
      update_payment_url: "#{frontend_origin}/dashboard?tab=billing"
    )
    send_design_mail(user, "billing/payment-failed", variables, "Payment failed – action required")
  end

  def subscription_cancelled(user, plan_name:, **opts)
    variables = billing_base(user).merge(
      plan_name: plan_name,
      cancellation_date: opts[:cancellation_date] || Date.current.strftime("%B %d, %Y"),
      access_end_date: opts[:access_end_date] || "",
      deletion_date: opts[:deletion_date] || "",
      reactivate_url: "#{frontend_origin}/pricing",
      export_data_url: "#{frontend_origin}/dashboard",
      feedback_survey_url: opts[:feedback_survey_url] || ""
    )
    send_design_mail(user, "billing/subscription-cancelled", variables, "Subscription cancelled")
  end

  def renewal_reminder(user, plan_name:, renewal_date:, payment_method:, amount:, **opts)
    variables = billing_base(user).merge(
      plan_name: plan_name,
      renewal_date: renewal_date,
      payment_method: payment_method,
      amount: amount,
      update_payment_url: "#{frontend_origin}/dashboard?tab=billing",
      change_plan_url: "#{frontend_origin}/pricing",
      cancel_url: opts[:cancel_url] || "#{frontend_origin}/dashboard?tab=billing"
    )
    send_design_mail(user, "billing/renewal-reminder", variables, "Renewal reminder")
  end

  private

  def billing_base(user)
    {
      business_name: user.name.presence || user.email.split("@").first,
      dashboard_url: "#{frontend_origin}/dashboard"
    }
  end

  def send_design_mail(user, template_path, variables, subject)
    html = render_design_template(template_path, variables)
    mail(to: user.email, subject: subject) do |format|
      format.html { render html: html, layout: false }
    end
  end
end
