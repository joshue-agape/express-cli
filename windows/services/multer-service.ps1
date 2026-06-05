function install-multer-service-express {
    if (-Not (Test-Path "package.json")) {
        Write-Host "`n--- package.json not found. Run this inside a Node.js project. ---" -ForegroundColor red
        return
    }

    Write-Host "`n--- Installing dependencies (Production) ---" -ForegroundColor Cyan
    npm install multer

    Write-Host "`n--- Installing dependencies (Development) ---" -ForegroundColor Cyan
    npm install -D @types/multer
}