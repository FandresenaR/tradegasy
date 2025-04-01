@echo off
echo Setting up Git repository for TradeGasy...

:: Initialize Git repository locally
git init

:: Add all files to Git (except those in .gitignore)
git add .

:: Make initial commit
git commit -m "Initial commit of TradeGasy app"

:: Instructions for connecting to GitHub
echo.
echo ======================================================================
echo Repository initialized locally. To connect to GitHub:
echo.
echo 1. Create a new repository on GitHub:
echo    https://github.com/new
echo.
echo 2. Then run these commands to connect and push:
echo    git remote add origin https://github.com/YOUR-USERNAME/tradegasy.git
echo    git branch -M main
echo    git push -u origin main
echo ======================================================================
echo.
echo Setup complete!
pause
