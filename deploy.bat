@echo off
echo ========================================
echo Bluestar POS - Firebase Deployment Script
echo ========================================
echo.

echo Step 1: Cleaning previous builds...
if exist build\web rmdir /s /q build\web
echo Previous builds cleaned.
echo.

echo Step 2: Building Flutter web app for production...
flutter build web --release --no-tree-shake-icons
if %ERRORLEVEL% neq 0 (
    echo Error: Flutter build failed!
    pause
    exit /b 1
)
echo Flutter web build completed successfully.
echo.

echo Step 3: Optimizing build for Firebase...
REM Add any additional optimization steps here if needed
echo Build optimization completed.
echo.

echo Step 4: Deploying to Firebase Hosting...
firebase deploy --only hosting
if %ERRORLEVEL% neq 0 (
    echo Error: Firebase deployment failed!
    echo Make sure you are logged in: firebase login
    pause
    exit /b 1
)
echo.

echo ========================================
echo Deployment completed successfully!
echo ========================================
echo.
echo Your POS system is now live at:
echo https://cateyepos.web.app
echo.
echo Admin Panel: https://cateyepos.web.app
echo Kiosk Mode: https://cateyepos.web.app/kiosk
echo Booking System: https://cateyepos.web.app/booking
echo.
pause