(function() { // ecapsulate variables in function, globals can be edited with 'window.'
const canvas = document.getElementById('game-canvas')
const ctx = canvas.getContext('2d');
const scaleX = canvas.width / 10;
const scaleY = canvas.height / 10;
const RIGHT = 0;
const DOWN = 1;
const LEFT = 2;
const UP = 3;
const TILE = 20;

let player_id = -1;
let opponent = "";
let snakes = [];
let mouse_pos = {x: 0.0, y: 0.0};
let state = "connecting";
let menu_text = "";

let in_tournament = false;

let gameState = {
	snakes: [],
	food: []
}

let menu_buttons = [
	{
		pos: {x: canvas.width * 0.35, y: canvas.height * 0.8},
		size: {x: canvas.width * 0.3, y: canvas.height * 0.1},
		color: "darkcyan",
		color_hover: "darkslategray",
		on_click: start_game,
		textBox: {
			text: "Find Game",
			color: "white",
			font: "24px Arial",
			pos: {x: canvas.width * 0.15, y: 8 + canvas.height * 0.05},
			align: "center"
		}
	},
	{
		on_click: find_tournament,
		pos: {x: canvas.width * 0.35, y: canvas.height * 0.65},
		size: {x: canvas.width * 0.3, y: canvas.height * 0.1},
		color: "darkcyan",
		color_hover: "darkslategray",
		textBox: {
			text: "Find Tournament",
			color: "white",
			font: "24px Arial",
			pos: {x: canvas.width * 0.15, y: 8 + canvas.height * 0.05},
			align: "center"
		}
	}
];

let menu_buttons_tournament = [
	{
		on_click: leave_tournament,
		pos: {x: canvas.width * 0.35, y: canvas.height * 0.65},
		size: {x: canvas.width * 0.3, y: canvas.height * 0.1},
		color: "darkcyan",
		color_hover: "darkslategray",
		textBox: {
			text: "Leave Tournament",
			color: "white",
			font: "24px Arial",
			pos: {x: canvas.width * 0.15, y: 8 + canvas.height * 0.05},
			align: "center"
		}
	}
];

let victory_buttons = [
	{
		pos: {x: canvas.width * 0.35, y: canvas.height * 0.8},
		size: {x: canvas.width * 0.3, y: canvas.height * 0.1},
		color: "darkcyan",
		color_hover: "darkslategray",
		on_click: function() {onOpen()},
		textBox: {
			text: "OK",
			color: "white",
			font: "24px Arial",
			pos: {x: canvas.width * 0.15, y: 8 + canvas.height * 0.05},
			align: "center"
		}
	}
]

let defeat_buttons = [
	{
		pos: {x: canvas.width * 0.35, y: canvas.height * 0.8},
		size: {x: canvas.width * 0.3, y: canvas.height * 0.1},
		color: "darkcyan",
		color_hover: "darkslategray",
		on_click: function() {onOpen()},
		textBox: {
			text: "OK",
			color: "white",
			font: "24px Arial",
			pos: {x: canvas.width * 0.15, y: 8 + canvas.height * 0.05},
			align: "center"
		}
	}
]

let logged_out_buttons = [
	{
		pos: {x: canvas.width * 0.35, y: canvas.height * 0.8},
		size: {x: canvas.width * 0.3, y: canvas.height * 0.1},
		color: "darkcyan",
		color_hover: "darkslategray",
		on_click: function() {window.location.hash = "#login"},
		textBox: {
			text: "Login",
			color: "white",
			font: "24px Arial",
			pos: {x: canvas.width * 0.15, y: 8 + canvas.height * 0.05},
			align: "center"
		}
	}
]

let button_map = {
	menu: menu_buttons,
	victory: victory_buttons,
	defeat: defeat_buttons,
	logged_out: logged_out_buttons
}

let options = {
	option_1: false
};

function start_game()
{
	state = "searching";
	sendWithToken(ws, {type: "find_snake"});
}

function find_tournament()
{
	state = "waiting_server";
	sendWithToken(ws, {type: "find_tournament", game: "snake"});
	sendWithToken(ws, {type: "get_game_status", game: "snake"});
}

function leave_tournament()
{
	state = "waiting_server"
	sendWithToken(ws, {type: "leave_tournament"});
}

function getMousePos(event)
{
	var rect = canvas.getBoundingClientRect();
	return {
		x: event.clientX - rect.left,
		y: event.clientY - rect.top
	};
}

function mouseInRect(x, y, width, height)
{
	if (mouse_pos.x >= x && mouse_pos.x <= x + width &&
	    mouse_pos.y >= y && mouse_pos.y <= y + height)
		return true;
	return false;
}

function drawTile(x, y, color)
{
	ctx.fillStyle = color;
	ctx.fillRect(x * TILE + 1, y * TILE + 1, TILE - 2, TILE - 2);
}

function drawSnakes(snakes)
{
	for (s in snakes)
	{
		let snake = snakes[s];
		let i = 0;
		while (i < snake.length - 1)
		{
			drawTile(snake[i], snake[i + 1], "white");
			i += 2;
		}
	}
}

function drawFood(food)
{
	let i = 0;
	while (i < food.length - 1)
	{
		drawTile(food[i], food[i + 1], "yellow");
		i += 2;
	}
}

function updateGame(data)
{   
	ctx.clearRect(0, 0, canvas.width, canvas.height);

	gameState.snakes = data.snakes;
	gameState.food = data.food;

	drawFood(gameState.food);
    drawSnakes(gameState.snakes);
	ctx.fillStyle = "white";
	ctx.font = "16px Arial";
	ctx.textAlign = "center";
	ctx.fillText(`Opponent: ${opponent}`, canvas.width / 2, 12);
}

function drawButtons()
{
	let buttons = button_map[state] != null ? button_map[state] : []
	if (state == "menu" && in_tournament)
		buttons = menu_buttons_tournament;
	for (i in buttons)
	{
		let button = buttons[i];
		if (button.option == null)
		{
			if (mouseInRect(button.pos.x, button.pos.y, button.size.x, button.size.y))
				ctx.fillStyle = button.color_hover;
			else
				ctx.fillStyle = button.color;
		}
		else
		{
			if (mouseInRect(button.pos.x, button.pos.y, button.size.x, button.size.y))
			{
				if (options[button.option])
					ctx.fillStyle = button.color_hover_selected;
				else
					ctx.fillStyle = button.color_hover;
			}
			else
			{
				if (options[button.option])
					ctx.fillStyle = button.color_selected;
				else
					ctx.fillStyle = button.color;
			}
		}
		ctx.fillRect(button.pos.x, button.pos.y, button.size.x, button.size.y);
		if (button.textBox != null)
		{
			ctx.fillStyle = button.textBox.color;
			ctx.font = button.textBox.font;
			ctx.textAlign = button.textBox.align;
			ctx.fillText(button.textBox.text, button.pos.x + button.textBox.pos.x, button.pos.y + button.textBox.pos.y);
		}
	}
}

function updateMenu() 
{
	ctx.clearRect(0, 0, canvas.width, canvas.height);
	ctx.fillStyle = "white";
	ctx.font = "24px Arial";
	ctx.textAlign = "center";
	ctx.fillText("Snake!", canvas.width / 2, 28);
	ctx.font = "16px Arial";
	ctx.fillText(menu_text, canvas.width / 2, 50);

	drawButtons();
}

function updateSearching()
{
	ctx.clearRect(0, 0, canvas.width, canvas.height);

	ctx.fillStyle = "white";
	ctx.textAlign = "center";
	ctx.font = "48px Arial";
	ctx.fillText("Searching for opponent...", canvas.width / 2, canvas.height / 2);
}

function updateConnecting()
{
	ctx.clearRect(0, 0, canvas.width, canvas.height);

	ctx.fillStyle = "white";
	ctx.textAlign = "center";
	ctx.font = "48px Arial";
	ctx.fillText("Connecting to server...", canvas.width / 2, canvas.height / 2);
}

function updateWaitingServer()
{
	ctx.clearRect(0, 0, canvas.width, canvas.height);

	ctx.fillStyle = "white";
	ctx.textAlign = "center";
	ctx.font = "48px Arial";
	ctx.fillText("Waiting for server response...", canvas.width / 2, canvas.height / 2);
}

function updateWaitingPartner()
{
	ctx.clearRect(0, 0, canvas.width, canvas.height);

	ctx.fillStyle = "white";
	ctx.textAlign = "center";
	ctx.font = "48px Arial";
	ctx.fillText("Waiting partner to connect...", canvas.width / 2, canvas.height / 2);
}

function updateDisconnected()
{
	ctx.clearRect(0, 0, canvas.width, canvas.height);

	ctx.fillStyle = "white";
	ctx.textAlign = "center";
	ctx.font = "32px Arial";
	ctx.fillText("Could not connect to server, try again later...", canvas.width / 2, canvas.height / 2);
}

function updateVictory()
{
	ctx.clearRect(0, 0, canvas.width, canvas.height);

	ctx.fillStyle = "green";
	ctx.textAlign = "center";
	ctx.font = "64px Arial";
	ctx.fillText("Victory!", canvas.width / 2, canvas.height / 3);

	drawButtons();
}

function updateDefeat()
{
	ctx.clearRect(0, 0, canvas.width, canvas.height);

	ctx.fillStyle = "red";
	ctx.textAlign = "center";
	ctx.font = "64px Arial";
	ctx.fillText("Defeat!", canvas.width / 2, canvas.height / 3);

	drawButtons();
}

function updateLoggedOut()
{
	ctx.clearRect(0, 0, canvas.width, canvas.height);

	ctx.fillStyle = "white";
	ctx.textAlign = "center";
	ctx.font = "32px Arial";
	ctx.fillText("You are not logged in, log in at URL/login", canvas.width / 2, canvas.height / 2);

	drawButtons();
}

window.onMessage = function(msg) 
{
	console.log("snake on message")
	switch (msg.type)
	{
		case "state":
			if (msg.data.winner != null)
			{
				if (msg.data.winner == player_id)
				{
					menu_text = "";
					state = "victory";
				}
				else
				{
					menu_text = "";
					state = "defeat";
				}
				break;
			}
			gameState = msg.data;
			updateGame(msg.data);
			break;
		case "game_found":
			console.log("game found");
			if (msg.data != null && msg.data.game == "snake" && msg.data.player_id != null)
			{
				player_id = msg.data.player_id;
				state = "game";
				console.log("player_id: ", player_id);
				if (msg.data.opponent != null)
					opponent = msg.data.opponent
				else
					opponent = "";
			}
			break;
		case "partner_disconnected":
			menu_text = "Victory: opponent disconnected"
			state = "menu";
			break;
		case "game_status":
			if (msg.data.status == "WaitingPartner")
			{
				in_tournament = true;
				state = "waiting_partner";
			}
			else
			{
				in_tournament = false;
				state = "menu";
				menu_text = "";
			}
			if (msg.data.status == "FoundTournament")
			{
				in_tournament = true;
				menu_text = "Searching for tournament players"
			}
			break;
		case "TournamentMatchStarted":
			if (state != "game" && state != "victory" && state != "defeat")
				sendWithToken(ws, {type: "get_game_status", game: "snake"});
			break;
	}
}

function handleKeyDown(event)
{
	if (player_id < 0)
		return;
	if (event.key === 'ArrowUp') sendWithToken(ws, {type: "change_direction", direction: UP});
	if (event.key === 'ArrowDown') sendWithToken(ws, {type: "change_direction", direction: DOWN});
	if (event.key === 'ArrowLeft') sendWithToken(ws, {type: "change_direction", direction: LEFT});
	if (event.key === 'ArrowRight') sendWithToken(ws, {type: "change_direction", direction: RIGHT});
}
document.addEventListener('keydown', handleKeyDown);

function handleMouseMove(event)
{
	mouse_pos = getMousePos(event);
}
document.addEventListener('mousemove', handleMouseMove);

function handleMouseClick(event)
{
	let buttons = button_map[state] != null ? button_map[state] : []
	if (state == "menu" && in_tournament)
		buttons = menu_buttons_tournament;
	for (i in buttons)
	{
		let button = buttons[i];
		if (mouseInRect(button.pos.x, button.pos.y, button.size.x, button.size.y))
		{
			if (button.on_click != null)
				button.on_click();
			else if (button.option != null)
				options[button.option] = !options[button.option];
		}
	}
}
document.addEventListener('click', handleMouseClick);

window.cleanupPage = function() {
	ws.close();
	document.removeEventListener('keydown', handleKeyDown);
	document.removeEventListener('mousemove', handleMouseMove);
	document.removeEventListener('click', handleMouseClick);
}

function gameLoop() {
	if (!is_logged_in() && (state == "game"))
	{
		state = "logged_out";
	}
	switch (state)
	{
		case "menu":
			updateMenu(); break;
		case "searching":
			updateSearching(); break;
		case "game":
			updateGame(gameState); break;
		case "connecting":
			updateConnecting(); break;
		case "disconnected":
			updateDisconnected(); break;
		case "victory":
			updateVictory(); break;
		case "defeat":
			updateDefeat(); break;
		case "logged_out":
			updateLoggedOut(); break;
		case "waiting_server":
			updateWaitingServer(); break;
		case "waiting_partner":
			updateWaitingPartner(); break;

	}
	requestAnimationFrame(gameLoop);
}

// websocket.js overloads
window.onLogout = function()
{
	state = "logged_out";
}

window.onLogin = function()
{
	state = "menu";
}

window.onOpen = function()
{
	console.log("snake on open")
	state = "waiting_server"
	sendWithToken(ws, {type:"get_game_status", game: "snake"});
}

window.onClose = function()
{
	state = "disconnected"
}

// initalize game state
switch(ws.readyState)
{
	case ws.CONNECTING:
		state = "connecting"; break;
	case ws.OPEN:
		onOpen(null); break;
	case ws.CLOSING:
	case ws.CLOSED:
		onClose(null); break;
}

//start the game loop
requestAnimationFrame(gameLoop);
})();
