/*global forge*/

/**
 * Generate a regex (as a string) for a chrome match pattern
 */
var patternToReStr = function (str) {
	if (str == '<all_urls>') {
		str = '*://*';
	}
	str = str.split('://');
	var scheme = str[0];
	var host, path;
	if (str[1].indexOf('/') === -1) {
		host = str[1];
		path = '';
	} else {
		host = str[1].substring(0, str[1].indexOf('/'));
		path = str[1].substring(str[1].indexOf('/'));
	}

	var re = '';

	// Scheme
	if (scheme == '*') {
		re += '.*://';
	} else {
		re += scheme+'://';
	}

	// Host
	if (host == '*') {
		re += '.*';
	} else if (host.indexOf('*.') === 0) {
		re += '(.+\\.)?'+host.substring(2);
	} else {
		re += host;
	}
	
	// Path
	re += path.replace(/\*/g, '.*');
	
	return "^"+re+"$";
};

forge['tabs'] = {
	/**
	 * Open a new browser window, or (on mobile) a modal view.
	 *
	 * @param {string} url The URL to open in the new window.
	 * @param {function()=} success
	 * @param {function({message: string}=} error
	 */
	'open': function (url, success, error) {
		forge.tabs.openAdvanced({
			url: url
		}, function (childBrowser) {
			childBrowser.closed.addListener(function (details) {
				success && success(details);
			});
		}, error);
	},
	/**
	 * Open a new browser window, or (on mobile) a modal view. With options as an object
	 *
	 * @param {object} options Options
	 * @param {function()=} success
	 * @param {function({message: string}=} error
	 */
	'openWithOptions': function (options, success, error) {
		forge.tabs.openAdvanced(options, function (childBrowser) {
			childBrowser.closed.addListener(function (details) {
				success && success(details);
			});
		}, error);
	},

	/**
	 * Open a child browser with advanced event handling
	 */
	'openAdvanced': function (options, success, error) {
		if (options.pattern) {
			options.pattern = patternToReStr(options.pattern);
		}
		forge.internal.call("tabs.open", options, function (cbId) {
			success && success({
				'closed': {
					'addListener': function (callback) {
						forge.internal.addEventListener('tabs.'+cbId+'.closed', callback);
					}
				},
				'loadStarted': {
					'addListener': function (callback) {
						forge.internal.addEventListener('tabs.'+cbId+'.loadStarted', callback);
					}
				},
				'loadFinished': {
					'addListener': function (callback) {
						forge.internal.addEventListener('tabs.'+cbId+'.loadFinished', callback);
					}
				},
				'loadError': {
					'addListener': function (callback) {
						forge.internal.addEventListener('tabs.'+cbId+'.loadError', callback);
					}
				},
				'executeJS': function (script, success, error) {
					forge.internal.call("tabs.executeJS", {
						modal: cbId,
						script: script
					}, success, error);
				},
				'close': function (success, error) {
					forge.internal.call("tabs.close", {
						modal: cbId
					}, success, error);
				}
			});
		}, error);
	}

};
