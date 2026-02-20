# Creates GitHub issues from markdown files in this folder using the GitHub CLI (gh)
# Requirements: gh CLI installed and authenticated (gh auth login)

$files = Get-ChildItem -Path $PSScriptRoot -Filter "*.md" | Where-Object { $_.Name -ne 'README.md' }

foreach ($file in $files) {
    try {
        $firstLine = Get-Content -Path $file.FullName -TotalCount 1
        $title = $firstLine -replace '^#\s*', '' -replace '\s+$',''
        if ([string]::IsNullOrWhiteSpace($title)) {
            Write-Host "Skipping $($file.Name): missing title"
            continue
        }

        Write-Host "Creating issue: $title"
        gh issue create --title "$title" --body-file "$($file.FullName)" --label "todo","tech-debt" | Out-Null
        Write-Host "Created: $title"
        Start-Sleep -Milliseconds 300
    } catch {
        Write-Host "Failed to create issue for $($file.Name): $_"
    }
}
