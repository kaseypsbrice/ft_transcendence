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
		case "game_status":
			if (msg.data == null || msg.data.status == null || msg.data.status == "error" || 
			!msg.data.game || !msg.data.matches || !msg.data.players)
			{
				in_game = false;
				clearPage();
				document.getElementById('tn-title').textContent = "You are not in a tournament!";
				break;
			}
			switch (msg.data.status)
			{
				case "NotFull":
					in_game = false;
					clearPage();
					document.getElementById('tn-title').textContent = `${msg.data.game.toUpperCase()} WAITING FOR PLAYERS...`;
					for (let i = 0; i < msg.data.players.length; i++)
					{
						let player = msg.data.players[i];
						document.getElementById(`tn-player-${i + 1}`).textContent = player;
					}
					break;
				case "Full":
					in_game = false;
					clearPage();
					document.getElementById('tn-title').textContent = `${msg.data.game.toUpperCase()} TOURNAMENT`;
					for (let i = 0; i < msg.data.matches.length; i++)
					{
						let match = msg.data.matches[i];
						document.getElementById(`tn-player-${i * 2 + 1}`).textContent = match.player1;
						document.getElementById(`tn-player-${i * 2 + 2}`).textContent = match.player2;
					}
					break;
				case "MatchReady":
					in_game = true;
					clearPage();
					document.getElementById('tn-title').textContent = `${msg.data.game.toUpperCase()} TOURNAMENT`;
					for (let i = 0; i < msg.data.matches.length; i++)
					{
						let match = msg.data.matches[i];
						document.getElementById(`tn-player-${i * 2 + 1}`).textContent = match.player1;
						document.getElementById(`tn-player-${i * 2 + 2}`).textContent = match.player2;
					}
					break;
			}
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