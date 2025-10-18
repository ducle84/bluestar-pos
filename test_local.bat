@echo off
echo =======================================
echo CatEye POS - Local Testing Script
echo =======================================
echo.

echo Building Flutter web app for testing...
flutter build web --release --no-tree-shake-icons

if %ERRORLEVEL% neq 0 (
    echo Error: Flutter build failed!
    pause
    exit /b 1
)

echo.
echo Starting local web server...
echo.
echo Your app will be available at:
echo http://localhost:8080
echo.
echo Press Ctrl+C to stop the server
echo.

cd build\web
python -m http.server 8080 2>nul || (
    echo Python not found, trying alternative...
    php -S localhost:8080 2>nul || (
        echo Starting with Flutter...
        flutter run -d web-server --web-port=8080
    )
)

pause