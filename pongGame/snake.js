const canvas = document.getElementById('pongCanvas')
const ctx = canvas.getContext('2d');
const ws = new WebSocket('ws://127.0.0.1:8080');


let snakes = [];
const scaleX = canvas.width / 10;
const scaleY = canvas.height / 10;
const RIGHT = 0;
const DOWN = 1;
const LEFT = 2;
const UP = 3;
const TILE = 20;

var player_id = -1;


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
		console.log(snake.length)
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

function updateGame(data) {   
	ctx.clearRect(0, 0, canvas.width, canvas.height);

	drawFood(data.food);
    drawSnakes(data.snakes);
}

ws.onopen = function(event) {
	console.log("Connected to websocket server");
};


ws.onmessage = function(event) {
    try {
		//console.log("message received from server:");
        const msg = JSON.parse(event.data);
        if(msg.type === 'state') {
            updateGame(msg.data);
        } else if(msg.type === 'welcome') {
            console.log(msg.message);
			ws.send(JSON.stringify({type: "find_snake"}));
        } else if (msg.type === 'game_found')
		{
			console.log("game found");
			player_id = msg.data.player_id;
			console.log("player_id: ", player_id);
		}
    } catch (e) {
        console.error('Error parsing message:', e);
    }
};

  ws.onclose = function(event) {
	console.log('websocket connection closed', event.code, event.reason);
  };




// listen for key presses to control the paddle
document.addEventListener('keydown', function(event) {
	if (player_id < 0)
		return;
	if (event.key === 'ArrowUp') ws.send(JSON.stringify({type: "change_direction", direction: UP}));
	if (event.key === 'ArrowDown') ws.send(JSON.stringify({type: "change_direction", direction: DOWN}));
	if (event.key === 'ArrowLeft') ws.send(JSON.stringify({type: "change_direction", direction: LEFT}));
	if (event.key === 'ArrowRight') ws.send(JSON.stringify({type: "change_direction", direction: RIGHT}));
});

function gameLoop() {
	updateGame(gameState);
	requestAnimationFrame(gameLoop);
}

//start the game loop
requestAnimationFrame(gameLoop);