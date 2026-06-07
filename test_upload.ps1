
$filePath = "test_image.txt"
"test content" | Out-File $filePath
$url = "http://192.168.11.171:8000/api/v1/upload/"

try {
    $response = curl.exe -X POST -F "images=@$filePath" $url
    Write-Output "Response: $response"
} catch {
    Write-Output "Error: $_"
}
finally {
    Remove-Item $filePath
}
