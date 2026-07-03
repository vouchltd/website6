$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:3010/")
$listener.Start()
Write-Output "Serving $root on http://localhost:3010/"

$mime = @{
  ".html" = "text/html"; ".htm" = "text/html"; ".css" = "text/css"; ".js" = "application/javascript";
  ".png" = "image/png"; ".jpg" = "image/jpeg"; ".jpeg" = "image/jpeg"; ".gif" = "image/gif";
  ".svg" = "image/svg+xml"; ".txt" = "text/plain"; ".json" = "application/json"; ".ico" = "image/x-icon";
}

while ($listener.IsListening) {
  $context = $listener.GetContext()
  $req = $context.Request
  $res = $context.Response
  try {
    $path = $req.Url.AbsolutePath
    if ($path -eq "/") { $path = "/index.html" }
    $filePath = Join-Path $root ($path.TrimStart("/"))
    if (Test-Path $filePath -PathType Leaf) {
      $ext = [System.IO.Path]::GetExtension($filePath)
      $contentType = $mime[$ext]
      if (-not $contentType) { $contentType = "application/octet-stream" }
      if ($contentType -like "text/*" -or $contentType -eq "application/javascript") { $contentType += "; charset=utf-8" }
      $bytes = [System.IO.File]::ReadAllBytes($filePath)
      $res.ContentType = $contentType
      $res.ContentLength64 = $bytes.Length
      $res.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $res.StatusCode = 404
      $msg = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
      $res.OutputStream.Write($msg, 0, $msg.Length)
    }
  } catch {
  } finally {
    $res.OutputStream.Close()
  }
}
