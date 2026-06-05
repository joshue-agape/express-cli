. "$PSScriptRoot\auth-service.ps1"
. "$PSScriptRoot\mailer-service.ps1"
. "$PSScriptRoot\multer-service.ps1"


function install-express-service {
    Write-Host "`n--- Choose and select the services ---" -ForegroundColor Cyan
    Write-Host "1. Auth Service"
    Write-Host "2. Multer File Upload Service"
    Write-Host "3. Mailer Service"

    $service = Read-Host "Select your service (1-3)"

    switch ($service) {
        "1" {
            install-auth-service-express
        }
        "2" {
            install-multer-service-express
        }
        "3" {
            install-mailer-service-express
        }
    }
}