const pageTitle = "Mighty Pong";

const routes = {
	404: {
		template: "./templates/404.html",
		title: pageTitle + " | 404",
		description: "Page not found"
	},
	home: {
		template: "./templates/home.html",
		title: pageTitle + " | Home",
		description: "This is the homepage"
	},
	leaderboard: {
		template: "./templates/leaderboard.html",
		title: pageTitle + " | Leaderboard",
		description: "View leaderboard on this page"
	},
    login: {
        template: "./templates/login.html",
		title: pageTitle + " | Login",
		description: "Login if you're an existing member of the site"
    },
    signup: {
        template: "./templates/signup.html",
		title: pageTitle + " | Sign Up",
		description: "Sign up and become a member of the site"
    },
};
// Add other pages to the list

const locationHandler = async () => {
	var location = window.location.hash.replace("#", "");
	if (location.length === 0) {
		location = "home" // Default route/page
	}
	const route = routes[location] || routes[404];
	const html = await fetch(route.template).then((response) => response.text());
	document.getElementById("content").innerHTML = html;
	document.title = route.title;
	document
		.querySelector('meta[name="description"]')
		.setAttribute("content", route.description);
};

window.addEventListener("hashchange", locationHandler);

locationHandler();

function onRouteChanged() {
	console.log("Hash changed!");
}

window.addEventListener("hashchange", onRouteChanged);

/* Overall: Changes the content of our html page depending on what navigation link we
 * click on. */