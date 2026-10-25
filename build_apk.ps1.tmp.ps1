$env:PUB_CACHE = "$env:USERPROFILE\AppData\Local\Pub\Cache"
Set-Location "C:\Users\Code-D\OneDrive\Desktop\DEV\Flutter\GrowWithMe\mobile"
flutter build apk --release *>&1 | Out-File -FilePath "C:\Users\Code-D\AppData\Local\Temp\opencode\apk-build.log" -Encoding UTF8
"BUILD EXIT: $LASTEXITCODE" | Out-File -FilePath "C:\Users\Code-D\AppData\Local\Temp\opencode\apk-build.done" -Encoding UTF8
