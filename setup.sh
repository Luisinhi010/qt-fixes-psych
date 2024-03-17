#!/bin/bash
# FOR LINUX, based off of setup.bat
# go to https://haxe.org/download/linux/ to install the latest version of Haxe
# you may or may not need to run "haxelib setup"
# you may also need to run "chmod +x setup" to mark this file as an executable
haxelib install hxcpp > nul
haxelib install lime
haxelib install openfl
haxelib install flixel
haxelib git cne-flixel https://github.com/FNF-CNE-Devs/flixel
haxelib install flixel-tools
haxelib install flixel-ui
haxelib install flixel-addons
haxelib git cne-flixel-addons https://github.com/FNF-CNE-Devs/flixel-addons
haxelib install hxjsonast
haxelib install hscript
haxelib install hxcpp-debug-server
haxelib git polymod https://github.com/larsiusprime/polymod.git
haxelib git linc_luajit https://github.com/nebulazorua/linc_luajit
haxelib git hscript-ex https://github.com/ianharrigan/hscript-ex
haxelib install SScript 3.0.0
haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc
haxelib install hxCodec 2.5.1
haxelib run flixel-tools setup
haxelib run lime setup flixel
haxelib run lime setup