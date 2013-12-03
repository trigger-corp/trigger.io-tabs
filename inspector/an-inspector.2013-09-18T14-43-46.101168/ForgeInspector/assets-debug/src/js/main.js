$(function () {
	$('#start').on('click', function () {
		forge.tabs.openAdvanced({
			url: 'http://192.168.2.144:10000/index2.html'
		});
	});
});

