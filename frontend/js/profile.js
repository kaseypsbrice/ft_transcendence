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
	containers = document.querySelectorAll('.data-mh-tb-container')
	for (let i = 0; i < containers.length; i++)
	{
		let c = containers[i]
		c.remove();
	}
}

window.onMessage = function(event, msg)
{
	switch(msg.type)
	{
		case "Profile":
			if (msg.data == null || msg.data.username == null || msg.data.matches == null ||
			msg.data.display_name == null || msg.data.online == null || msg.data.you == null)
			{
				console.log("invalid profile")
				break;
			}
			clearPage();
			document.getElementById('profile-display-name').textContent = `${msg.data.display_name}`;
			document.getElementById('profile-username').textContent = `${msg.data.username}`;
			if (msg.data.online == true)
				document.getElementById('profile-status').innerHTML = '&#x2022; Online';
			else
				document.getElementById('profile-status').innerHTML = '&#x2022; Offline';
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
			break;
	}
}

window.onOpen = function(event)
{
	clearPage();
	console.log(current_profile)
	sendWithToken(ws, {type:"get_profile", profile: current_profile});
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