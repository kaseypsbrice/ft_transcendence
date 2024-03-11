(function () {
let game = "";
let in_game = false;
window.onMessage = function(msg)
{
	switch (msg.type)
	{
		case "NoTournament":
			in_game = false;
			clearPage();
			document.getElementById('tn-title').textContent = "You are not in a tournament!";
			break;
		case "TournamentInfo":
			if (msg.data == null || msg.data.status == null || msg.data.status == "error" || 
			!msg.data.game || !msg.data.matches)
			{
				in_game = false;
				clearPage();
				document.getElementById('tn-title').textContent = "You are not in a tournament!";
				break;
			}
			if (msg.data.in_game != null)
				in_game = msg.data.in_game;
			clearPage();
			let t_hash = msg.data;
			game = t_hash.game
			document.getElementById('tn-title').textContent = `${game} TOURNAMENT`.toUpperCase();
			for (let i = 0; i < t_hash.matches.length; i++)
			{
				let match = t_hash.matches[i];
				document.getElementById(`tn-player-${i * 2 + 1}`).textContent = match.player1;
				document.getElementById(`tn-player-${i * 2 + 2}`).textContent = match.player2;
			}
			break;
		case "TournamentMatchStarted":
			document.getElementById('tn-join-game').style.display = '';
			in_game = true;
			game = msg.game;
			sendWithToken(ws, {type:"get_tournament_info"});
			break;
	}
};

window.joinGame = function ()
{
	if (game.length < 1)
		return;
		window.location.hash = game;
}

function clearPage()
{
	if (in_game)
		document.getElementById('tn-join-game').style.display = '';
	else
		document.getElementById('tn-join-game').style.display = 'none';
	document.getElementById('tn-title').textContent = "";
	for (let i = 1; i <= 6; i++)
	{
		document.getElementById(`tn-player-${i}`).textContent = "";
	}
}

window.onOpen = function()
{
	clearPage();
	sendWithToken(ws, {type:"get_tournament_info"});
};

if (ws.readyState == ws.OPEN)
{
	onOpen(null);
}
else
{
	clearPage();
}

})();