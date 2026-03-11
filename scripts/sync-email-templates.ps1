# Sync Email Templates from GitHub
# Fetches HTML templates from BlackCollar27/Feedbackpage into feedback_api/email-templates/

$baseUrl = "https://raw.githubusercontent.com/BlackCollar27/Feedbackpage/main/email-templates"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$targetRoot = Join-Path (Split-Path -Parent $scriptDir) "email-templates"

$templates = @(
    @{ subdir = "auth"; file = "welcome.html" },
    @{ subdir = "auth"; file = "email-verification.html" },
    @{ subdir = "auth"; file = "password-reset.html" },
    @{ subdir = "feedback"; file = "new-negative-feedback.html" },
    @{ subdir = "feedback"; file = "new-suggestion.html" },
    @{ subdir = "feedback"; file = "new-optin.html" },
    @{ subdir = "customer"; file = "feedback-confirmation.html" },
    @{ subdir = "customer"; file = "optin-confirmation.html" },
    @{ subdir = "billing"; file = "payment-successful-first.html" },
    @{ subdir = "billing"; file = "payment-successful-recurring.html" },
    @{ subdir = "billing"; file = "payment-failed.html" },
    @{ subdir = "billing"; file = "subscription-upgraded.html" },
    @{ subdir = "billing"; file = "subscription-downgraded.html" },
    @{ subdir = "billing"; file = "subscription-cancelled.html" },
    @{ subdir = "billing"; file = "renewal-reminder.html" },
    @{ subdir = "trial"; file = "trial-15-days.html" },
    @{ subdir = "trial"; file = "trial-7-days.html" },
    @{ subdir = "trial"; file = "trial-3-days.html" },
    @{ subdir = "trial"; file = "trial-last-day.html" },
    @{ subdir = "trial"; file = "trial-expired.html" }
)

foreach ($t in $templates) {
    $targetDir = Join-Path $targetRoot $t.subdir
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    $url = "$baseUrl/$($t.subdir)/$($t.file)"
    $destPath = Join-Path $targetDir $t.file
    try {
        Invoke-WebRequest -Uri $url -OutFile $destPath -UseBasicParsing
        Write-Host "Downloaded: $($t.subdir)/$($t.file)"
    } catch {
        Write-Error "Failed to download $url : $_"
    }
}

Write-Host "Sync complete."
