const canvas = document.getElementById('pongCanvas')
const ctx = canvas.getContext('2d');
const ws = new WebSocket('ws://127.0.0.1:8080');
const scaleX = canvas.width / 10;
const scaleY = canvas.height / 10;
const RIGHT = 0;
const DOWN = 1;
const LEFT = 2;
const UP = 3;
const TILE = 20;

let player_id = -1;
let snakes = [];
let mouse_pos = {x: 0.0, y: 0.0};
let state = "menu";

let gameState = {
	snakes: [],
	food: []
}

let buttons = [
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
		option: "option_1",
		pos: {x: canvas.width * 0.7, y: canvas.height * 0.6},
		size: {x: canvas.width * 0.05, y: canvas.width * 0.05},
		color: "darkcyan",
		color_selected: "gold",
		color_hover: "darkslategray",
		color_hover_selected: "goldenrod",
		textBox: {
			text: "Cool option that does stuff:",
			color: "white",
			font: "20px Arial",
			pos: {x: -canvas.width * 0.35, y: canvas.width * 0.05 - 12},
			align: "left"
		}
	}
];

let options = {
	option_1: false
};

function start_game()
{
	state = "searching";
	ws.send(JSON.stringify({type: "find_snake"}));
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
}

function drawButtons()
{
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

ws.onopen = function(event) {
	console.log("Connected to websocket server");
};


ws.onmessage = function(event) {
    try {
		//console.log("message received from server:");
        const msg = JSON.parse(event.data);
        if(msg.type === 'state') {
			gameState = msg.data;
            updateGame(msg.data);
        } else if(msg.type === 'welcome') {
            console.log(msg.message);
			//ws.send(JSON.stringify({type: "find_snake"}));
        } else if (msg.type === 'game_found')
		{
			console.log("game found");
			player_id = msg.data.player_id;
			state = "game";
			console.log("player_id: ", player_id);
		}
    } catch (e) {
        console.error('Error parsing message:', e);
    }
};

  ws.onclose = function(event) {
	console.log('websocket connection closed', event.code, event.reason);
  };

document.addEventListener('keydown', function(event) {
	if (player_id < 0)
		return;
	if (event.key === 'ArrowUp') ws.send(JSON.stringify({type: "change_direction", direction: UP}));
	if (event.key === 'ArrowDown') ws.send(JSON.stringify({type: "change_direction", direction: DOWN}));
	if (event.key === 'ArrowLeft') ws.send(JSON.stringify({type: "change_direction", direction: LEFT}));
	if (event.key === 'ArrowRight') ws.send(JSON.stringify({type: "change_direction", direction: RIGHT}));
});

document.addEventListener('mousemove', function(event) {
	mouse_pos = getMousePos(event);
});

document.addEventListener('click', function(event)
{
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
});

function gameLoop() {
	switch (state)
	{
		case "menu":
			updateMenu(); break;
		case "searching":
			updateSearching(); break;
		case "game":
			updateGame(gameState); break;
	}

	requestAnimationFrame(gameLoop);
}

//start the game loop
requestAnimationFrame(gameLoop);