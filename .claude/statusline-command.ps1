# Claude Code Advanced StatusLine PowerShell Script for Windows 11
# Display model name in orange color using ANSI escape codes

param()

# Set PowerShell output encoding to UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Read JSON input from stdin
$jsonInput = ""
try {
    $inputStream = [System.IO.StreamReader]::new([System.Console]::OpenStandardInput())
    $jsonInput = $inputStream.ReadToEnd()
    $inputStream.Close()
}
catch {
    # Use default JSON if stdin read fails
    $jsonInput = '{"model":{"display_name":"Claude"}}'
}

try {
    # Parse JSON data
    $inputData = $jsonInput | ConvertFrom-Json

    # Extract model information
    $modelName = if ($inputData.model.display_name) { $inputData.model.display_name } else { "Claude" }
    $outputStyle = if ($inputData.output_style.name) { $inputData.output_style.name } else { "" }

    $totalTokens = $inputData.tokens.total
    $sessionCost = [math]::Round($inputData.cost.total_cost_usd, 4)

    # Define ANSI color codes
    $orangeMedium = "$([char]27)[38;5;208m"
    $orangeBright = "$([char]27)[38;5;220m"
    $dimGray = "$([char]27)[2m"
    $bold = "$([char]27)[1m"
    $reset = "$([char]27)[0m"

    # Select orange color (bright for Haiku, medium for others)
    $orangeColor = $orangeMedium
    if ($modelName -like "*Haiku*") {
        $orangeColor = $orangeBright
    }

    # Build output string
    $outputText = "$orangeColor$bold$modelName Total Tokens: $dimGray$totalTokens$reset"

    # Add output style if present
    if ($outputStyle -and $outputStyle -ne "default") {
        $outputText = $outputText + " $dimGray($outputStyle)$reset"
    }

    # Write directly to standard output (do not use Write-Host)
    [System.Console]::Write($outputText)
    [System.Console]::Out.Flush()
}
catch {
    # Error handling: display default model name in orange
    $errorModel = "Claude"
    $orangeColor = "$([char]27)[38;5;208m"
    $bold = "$([char]27)[1m"
    $reset = "$([char]27)[0m"

    $outputText = "$orangeColor$bold$errorModel$reset"
    [System.Console]::Write($outputText)
    [System.Console]::Out.Flush()
}

exit 0
