function insertMatchHistory(date, matchType, opponent, winner) {
    // Detects our header container
    const dataContainer = document.querySelector('.mh-tb-header');
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
    const topPosition = `calc(22% + 45px + ${containerCount * 40}px)`;
    // Calculates the position is should be from the top because our header is 22% from the top
    // and our data containers need to be below that.
    // 45px is the initial spacing from the header, every subsequent spacing is 40px.

    // Set the top position for the data container added.
    newDataContainer.style.top = topPosition;

    dataContainer.appendChild(newDataContainer);
}

// This can obviously be done better, but it's a quick draft to give you an idea of
// how things could be done.
insertMatchHistory('2024-02-26', '1v1', 'User932908', 'User932908');
insertMatchHistory('2024-02-26', '1v1', 'User932908', 'User932908');
insertMatchHistory('2024-02-26', '1v1', 'User932908', 'User932908');
// This I'm not sure how to do yet. I've probably got to make the containers relative to each other.
// Otherwise the multiple users will appear over the top of other containers.
// insertMatchHistory('2024-02-26', 'Tournament', 'User932908, User932908, User932908', 'kbrice');

/* To do for me later:
 * - Make it so that when it's over a specified number the rest of the match history
 *   will be hidden until you click on some sort of see more button. 
 *   Shouldn't take that long to make, but I'm still drafting this.
 */