(function () {
let game = "";
let in_game = false;
window.onMessage = function(msg)
{
	switch (msg.type)
	{
		case "NoTournament":
			in_game = false;
			game = "";
			clearPage();
			document.getElementById('tn-title').textContent = "You are not in a tournament!";
			break;
		case "game_status":
			if (msg.data == null || msg.data.status == null || msg.data.status == "error" || 
			!msg.data.game || !msg.data.matches || !msg.data.players)
			{
				in_game = false;
				game = "";
				clearPage();
				document.getElementById('tn-title').textContent = "You are not in a tournament!";
				break;
			}
			game = msg.data.game;
			console.log("in game status")
			console.log(msg.data.status)
			switch (msg.data.status)
			{
				case "NotFull":
					in_game = false;
					setPlayers(msg);
					break;
				case "Full":
					in_game = false;
					setMatches(msg);
					break;
				case "MatchReady":
					in_game = true;
					setMatches(msg);
					break;
			}
			break;
	}
};

function setPlayers(msg)
{
	clearPage();
	document.getElementById('tn-title').textContent = `${msg.data.game.toUpperCase()} WAITING FOR PLAYERS...`;
	console.log(msg.data.players)
	for (let i = 0; i < msg.data.players.length; i++)
	{
		console.log(i);
		let player = msg.data.players[i];
		console.log(player)
		document.getElementById(`tn-player-${i + 1}`).textContent = player;
		setPictureDisplayName(document.getElementById(`tn-player-pic-${i + 1}`), player);
		let cachedData = localStorage.getItem(player);
		if (!cachedData)
			sendWithToken(ws, {type: "get_profile_picture", display_name: player, timestamp: "0"});
		else
		{
			let cachedJSON = JSON.parse(cachedData);
			sendWithToken(ws, {type: "get_profile_picture", display_name: player, timestamp: cachedJSON.timestamp});
		}
	}
}

function setMatches(msg)
{
	clearPage();
	document.getElementById('tn-title').textContent = `${msg.data.game.toUpperCase()} TOURNAMENT`;
	for (let i = 0; i < msg.data.matches.length; i++)
	{
		let match = msg.data.matches[i];
		document.getElementById(`tn-player-${i * 2 + 1}`).textContent = match.player1;
		document.getElementById(`tn-player-${i * 2 + 2}`).textContent = match.player2;
		setPictureDisplayName(document.getElementById(`tn-player-pic-${i * 2 + 1}`), match.player1);
		setPictureDisplayName(document.getElementById(`tn-player-pic-${i * 2 + 2}`), match.player2);
		let cachedData1 = localStorage.getItem(match.player1);
		let cachedData2 = localStorage.getItem(match.player2);

		if (!cachedData1)
			sendWithToken(ws, {type: "get_profile_picture", display_name: match.player1, timestamp: "0"});
		else
		{
			let cachedJSON = JSON.parse(cachedData1);
			sendWithToken(ws, {type: "get_profile_picture", display_name: match.player1, timestamp: cachedJSON.timestamp});
		}

		if (!cachedData2)
			sendWithToken(ws, {type: "get_profile_picture", display_name: match.player2, timestamp: "0"});
		else
		{
			let cachedJSON = JSON.parse(cachedData2);
			sendWithToken(ws, {type: "get_profile_picture", display_name: match.player2, timestamp: cachedJSON.timestamp});
		}
	}
}

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
		setPictureDisplayName(document.getElementById(`tn-player-pic-${i}`), "");
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