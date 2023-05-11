#!/bin/bash
# FOR LINUX, based off of setup.bat
# go to https://haxe.org/download/linux/ to install the latest version of Haxe
# you may or may not need to run "haxelib setup"
# you may also need to run "chmod +x setup" to mark this file as an executable
haxelib install hxcpp > nul
haxelib install lime 8.0.0
haxelib install openfl 9.2.0
haxelib install flixel 4.11.0
haxelib install flixel-tools
haxelib install flixel-ui
haxelib install flixel-addons 2.11.0
haxelib install hxjsonast
haxelib install hscript
haxelib install hxcpp-debug-server
haxelib git polymod https://github.com/larsiusprime/polymod.git
haxelib git linc_luajit https://github.com/nebulazorua/linc_luajit
haxelib git hscript-ex https://github.com/ianharrigan/hscript-ex
haxelib git SScript https://github.com/TheWorldMachinima/SScript
haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc
haxelib install hxCodec 2.5.1
haxelib run flixel-tools setup
haxelib run lime setup flixel
haxelib run lime setup