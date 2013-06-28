
var url    = phantom.args[0]
var output = phantom.args[1];
var width  = phantom.args[2];

var page = require('webpage').create();

page.viewportSize = { width: width, height: 10 };
page.open(url, function (status) {
	if (status !== 'success') {
		console.log("badness");
		phantom.exit(1);
	}

	page.render(output);
	console.log(output);
	phantom.exit();
});

