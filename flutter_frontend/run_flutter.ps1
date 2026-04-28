$envPath = Join-Path $PSScriptRoot ".env"
$defines = @()

if (Test-Path $envPath) {
  Get-Content $envPath | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#") -and $line.Contains("=")) {
      $parts = $line.Split("=", 2)
      $key = $parts[0].Trim()
      $value = $parts[1].Trim()
      if ($value -and -not $value.Contains("your_")) {
        $defines += "--dart-define=$key=$value"
      }
    }
  }
}

flutter run -d chrome @defines
