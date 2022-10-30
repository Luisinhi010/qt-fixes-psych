--[[
function onUpdate(elapsed)

	songPos = getSongPosition()
	local currentBeat = (songPos / 1000) * (bpm / 60)
	if curBeat >= 704 and curBeat < 832 then
		noteTweenX(defaultPlayerStrumX0, 4, defaultPlayerStrumX0 - 80 * math.sin((currentBeat + 4 * 0.25) * math.pi), 0.6)
		noteTweenX(defaultPlayerStrumX1, 5, defaultPlayerStrumX1 - 80 * math.sin((currentBeat + 5 * 0.25) * math.pi), 0.6)
		noteTweenX(defaultPlayerStrumX2, 6, defaultPlayerStrumX2 - 80 * math.sin((currentBeat + 6 * 0.25) * math.pi), 0.6)
		noteTweenX(defaultPlayerStrumX3, 7, defaultPlayerStrumX3 - 80 * math.sin((currentBeat + 7 * 0.25) * math.pi), 0.6)
	elseif curBeat >= 896 and curBeat < 960 then
		noteTweenX(defaultPlayerStrumX0, 4, defaultPlayerStrumX0 - 70 * math.sin((currentBeat + 4 * 0.25) * math.pi), 0.7)
		noteTweenX(defaultPlayerStrumX1, 5, defaultPlayerStrumX1 - 70 * math.sin((currentBeat + 5 * 0.25) * math.pi), 0.7)
		noteTweenX(defaultPlayerStrumX2, 6, defaultPlayerStrumX2 - 70 * math.sin((currentBeat + 6 * 0.25) * math.pi), 0.7)
		noteTweenX(defaultPlayerStrumX3, 7, defaultPlayerStrumX3 - 70 * math.sin((currentBeat + 7 * 0.25) * math.pi), 0.7) --idk how psych enigne lua works, i take these from Vs FNAF 1 mod (i recommend to you to check it btw)
	else
		noteTweenX(defaultPlayerStrumX0, 4, defaultPlayerStrumX0, 0.01)
		noteTweenX(defaultPlayerStrumX1, 5, defaultPlayerStrumX1, 0.01)
		noteTweenX(defaultPlayerStrumX2, 6, defaultPlayerStrumX2, 0.01)
		noteTweenX(defaultPlayerStrumX3, 7, defaultPlayerStrumX2 + 110, 0.001) --i want to die srs
	end

end
--]] --i want to die because of this, i will port the kade's modchart support fuck you -Luis
--this is all your fault for not learning Pysch engine Lua -Future Luis
