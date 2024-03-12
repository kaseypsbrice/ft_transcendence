(function (){
function insertMatchHistory(date, matchType, opponent, winner) {
    // Detects our header container
    const dataContainer = document.querySelector('.scrollable-mh-data');
    // Creates a new div element and sets it's class element
    const newDataContainer = document.createElement('div');
    newDataContainer.classList.add('data-mh-tb-container');

    newDataContainer.innerHTML = `
        <div id="data-mh-tb-date">${date}</div>
        <div id="data-mh-tb-match-type">${matchType}</div>
        <div id="data-mh-tb-opponent">${opponent}</div>
        <div id="data-mh-tb-winner">${winner}</div>
    `;

    const containerCount = document.querySelectorAll('.data-mh-tb-container').length;
    const topPosition = `calc(10px + ${containerCount * 40}px)`;
    // Calculates the position is should be from the top because our header is 22% from the top
    // and our data containers need to be below that.
    // 45px is the initial spacing from the header, every subsequent spacing is 40px.

    // Set the top position for the data container added.
    newDataContainer.style.top = topPosition;

    dataContainer.appendChild(newDataContainer);
}

function insertPongStats(wins, losses, tournament_wins) {
    // Detects our header container
    const dataContainer = document.querySelector('.data-stats-pong-container');
    // Creates a new div element and sets it's class element

    dataContainer.innerHTML = `
        <div id="data-mh-tb-date">Pong</div>
        <div id="data-mh-tb-match-type">${wins}</div>
        <div id="data-mh-tb-opponent">${losses}</div>
        <div id="data-mh-tb-winner">${tournament_wins}</div>
    `;
}

function insertSnakeStats(wins, losses, tournament_wins) {
    // Detects our header container
    const dataContainer = document.querySelector('.data-stats-snake-container');
    // Creates a new div element and sets it's class element

    dataContainer.innerHTML = `
        <div id="data-mh-tb-date">Snake</div>
        <div id="data-mh-tb-match-type">${wins}</div>
        <div id="data-mh-tb-opponent">${losses}</div>
        <div id="data-mh-tb-winner">${tournament_wins}</div>
    `;
}

// This can obviously be done better, but it's a quick draft to give you an idea of
// how things could be done.
// This I'm not sure how to do yet. I've probably got to make the containers relative to each other.
// Otherwise the multiple users will appear over the top of other containers.
// insertMatchHistory('2024-02-26', 'Tournament', 'User932908, User932908, User932908', 'kbrice');

/* To do for me later:
 * - Make it so that when it's over a specified number the rest of the match history
 *   will be hidden until you click on some sort of see more button. 
 *   Shouldn't take that long to make, but I'm still drafting this.
 */

function clearPage()
{
	document.getElementById('profile-display-name').textContent = "";
	document.getElementById('profile-username').textContent = "";
	setPictureDisplayName(document.getElementById('profile-picture'), "");
	let containers = document.querySelectorAll('.data-mh-tb-container')
	for (let i = 0; i < containers.length; i++)
	{
		let c = containers[i]
		c.remove();
	}
	let friends = document.querySelectorAll('.wrap-friend-elements')
	for (let i = 0; i < friends.length; i++)
	{
		let c = friends[i]
		c.remove();
	}
}

function setUnfriend(friendButton)
{
	friendButton.style.display = '';
	friendButton.textContent = "Remove Friend";
	friendButton.onclick = function() {
		sendWithToken(ws, {type: "unfriend_user", name: current_profile});
		friendButton.style.display = 'none';
	};
}

function setFriend(friendButton)
{
	friendButton.style.display = '';
	friendButton.textContent = "Add Friend";
	friendButton.onclick = function() {
		sendWithToken(ws, {type: "friend_user", name: current_profile});
		friendButton.style.display = 'none';
	};
}

function setUnblock(blockButton)
{
	blockButton.style.display = '';
	blockButton.textContent = "Unblock";
	blockButton.onclick = function() {
		sendWithToken(ws, {type: "unblock_user", name: current_profile});
		blockButton.style.display = 'none';
	};
}

function setBlock(blockButton)
{
	blockButton.style.display = '';
	blockButton.textContent = "Block";
	blockButton.onclick = function() {
		sendWithToken(ws, {type: "block_user", name: current_profile});
		blockButton.style.display = 'none';
	};
}

function setAcceptFriend(friendButton)
{
	friendButton.style.display = '';
	friendButton.textContent = "Accept Friend Request";
	friendButton.onclick = function() {
		sendWithToken(ws, {type: "accept_friend", name: current_profile});
		friendButton.style.display = 'none';
	}
}

window.onMessage = function(msg)
{
	switch(msg.type)
	{
		case "Profile":
			if (msg.data == null || msg.data.username == null || msg.data.matches == null ||
			msg.data.display_name == null || msg.data.online == null || msg.data.you == null || 
			msg.data.pong_wins == null || msg.data.pong_losses == null || msg.data.snake_wins == null ||
			msg.data.snake_losses == null || msg.data.pong_tournament_wins == null || 
			msg.data.snake_tournament_wins == null)
			{
				console.log("invalid profile")
				break;
			}
			clearPage();
			document.getElementById('profile-display-name').textContent = `${msg.data.display_name}`;
			document.getElementById('profile-username').textContent = `${msg.data.username}`;
			let blockButton = document.getElementById('pf-block');
			let friendButton = document.getElementById('pf-add-friend');
			if (msg.data.you)
			{
				blockButton.style.display = 'none';
				friendButton.style.display = 'none';
			}
			else
			{
				if (msg.data.is_friend)
					setUnfriend(friendButton);
				else if (msg.data.friend_pending)
					setAcceptFriend(friendButton);
				else
					setFriend(friendButton);
				if (msg.data.is_blocked)
					setUnblock(blockButton);
				else
					setBlock(blockButton);
			}
			if (msg.data.online == true)
			{
				document.getElementById('profile-status').style.color = "green";
				document.getElementById('profile-status').innerHTML = '&#x2022; Online';
			}
			else
			{
				document.getElementById('profile-status').style.color = "red";
				document.getElementById('profile-status').innerHTML = '&#x2022; Offline';
			}
			insertPongStats(msg.data.pong_wins, msg.data.pong_losses, msg.data.pong_tournament_wins);
			insertSnakeStats(msg.data.snake_wins, msg.data.snake_losses, msg.data.snake_tournament_wins);
			for (let i = 0; i < msg.data.matches.length; i++)
			{
				let m = msg.data.matches[i];
				if (m.winner == null || m.loser == null || m.game == null || m.time == null || m.info == null)
				{
					console.log("invalid match", m);
					continue;
				}
				console.log(m)
				if (m.winner == msg.data.display_name)
					insertMatchHistory(m.time.split(' ', 1)[0], `${m.game.charAt(0).toUpperCase() + m.game.slice(1)} ${m.info}`, m.loser, m.winner);
				else
					insertMatchHistory(m.time.split(' ', 1)[0], `${m.game.charAt(0).toUpperCase() + m.game.slice(1)} ${m.info}`, m.winner, m.winner);
			}
			for (let i = 0; i < msg.data.friends.length; i++)
			{
				let friend = msg.data.friends[i];
				const newDiv = document.createElement('div');
				newDiv.classList.add('wrap-friend-elements');
				const newNameDiv = document.createElement('div');
				newNameDiv.classList.add('friend');
				const newStatusDiv = document.createElement('div');
				newStatusDiv.innerHTML = '&#x2022;'
				newStatusDiv.id = 'friend-status';
				newNameDiv.textContent = friend.name;
				if (friend.online)
					newStatusDiv.style.color = 'green';
				else
					newStatusDiv.style.color = 'red';
				newDiv.appendChild(newNameDiv);
				newDiv.appendChild(newStatusDiv);
				document.getElementById('pf-friends').appendChild(newDiv);
			}
			break;
		case "BlockReply":
		case "UnblockError":
			setUnblock(document.getElementById('pf-block'));
			break;
		case "UnblockReply":
		case "BlockError":
			setBlock(document.getElementById('pf-block'));
			break;
		case "UnfriendError":
			setUnfriend(document.getElementById('pf-add-friend'));
			break;
		case "UnfriendReply":
		case "AcceptFriendReply":
		case "FriendError":
			setFriend(document.getElementById('pf-add-friend'));
			break;
		
	}
}

window.onOpen = function()
{
	clearPage();
	console.log(current_profile)
	sendWithToken(ws, {type:"get_profile", profile: current_profile});
	let cachedData = localStorage.getItem(current_profile);
	setPictureDisplayName(document.getElementById('profile-picture'), current_profile);
	if (!cachedData)
		sendWithToken(ws, {type: "get_profile_picture", display_name: current_profile, timestamp: "0"});
	else
	{
		let cachedJSON = JSON.parse(cachedData);
		sendWithToken(ws, {type: "get_profile_picture", display_name: current_profile, timestamp: cachedJSON.timestamp});
	}
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