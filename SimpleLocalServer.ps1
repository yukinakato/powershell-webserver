$docRoot = "dist"

$port = (Get-Random -Minimum 10000 -Maximum 60000)

Add-Type -AssemblyName System.Web

[Environment]::CurrentDirectory = (Get-Location).ProviderPath

function ContentType ($ext) {
    switch ($ext.ToLower()) {
        "js" { "text/javascript" }
        "css" { "text/css" }
        "xml" { "application/xml" }
        "txt" { "text/plain" }
        "csv" { "text/csv" }
        "gif" { "image/gif" }
        "png" { "image/png" }
        "svg" { "image/svg+xml" }
        "ico" { "image/x-icon" }
        "jpg" { "image/jpeg" }
        "jpeg" { "image/jpeg" }
        "html" { "text/html" }
        "json" { "application/json" }
        "woff" { "font/woff" }
        "woff2" { "font/woff2" }
        Default { "application/octet-stream" }
    }
}

try {
    Write-Host Starting server...
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:${port}/")
    $listener.Start()
    Write-Host Listening at - http://localhost:${port}/
    Start-Process "http://localhost:${port}/"

    while ($true) {
        $task = $listener.GetContextAsync()
        while (-not $task.AsyncWaitHandle.WaitOne(200)) {}
        $context = $task.GetAwaiter().GetResult()

        $request = $context.Request
        $response = $context.Response

        $target = Join-Path $docRoot ([System.Web.HttpUtility]::UrlDecode($request.RawUrl))
        if ($target[-1] -eq "\") {
            $target += "index.html"
        }
        elseif (Test-Path $target -PathType Container) {
            $target += "\index.html"
        }

        if (Test-Path $target -PathType Leaf) {
            $buffer = [IO.File]::ReadAllBytes($target)
            $response.StatusCode = 200
            $response.ContentLength64 = $buffer.Length
            $response.ContentType = ContentType($target.Split(".")[-1])
            $response.Close($buffer, $false)
        }
        else {
            $response.StatusCode = 404
            $response.ContentLength64 = 0
            $response.Close()
        }

        # Write-Output $request
        # Write-Output $response
    }
}
catch {
    Write-Host Error: $_
    Write-Host
    Write-Host Exiting...
}
finally {
    $listener.Dispose()
}
