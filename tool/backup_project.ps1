$source = "C:\Development\my_catholic_day"
$destination = "C:\Users\cazni\OneDrive\my_catholic_day"

Write-Host ""
Write-Host "Backing up My Catholic Day..."
Write-Host "From: $source"
Write-Host "To:   $destination"
Write-Host ""

New-Item `
  -ItemType Directory `
  -Force `
  -Path $destination |
Out-Null

robocopy `
  $source `
  $destination `
  /E `
  /Z `
  /FFT `
  /R:2 `
  /W:2 `
  /XJ `
  /XD `
  "$source\build" `
  "$source\.dart_tool"

$robocopyResult = $LASTEXITCODE

if ($robocopyResult -ge 8) {
  Write-Host ""
  Write-Host "Backup failed. Robocopy code: $robocopyResult"
  exit $robocopyResult
}

Write-Host ""
Write-Host "Backup completed successfully."
exit 0