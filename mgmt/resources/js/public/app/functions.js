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

async function meta_api_get(endpoint, itemCallback, globalCallback, errorCallback) {
    try {
        const response = await fetch(endpoint);
        if(response.ok) {
            const jsonList = await response.json();
            jsonList.forEach(function(item) {
                itemCallback(item);
            });
            globalCallback();
        }
        else throw response;
    }
    catch(e) {
        errorCallback(e);
    }
}

async function meta_api_delete(endpoint, callback, errorCallback) {
    try {
        const response = await fetch(endpoint, {
            method: "DELETE",
            mode: "cors"
        });
        await response;
        if(response.ok) {
            callback();
        }
        else throw response;
    }
    catch(e) {
        errorCallback(e);
    }
}

async function meta_api_post(endpoint, body, callback, errorCallback) {
	try {
        const response = await fetch(endpoint, {
            method: "POST",
            mode: "cors",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify(body)
        });
        await response;
        if(response.ok) {
            callback();
        }
        else throw response;
    }
    catch(e) {
        errorCallback(e);
    }
}

async function meta_api_put(endpoint, body, callback, errorCallback) {
	try {
        const response = await fetch(endpoint, {
            method: "PUT",
            mode: "cors",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify(body)
        });
        await response;
        if(response.ok) {
            callback();
        }
        else throw response;
    }
    catch(e) {
        errorCallback(e);
    }
}