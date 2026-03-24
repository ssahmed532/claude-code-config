#Requires -Version 5.1

param()

# Set PowerShell output encoding to UTF-8 to ensure correct ANSI color handling
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ANSI escape codes
# Define ANSI color codes
#$reset = "\x1b[0m"
$red = "\x1b[31m"
$green = "\x1b[32m"
$yellow = "\x1b[33m"
$blue = "\x1b[34m"
$magenta = "\x1b[35m"
$cyan = "\x1b[36m"
$orange = "`e[38;5;208m"
$reset = "`e[0m"
$dim = "`e[2m"

# Read JSON input from stdin
$jsonInput = ""
try {
    $inputStream = [System.IO.StreamReader]::new([System.Console]::OpenStandardInput())
    $jsonInput = $inputStream.ReadToEnd()
    $inputStream.Close()
}
catch {
    # Handle error or use default if stdin fails
    $jsonInput = '{"model":{"display_name":"N/A"}, "cost": {"total_cost_usd": 0}, "tokens": {"total": 0}}'
}

try {
    # Parse the JSON data
    $data = ConvertFrom-Json $jsonInput

    # Extract relevant information
    $modelName = $data.model.display_name
    $totalTokens = $data.tokens.total
    $sessionCost = [math]::Round($data.cost.total_cost_usd, 4)
    # Context percentage requires access to current context length which might need the 'ccstatusline' npm package for simplicity (not covered here)
    # The snippet below provides basic model, token, and cost info

    # Format the output using ANSI colors
    $output = "[$($cyan)$modelName$($reset)] Tokens: $($yellow)$totalTokens$($reset) | Cost: $($green)$$sessionCost$($reset)"

    # Print the status line (first line of stdout becomes the status line text)
    Write-Output $output
    #Write-Host $output

    #Write-Output "${orange}${modelName}${reset} ${dim}in${reset} $cwd" -NoNewline

}
catch {
    # Handle JSON parsing errors
    Write-Output "[$($red)Error parsing data$($reset)]"
}
