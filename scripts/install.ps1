$ErrorActionPreference = "Continue"

$GITHUB_REPO = "entireio/cli"
$INSTALL_DIR = Join-Path $HOME ".entire\bin"
$BINARY_NAME = "entire.exe"

function Write-Info($msg) { Write-Host "==> $msg" -ForegroundColor Blue }
function Write-Success($msg) { Write-Host "==> $msg" -ForegroundColor Green }
function Write-Error-Custom($msg) { Write-Host "Error: $msg" -ForegroundColor Red }

if (!(Get-Command go -ErrorAction SilentlyContinue)) {
    Write-Error-Custom "Go is not installed. Download it here: https://go.dev/dl/"
    exit 1
}

if (!(Test-Path $INSTALL_DIR)) {
    New-Item -ItemType Directory -Path $INSTALL_DIR -Force | Out-Null
}

$tmp_dir = Join-Path $env:TEMP "entire-build-$([Guid]::NewGuid().ToString().Substring(0,8))"
New-Item -ItemType Directory -Path $tmp_dir | Out-Null

try {
    Write-Info "Cloning latest source..."
    git clone --depth 1 "https://github.com/$GITHUB_REPO.git" $tmp_dir
    Set-Location $tmp_dir

    Write-Info "Fetching dependencies..."
    go mod download

    Write-Info "Compiling..."

    if (Test-Path "./cmd/entire") {
        go build -v -ldflags="-s -w" -o $BINARY_NAME ./cmd/entire
    } else {
        go build -v -ldflags="-s -w" -o $BINARY_NAME .
    }

    if (Test-Path $BINARY_NAME) {
        Write-Info "Installing binary to $INSTALL_DIR..."
        Move-Item -Path (Join-Path $tmp_dir $BINARY_NAME) -Destination (Join-Path $INSTALL_DIR $BINARY_NAME) -Force
        
        Write-Info "Updating PATH..."
        $current_path = [Environment]::GetEnvironmentVariable("Path", "User")
        if ($current_path -notlike "*$INSTALL_DIR*") {
            $new_path = "$current_path;$INSTALL_DIR"
            [Environment]::SetEnvironmentVariable("Path", $new_path, "User")
            $env:Path = "$env:Path;$INSTALL_DIR" 
        }

        Write-Success "Successfully built and installed Entire CLI!"
        Write-Host "Restart your terminal and run 'entire version' to verify."
    } else {
        Write-Error-Custom "The build finished but $BINARY_NAME was not found in $(Get-Location)."
    }
}
catch {
    Write-Error-Custom "An unexpected script error occurred: $($_.Exception.Message)"
}
finally {
    Set-Location $env:USERPROFILE
}