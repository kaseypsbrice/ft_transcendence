
(function() { // ecapsulate variables in function, globals can be edited with 'window.'
let gameState = {
	ball_position: {x: 0, y: 0},
	left_paddle: {y:5},
	right_paddle: {y:5},
	score_left: 0,
	score_right: 0
};

const canvas = document.getElementById('game-canvas')
const ctx = canvas.getContext('2d');

const scaleX = canvas.width / 10;
const scaleY = canvas.height / 10;

let player_id = -1;
let mouse_pos = {x: 0.0, y: 0.0};
let state = "connecting";
let menu_text = "";

let in_tournament = false;
let up_pressed = false;
let down_pressed = false;
let opponent = "";

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
	sendWithToken(ws, {type: "find_pong"});
}

function find_tournament()
{
	state = "waiting_server";
	sendWithToken(ws, {type: "find_tournament", game: "pong"});
	sendWithToken(ws, {type: "get_game_status", game: "pong"});
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

function drawPaddle(position, paddleSide) {
    ctx.fillStyle = '#FFF';
    let xPosition, paddleHeight = 4 * scaleY; // Make sure this matches the PongClass @paddle_height
    if (paddleSide === 'left') {
        xPosition = 20; // Left paddle x position
    } else { // 'right'
        xPosition = canvas.width - 30; // Right paddle x position
    }
    // Adjust the yPosition to draw from the top-left corner of the paddle
    let yPosition = (10 - position.y - 4) * scaleY; // Subtracting 4 to align with the game logic

    // Draw the paddle
    ctx.fillRect(xPosition, yPosition, 10, paddleHeight);

    // Draw the bounding box for debugging
    ctx.strokeStyle = 'red';
    ctx.strokeRect(xPosition, yPosition, 10, paddleHeight);
    //console.log(`Drawing ${paddleSide} paddle at x: ${xPosition}, y: ${yPosition}, height: ${paddleHeight}`);
}


// Invert the y-coordinate for the canvas system
function drawBall(position) {
    ctx.fillStyle = '#FFF';
    ctx.beginPath();
    ctx.arc(position.x * scaleX, (10 - position.y) * scaleY, 10, 0, Math.PI * 2);
    ctx.closePath();
    ctx.fill();
}

function drawScore(score, x, y) {
	ctx.fillStyle = '#FFF';
	ctx.font = '32px Arial';
	ctx.fillText(score, x, y);
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
	ctx.fillText("Pong!", canvas.width / 2, 28);
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

function updateGame(data) {
	//console.log("inside updateGame");
	//console.log("New data:", data);

	// Assign the new data to the gameState variable
	gameState.ball_position = data.ball_position;
	gameState.left_paddle = data.left_paddle;
	gameState.right_paddle = data.right_paddle;
	gameState.score_left = data.score_left;
	gameState.score_right = data.score_right;

	//console.log("Updated game state:", gameState);

	// Clear the canvas
	ctx.clearRect(0, 0, canvas.width, canvas.height);

	// Redraw all game elements with the updated game state
	drawBall(gameState.ball_position);
	drawPaddle(gameState.left_paddle, 'left'); 
	drawPaddle(gameState.right_paddle, 'right'); 
	drawScore(gameState.score_left, canvas.width / 4, 50);
	drawScore(gameState.score_right, (canvas.width / 4) * 3, 50);
	ctx.fillStyle = "white";
	ctx.font = "16px Arial";
	ctx.textAlign = "center";
	ctx.fillText(`Opponent: ${opponent}`, canvas.width / 2, 12);
}

window.onMessage = function(msg) 
{
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
			//console.log("game found");
			if (msg.data != null && msg.data.game == "pong" && msg.data.player_id != null)
			{
				player_id = msg.data.player_id;
				state = "game";
				//console.log("player_id: ", player_id);
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
			if (!msg.data || !msg.data.status || state == "game" || state == "victory" || state == "defeat")
				return;
			switch (msg.data.status)
			{
				case "NotFull":
					in_tournament = true;
					state = "menu";
					menu_text = "Waiting for players...";
					break;
				case "Full":
					in_tournament = true;
					state = "menu";
					menu_text = "Waiting for other matches to finish...";
					break;
				case "MatchReady":
					in_tournament = true;
					state = "menu";
					menu_text = "Waiting for opponent to connect...";
					break
				case "WaitingPartner":
					in_tournament = false;
					state = "menu";
					menu_text = "Waiting for opponent to connect...";
					break;
				default:
					in_tournament = false;
					state = "menu";
					menu_text = "";
					break;
			}
			break;
		case "TournamentMatchStarted":
			sendWithToken(ws, {type: "get_game_status", game: "snake"});
			break;
	}
}

// function to send puddle movement to server
function movePaddle(paddle, direction) {
	const type = (paddle === 'left') ? 'move_left_paddle' : 'move_right_paddle';
	sendWithToken(ws, {type: type, direction: direction});
}

// listen for key presses to control the paddle
function handleKeyDown(event)
{
	if (event.key === 'w') up_pressed = true;
	else if (event.key === 's') down_pressed = true;
	checkMovement();
}
document.addEventListener('keydown', handleKeyDown);

function handleKeyUp(event)
{
	if (event.key === 'w') up_pressed = false;
	else if (event.key === 's') down_pressed = false;
	checkMovement();
}
document.addEventListener('keyup', handleKeyUp);

function checkMovement()
{
	if (player_id < 0)
		return;
	let paddle = "left";
	if (player_id != 0)
		paddle = "right";
	if (up_pressed && !down_pressed)
		movePaddle(paddle, 1.0);
	else if (down_pressed && !up_pressed)
		movePaddle(paddle, -1.0);
	else
		movePaddle(paddle, 0.0);
}

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
	document.removeEventListener('keyup', handleKeyUp);
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
	state = "waiting_server"
	sendWithToken(ws, {type:"get_game_status", game: "pong"});
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
