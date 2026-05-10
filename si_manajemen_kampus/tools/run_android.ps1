$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$flutterExe = "D:\Flutter\flutter_SDK\flutter\bin\flutter.bat"
$androidSdk = "D:\Flutter\Android_SDK"
$javaHome = "C:\Program Files\Android\Android Studio\jbr"
$gradleLock = Join-Path $env:USERPROFILE ".gradle\wrapper\dists\gradle-8.10.2-all\7iv73wktx1xtkvlq19urqw1wm\gradle-8.10.2-all.zip.lck"

if (!(Test-Path $flutterExe)) {
  throw "Flutter tidak ditemukan di $flutterExe"
}

if (!(Test-Path $androidSdk)) {
  throw "Android SDK tidak ditemukan di $androidSdk"
}

if (!(Test-Path $javaHome)) {
  throw "JDK Android Studio tidak ditemukan di $javaHome"
}

$env:JAVA_HOME = $javaHome
$env:ANDROID_SDK_ROOT = $androidSdk
$env:ANDROID_HOME = $androidSdk
$env:Path = "$androidSdk\platform-tools;$javaHome\bin;$env:Path"

if (Test-Path $gradleLock) {
  Remove-Item -LiteralPath $gradleLock -Force -ErrorAction SilentlyContinue
}

Push-Location $projectRoot
try {
  & $flutterExe clean
  & $flutterExe pub get
  & $flutterExe run -d emulator-5554
} finally {
  Pop-Location
}
