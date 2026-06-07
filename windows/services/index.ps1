. "$PSScriptRoot\auth-service.ps1"
. "$PSScriptRoot\mailer-service.ps1"
. "$PSScriptRoot\multer-service.ps1"


function Get-CheckboxSelection {
    param([string[]]$Items)

    $selected = [System.Collections.Generic.List[int]]::new()
    $currentIndex = 0
    $keepRunning = $true
    
    $startPos = $Host.UI.RawUI.CursorPosition

    while ($keepRunning) {
        $Host.UI.RawUI.CursorPosition = $startPos
        
        Write-Host "--- Use arrow keys to navigate, SPACE to select, ENTER to confirm ---`n" -ForegroundColor Cyan

        for ($i = 0; $i -lt $Items.Count; $i++) {
            $prefix = if ($currentIndex -eq $i) { ">" } else { " " }
            $check = if ($selected.Contains($i)) { "[X]" } else { "[ ]" }
            
            if ($currentIndex -eq $i) {
                Write-Host "$prefix $check $($Items[$i])" -ForegroundColor Yellow
            } else {
                Write-Host "$prefix $check $($Items[$i])"
            }
        }

        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

        switch ($key.VirtualKeyCode) {
            38 { $currentIndex = ($currentIndex - 1 + $Items.Count) % $Items.Count }
            40 { $currentIndex = ($currentIndex + 1) % $Items.Count }
            32 {
                if ($selected.Contains($currentIndex)) { $selected.Remove($currentIndex) }
                else { $selected.Add($currentIndex) }
            }
            13 { $keepRunning = $false }
        }
    }
    
    Write-Host "`n"
    return $Items | Where-Object { $selected.Contains([array]::IndexOf($Items, $_)) }
}

function Install-Express-Services {
    $servicesDisponibles = @("Auth Service", "Multer File Upload Service", "Mailer Service")
    $choix = Get-CheckboxSelection -Items $servicesDisponibles

    if ($choix.Count -eq 0) {
        Write-Warning "Aucun service sélectionné."
        return
    }

    Write-Host "`nInstalling selected services:" -ForegroundColor Green
    foreach ($service in $choix) {
        switch ($service) {
            "Auth Service" {
                Write-Host ""
                Write-Host "`n--- AUTH SERVICE SETUP ---" -ForegroundColor Cyan
                install-auth-service-express
            }
            "Multer File Upload Service" {
                Write-Host ""
                Write-Host "`n--- MULTER FILE UPLOAD SERVICE SETUP ---" -ForegroundColor Cyan
                install-multer-service-express
            }
            "Mailer Service" {
                Write-Host ""
                Write-Host "`n--- MAILER SERVICE SETUP ---" -ForegroundColor Cyan
                install-mailer-service-express
            }
        }
    }
}

function Get-RadioSelection {
    param([string[]]$Items)

    $selectedIndex = 0
    $keepRunning = $true
    $startPos = $Host.UI.RawUI.CursorPosition

    while ($keepRunning) {
        $Host.UI.RawUI.CursorPosition = $startPos
        Write-Host "--- Select exactly one service (Use arrows, ENTER to confirm) ---`n" -ForegroundColor Cyan

        for ($i = 0; $i -lt $Items.Count; $i++) {
            $marker = if ($selectedIndex -eq $i) { "(*)" } else { "( )" }
            
            if ($selectedIndex -eq $i) {
                Write-Host " > $marker $($Items[$i])" -ForegroundColor Yellow
            } else {
                Write-Host "   $marker $($Items[$i])"
            }
        }

        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

        switch ($key.VirtualKeyCode) {
            38 { $selectedIndex = ($selectedIndex - 1 + $Items.Count) % $Items.Count }
            40 { $selectedIndex = ($selectedIndex + 1) % $Items.Count }
            13 { $keepRunning = $false }
        }
    }
    
    return $Items[$selectedIndex]
}

function Install-Express-Service {
    $servicesDisponibles = @("Auth Service", "Multer File Upload Service", "Mailer Service")
    
    $choix = Get-RadioSelection -Items $servicesDisponibles

    Write-Host "`nSelected: $choix" -ForegroundColor Green

    switch ($choix) {
        "Auth Service" {
            Write-Host ""
            Write-Host "`n--- AUTH SERVICE SETUP ---" -ForegroundColor Cyan
            install-auth-service-express
        }
        "Multer File Upload Service" {
            Write-Host ""
            Write-Host "`n--- MULTER FILE UPLOAD SERVICE SETUP ---" -ForegroundColor Cyan
            install-multer-service-express
        }
        "Mailer Service" {
            Write-Host ""
            Write-Host "`n--- MAILER SERVICE SETUP ---" -ForegroundColor Cyan
            install-mailer-service-express
        }
    }
}