function getParameterByName(name, url) {
	if (!url)
		url = window.location.href;
	name = name.replace(/[\[\]]/g, '\\$&');
	var regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)'), results = regex.exec(url);
	if (!results)
		return null;
	if (!results[2])
		return '';
	return decodeURIComponent(results[2].replace(/\+/g, ' '));
}

async function get(endpoint, itemCallback, globalCallback) {
	const response = await fetch(endpoint);
	const jsonList = await response.json();
	jsonList.forEach(function(item) {
		itemCallback(item);
	});
	globalCallback();
}

async function delete_item(endpoint, callback) {
	const response = await fetch(endpoint, {
        method: "DELETE",
		mode: "cors"
    });
	await response;
	callback();
}

async function post_item(endpoint, body, callback) {
	const response = await fetch(endpoint, {
        method: "POST",
		mode: "cors",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify(body)
    });
	await response;
	callback();
}

async function put_item(endpoint, body, callback) {
	const response = await fetch(endpoint, {
        method: "PUT",
		mode: "cors",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify(body)
    });
	await response;
	callback();
}