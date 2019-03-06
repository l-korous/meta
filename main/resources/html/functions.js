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

async function loadListData(endpoint, itemCallback, globalCallback) {
	const response = await fetch(endpoint);
	const jsonList = await response.json();
	jsonList.forEach(function(item) {
		itemCallback(item);
	});
	globalCallback();
}

async function loadDetailData(endpoint, queryString, itemCallback) {
	const response = await fetch(endpoint + '/?' + queryString);
	const myJson = await response.json();
	itemCallback(myJson);
}