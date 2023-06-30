@echo off
title Friday Night Funkin': Psych Engine Setup - Start
echo Make sure to have Haxe 4.2.5 and HaxeFlixel 4.11.0 is installed!
echo Press any key to install required libraries.
pause >nul
title Installing libraries
echo Installing haxelib libraries...
haxelib install hxcpp > nul
haxelib install lime 8.0.0
haxelib install openfl 9.2.0
haxelib install flixel 4.11.0
haxelib run lime setup flixel
haxelib run lime setup
haxelib install flixel-tools
haxelib install flixel-ui
haxelib install flixel-addons 2.11.0
haxelib install hxjsonast
haxelib install hscript
haxelib install hxcpp-debug-server
title User action required
cls
haxelib run flixel-tools setup
cls
echo Make sure you have git installed. You can download it here: https://git-scm.com/downloads
echo Press any key to install dependencies.
pause >nul
title Installing libraries
haxelib git polymod https://github.com/larsiusprime/polymod.git
haxelib git linc_luajit https://github.com/nebulazorua/linc_luajit
haxelib git hscript-ex https://github.com/ianharrigan/hscript-ex
haxelib install SScript 3.0.0
haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc
haxelib install hxCodec 2.5.1
cls
goto InstallVSCommunity

:InstallVSCommunity
title Installing Visual Studio Community
curl -# -O https://download.visualstudio.microsoft.com/download/pr/3105fcfe-e771-41d6-9a1c-fc971e7d03a7/8eb13958dc429a6e6f7e0d6704d43a55f18d02a253608351b6bf6723ffdaf24e/vs_Community.exe
vs_Community.exe --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.19041 -p
del vs_Community.exe
goto SkipVSCommunity
