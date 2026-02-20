Write-Host "Updating Flutter dependencies..." -ForegroundColor Cyan
flutter pub get
flutter pub outdated
flutter pub upgrade
Write-Host "Dependency update complete." -ForegroundColor Green
