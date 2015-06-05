hook.Add('Initialize','Statistics_Tracking_Spacebuild', function()
	http.Post('http://catbox.moe/spacebuild/tracking.php', {
		port = GetConVarString('hostport'),
		hostname = GetHostName()
	})
end)