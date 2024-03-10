const pageTitle = "Mighty Pong";

const routes = {
    404: {
        template: "./templates/404.html",
        title: pageTitle + " | 404",
        description: "Page not found",
        scripts: []
    },
    home: {
        template: "./templates/home.html",
        title: pageTitle + " | Home",
        description: "This is the homepage",
        scripts: []
    },
    leaderboard: {
        template: "./templates/leaderboard.html",
        title: pageTitle + " | Leaderboard",
        description: "View leaderboard on this page",
        scripts: []
    },
    login: {//Remove this and uncomment the below when finished testing (WIP)
      template: "./templates/profile.html",
      title: pageTitle + " | Profile",
      description: "Login if you're an existing member of the site",
      scripts: ["./js/profile.js"]
    },
    //   login: {
    //       template: "./templates/login.html",
    //       title: pageTitle + " | Login",
    //       description: "Login if you're an existing member of the site",
    //       scripts: ["./js/login.js"]
    // },
    signup: {
        template: "./templates/signup.html",
        title: pageTitle + " | Sign Up",
        description: "Sign up and become a member of the site",
        scripts: ["./js/register.js"]
    },
    profile: {
	    template: "./templates/profile.html",
    	title: pageTitle + " | Profile",
    	description: "View your user dashboard / profile",
    	scripts: ["./js/profile.js"]
    },
	pong: {
        template: "./templates/pong.html",
        title: pageTitle + " | Pong",
        description: "Play Pong",
        scripts: ["./js/pong.js"]
    },
	snake: {
        template: "./templates/snake.html",
        title: pageTitle + " | Snake",
        description: "Play snake",
        scripts: ["./js/snake.js"]
    },
	chat: {
        template: "./templates/chat.html",
        title: pageTitle + " | Chat",
        description: "Chat",
        scripts: ["./js/chat.js"]
    },
    tournament: {
        template: "./templates/tournament.html",
        title: pageTitle + " | Tournament",
        description: "Play tournament matches",
        scripts: ["./js/tournament.js"]
    },
    profileSettings: {
        template: "./templates/profile-settings.html",
        title: pageTitle + " | Profile Settings",
        description: "Profile settings that allow you to change your display name and password.",
        scripts: ["./js/profile-settings.js"]
    },
};
// Add other pages to the list

const locationHandler = async () => {
    var location = window.location.hash.replace("#", "");
    if (location.length === 0) {
        location = "home" // Default route/page
    }
    const route = routes[location] || routes[404];
    
    // Remove scripts from the previous route
    const previousScripts = document.querySelectorAll('script[data-route]');
    previousScripts.forEach(script => {
		cleanupPage();
		script.remove();
	});

	// Remove overloads for websocket.js
	window.onOpen = function (event){}
	window.onClose = function (event) {}
	window.onMessage = function (event, msg) {}
	window.onLogout = function () {}
	window.onLogin = function () {}
	window.cleanupPage = function () {}

    // Fetch and load HTML template
    const html = await fetch(route.template).then((response) => response.text());
    document.getElementById("content").innerHTML = html;
    document.title = route.title;
    document
        .querySelector('meta[name="description"]')
        .setAttribute("content", route.description);

    // Fetch and execute scripts for the new route
    const scripts = await Promise.all(
        route.scripts.map(script => fetch(script).then(response => response.text()))
    );
    scripts.forEach(scriptContent => {
        const scriptElement = document.createElement("script");
        scriptElement.innerHTML = scriptContent;
        scriptElement.setAttribute("data-route", location); // Mark script with data attribute
        document.body.appendChild(scriptElement);
    });
};

window.addEventListener("hashchange", locationHandler);

locationHandler();

function onRouteChanged() {
    console.log("Hash changed!");
}

window.addEventListener("hashchange", onRouteChanged);

/* Overall: Changes the content of our html page depending on what navigation link we
 * click on. */
