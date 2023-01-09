--[[
Functions explained in a nutshell:

Hello and welcome to v2.2!
You can now use custom pincers using Lua!
If you want to use the other QT events, just use event arrows. They're more reliable and easier to use.
If you really want to use them in Lua though, you can use the 'triggerEvent' function (example: 'triggerEvent("KB_Alert",4)' will do the quadruple alert).


Here's how you use the pincers:

qtMod_PincerPrepare(pincerID:Int, goAway:Bool)
Use this function to prepare a pincer. 'pincerID' refers to which pincer to use (from 1-4). 'goAway' makes the pincer leave if set to true.

qtMod_PincerGrab(pincerID:Int)
This function is used to change the pincer sprite to look like it's grabbing a note. It's purely visual.

qtMod_PincerTweenX(tweenName:String, pincerID:Int, xPosition:Float, time:Float, Ease)
qtMod_PincerTweenY(tweenName:String, pincerID:Int, yPosition:Float, time:Float, Ease)
These above functions are used to tween the pincers X and Y position around the screen.
See below for an example of how to use the pincers.

--]]

function onBeatHit()	
	--Pincer shit. 	
	if difficulty > 0 then	 --To disable pincers for easy difficulty
		if curBeat == 16 then
			qtMod_PincerPrepare(1,false)
		elseif curBeat == 18 then
			qtMod_PincerPrepare(4,false)
		elseif curBeat == 20 then
			qtMod_PincerGrab(1)
			if downscroll then
				qtMod_PincerTweenY("NoteMovePincer1",1,defaultPlayerStrumY0-55,0.5, quadinout)
				noteTweenY("NoteMove1",4,defaultPlayerStrumY0-55,0.5, quadinout)
			else
				qtMod_PincerTweenY("NoteMovePincer1",1,defaultPlayerStrumY0+55,0.5, quadinout)
				noteTweenY("NoteMove1",4,defaultPlayerStrumY0+55,0.5, quadinout)
			end
		elseif curBeat == 22 then
			qtMod_PincerGrab(4)
			
			if downscroll then
				qtMod_PincerTweenY("NoteMovePincer2Y",4,defaultPlayerStrumY3-55,0.5, quadinout)
				noteTweenY("NoteMove2Y",7,defaultPlayerStrumY3-55,0.5, quadinout)
			else
				qtMod_PincerTweenY("NoteMovePincer2Y",4,defaultPlayerStrumY3+55,0.5, quadinout)
				noteTweenY("NoteMove2Y",7,defaultPlayerStrumY3+55,0.5, quadinout)
			end
			
			qtMod_PincerTweenX("NoteMovePincer2X",4,defaultPlayerStrumX3+75,0.5, quadinout)
			noteTweenX("NoteMove2X",7,defaultPlayerStrumX3+75,0.5, quadinout)
		elseif curBeat == 24 then
			qtMod_PincerPrepare(4,true)
			qtMod_PincerPrepare(1,true)
			
		elseif curBeat == 32 then
			qtMod_PincerPrepare(3,false)
		elseif curBeat == 34 then
			qtMod_PincerPrepare(2,false)
		elseif curBeat == 36 then
			qtMod_PincerGrab(3)
			if downscroll then
				qtMod_PincerTweenY("NoteMovePincer3",3,defaultPlayerStrumY2-100,0.5, quadinout)
				noteTweenY("NoteMove3",6,defaultPlayerStrumY2-100,0.5, quadinout)
			else
				qtMod_PincerTweenY("NoteMovePincer3",3,defaultPlayerStrumY2+100,0.5, quadinout)
				noteTweenY("NoteMove3",6,defaultPlayerStrumY2+100,0.5, quadinout)
			end
		elseif curBeat == 38 then
			qtMod_PincerGrab(2)
			if downscroll then
				qtMod_PincerTweenY("NoteMovePincer4",2,defaultPlayerStrumY1+60,0.5, quadinout)
				noteTweenY("NoteMove4",5,defaultPlayerStrumY1+60,0.5, quadinout)
			else
				qtMod_PincerTweenY("NoteMovePincer4",2,defaultPlayerStrumY1-60,0.5, quadinout)
				noteTweenY("NoteMove4",5,defaultPlayerStrumY1-60,0.5, quadinout)
			end
		elseif curBeat == 40 then
			qtMod_PincerPrepare(2,true)
			qtMod_PincerPrepare(3,true)
			
		--Pincers don't reset strums for troll if on harder difficulty
		elseif curBeat == 92 and difficulty ~= 3 then
			qtMod_PincerPrepare(3,false)
		elseif curBeat == 93 and difficulty ~= 3 then
			qtMod_PincerPrepare(4,false)
		elseif curBeat == 94 and difficulty ~= 3 then
			qtMod_PincerPrepare(1,false)
		elseif curBeat == 95 and difficulty ~= 3 then
			qtMod_PincerPrepare(2,false)
		elseif curBeat == 96 and difficulty ~= 3 then
			qtMod_PincerGrab(4)
			qtMod_PincerGrab(3)
			qtMod_PincerGrab(2)
			qtMod_PincerGrab(1)

			qtMod_PincerTweenX("NoteMovePincerReset1X",1,defaultPlayerStrumX0,1, quadinout)
			noteTweenX("NoteMoveReset1X",4,defaultPlayerStrumX0,1, quadinout)
			qtMod_PincerTweenY("NoteMovePincerReset1Y",1,defaultPlayerStrumY0,1, quadinout)
			noteTweenY("NoteMoveReset1Y",4,defaultPlayerStrumY0,1, quadinout)
			
			qtMod_PincerTweenX("NoteMovePincerReset2X",2,defaultPlayerStrumX1,1, quadinout)
			noteTweenX("NoteMoveReset2X",5,defaultPlayerStrumX1,1, quadinout)
			qtMod_PincerTweenY("NoteMovePincerReset2Y",2,defaultPlayerStrumY1,1, quadinout)
			noteTweenY("NoteMoveReset2Y",5,defaultPlayerStrumY1,1, quadinout)
			
			qtMod_PincerTweenX("NoteMovePincerReset3X",3,defaultPlayerStrumX2,1, quadinout)
			noteTweenX("NoteMoveReset3X",6,defaultPlayerStrumX2,1, quadinout)
			qtMod_PincerTweenY("NoteMovePincerReset3Y",3,defaultPlayerStrumY2,1, quadinout)
			noteTweenY("NoteMoveReset3Y",6,defaultPlayerStrumY2,1, quadinout)
			
			qtMod_PincerTweenX("NoteMovePincerReset4X",4,defaultPlayerStrumX3,1, quadinout)
			noteTweenX("NoteMoveReset4X",7,defaultPlayerStrumX3,1, quadinout)
			qtMod_PincerTweenY("NoteMovePincerReset4Y",4,defaultPlayerStrumY3,1, quadinout)
			noteTweenY("NoteMoveReset4Y",7,defaultPlayerStrumY3,1, quadinout)
			
		elseif curBeat == 99 and difficulty ~= 3 then
			qtMod_PincerPrepare(4,true)
			qtMod_PincerPrepare(3,true)
			qtMod_PincerPrepare(2,true)
			qtMod_PincerPrepare(1,true)
		end
	end
end

function onCreate() 
	--if downscroll then
	--	debugPrint("Downscroll enabled")
	--else
	--	debugPrint("Downscroll disabled")
	--end
end