@echo off
color 0a
cd ..
echo BUILDING GAME
lhaxelib run lime build windows -release
echo.
echo done.
pause
pwd
explorer.exe export\release\windows\bin