let gameState = {
	ball_position: {x: 0, y: 0},
	left_paddle: {y:5},
	right_paddle: {y:5},
	score_left: 0,
	score_right: 0
};

const canvas = document.getElementById('pongCanvas')
const ctx = canvas.getContext('2d');
const ws = new WebSocket('ws://127.0.0.1:8080');



const scaleX = canvas.width / 10;
const scaleY = canvas.height / 10;

var player_id = -1;

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
}

ws.onopen = function(event) {
	console.log("Connected to websocket server");
};


ws.onmessage = function(event) {
    try {
		//debug statement
		console.log("message received from server:");
        const msg = JSON.parse(event.data);
        if(msg.type === 'state') {
            updateGame(msg.data);
        } else if(msg.type === 'welcome') {
            console.log(msg.message);
			ws.send(JSON.stringify({type: "find_pong"}));
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




// function to send puddle movement to server
function movePaddle(paddle, direction) {
	const type = (paddle === 'left') ? 'move_left_paddle' : 'move_right_paddle';
	ws.send(JSON.stringify({type: type, direction: direction}));
}

// listen for key presses to control the paddle
document.addEventListener('keydown', function(event) {
	if (player_id < 0)
		return;
	if (event.key === 'ArrowUp' && player_id == 0) movePaddle('left', 1);
	if (event.key === 'ArrowDown' && player_id == 0) movePaddle('left', -1);
	if (event.key === 'ArrowUp' && player_id == 1) movePaddle( 'right', 1); // Move up
	if (event.key === 'ArrowDown' && player_id == 1) movePaddle('right', -1); // Move down

	//if (event.key === 'w') movePaddle('left', 1); // Move up
	//if (event.key === 's') movePaddle('left', -1); // Move down
});

function gameLoop() {
	// update game state or draw based on the most recent game state
	updateGame(gameState);
	requestAnimationFrame(gameLoop);
}

//start the game loop
requestAnimationFrame(gameLoop);