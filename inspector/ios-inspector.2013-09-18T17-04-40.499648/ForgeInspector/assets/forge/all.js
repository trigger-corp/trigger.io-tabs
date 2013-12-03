/*! Copyright 2011 Trigger Corp. All rights reserved. */
(function(){var n={};var o={};n.config=window.forge.config;o.listeners={};var q={};var j=[];var h=null;var a=false;var t=function(){if(j.length>0){if(!o.debug||window.catalystConnected){a=true;while(j.length>0){var u=j.shift();if(u[0]=="logging.log"){console.log(u[1].message)}o.priv.call.apply(o.priv,u)}a=false}else{h=setTimeout(t,500)}}};o.priv={call:function(B,A,z,v){if((!o.debug||window.catalystConnected||B==="internal.showDebugWarning")&&(j.length==0||a)){var u=n.tools.UUID();var x=true;if(B==="button.onClicked.addListener"||B==="message.toFocussed"){x=false}if(z||v){q[u]={success:z,error:v,onetime:x}}var w={callid:u,method:B,params:A};o.priv.send(w);if(window._forgeDebug){try{w.start=(new Date().getTime())/1000;window._forgeDebug.forge.APICall.apiRequest(w)}catch(y){}}}else{j.push(arguments);if(!h){h=setTimeout(t,500)}}},send:function(u){throw new Error("Forge error: missing bridge to privileged code")},receive:function(u){if(u.callid){if(typeof q[u.callid]===undefined){n.log("Nothing stored for call ID: "+u.callid)}var w=q[u.callid];var v=(typeof u.content==="undefined"?null:u.content);if(w&&w[u.status]){w[u.status](u.content)}if(w&&w.onetime){delete q[u.callid]}if(window._forgeDebug){try{u.end=(new Date().getTime())/1000;window._forgeDebug.forge.APICall.apiResponse(u)}catch(x){}}}else{if(u.event){if(o.listeners[u.event]){o.listeners[u.event].forEach(function(y){if(u.params){y(u.params)}else{y()}})}if(o.listeners["*"]){o.listeners["*"].forEach(function(y){if(u.params){y(u.event,u.params)}else{y(u.event)}})}if(window._forgeDebug){try{u.start=(new Date().getTime())/1000;window._forgeDebug.forge.APICall.apiEvent(u)}catch(x){}}}}}};o.addEventListener=function(u,v){if(o.listeners[u]){o.listeners[u].push(v)}else{o.listeners[u]=[v]}};o.generateQueryString=function(v){if(!v){return""}if(!(v instanceof Object)){return new String(v).toString()}var w=[];var u=function(C,B){if(C===null){return}else{if(C instanceof Array){var z=0;for(var y in C){var A=(B?B:"")+"["+z+"]";z+=1;if(!C.hasOwnProperty(y)){continue}u(C[y],A)}}else{if(C instanceof Object){for(var y in C){if(!C.hasOwnProperty(y)){continue}var A=y;if(B){A=B+"["+y+"]"}u(C[y],A)}}else{w.push(encodeURIComponent(B)+"="+encodeURIComponent(C))}}}};u(v);return w.join("&").replace("%20","+")};o.generateMultipartString=function(v,x){if(typeof v==="string"){return""}var w="";for(var u in v){if(!v.hasOwnProperty(u)){continue}if(v[u]===null){continue}w+="--"+x+"\r\n";w+='Content-Disposition: form-data; name="'+u.replace('"','\\"')+'"\r\n\r\n';w+=v[u].toString()+"\r\n"}return w};o.generateURI=function(v,u){var w="";if(v.indexOf("?")!==-1){w+=v.split("?")[1]+"&";v=v.split("?")[0]}w+=this.generateQueryString(u)+"&";w=w.substring(0,w.length-1);return v+(w?"?"+w:"")};o.disabledModule=function(u,v){var w="The '"+v+"' module is disabled for this app, enable it in your app config and rebuild in order to use this function";n.logging.error(w);u&&u({message:w,type:"UNAVAILABLE",subtype:"DISABLED_MODULE"})};n.enableDebug=function(){o.debug=true;o.priv.call("internal.showDebugWarning",{},null,null);o.priv.call("internal.hideDebugWarning",{},null,null)};setTimeout(function(){if(window.forge&&window.forge.debug){alert("Warning!\n\n'forge.debug = true;' is no longer supported\n\nUse 'forge.enableDebug();' instead.")}},3000);n.is={mobile:function(){return false},desktop:function(){return false},android:function(){return false},ios:function(){return false},chrome:function(){return false},firefox:function(){return false},safari:function(){return false},ie:function(){return false},web:function(){return false},orientation:{portrait:function(){return false},landscape:function(){return false}},connection:{connected:function(){return true},wifi:function(){return true}}};n.is["mobile"]=function(){return true};n.is["ios"]=function(){return true};n.is["orientation"]["portrait"]=function(){return o.currentOrientation=="portrait"};n.is["orientation"]["landscape"]=function(){return o.currentOrientation=="landscape"};n.is["connection"]["connected"]=function(){return o.currentConnectionState.connected};n.is["connection"]["wifi"]=function(){return o.currentConnectionState.wifi};var k=function(A,y,B){var w=[];stylize=function(D,C){return D};function u(C){return C instanceof RegExp||(typeof C==="object"&&Object.prototype.toString.call(C)==="[object RegExp]")}function v(C){return C instanceof Array||Array.isArray(C)||(C&&C!==Object.prototype&&v(C.__proto__))}function x(E){if(E instanceof Date){return true}if(typeof E!=="object"){return false}var C=Date.prototype&&Object.getOwnPropertyNames(Date.prototype);var D=E.__proto__&&Object.getOwnPropertyNames(E.__proto__);return JSON.stringify(D)===JSON.stringify(C)}function z(O,L){try{if(O&&typeof O.inspect==="function"&&!(O.constructor&&O.constructor.prototype===O)){return O.inspect(L)}switch(typeof O){case"undefined":return stylize("undefined","undefined");case"string":var C="'"+JSON.stringify(O).replace(/^"|"$/g,"").replace(/'/g,"\\'").replace(/\\"/g,'"')+"'";return stylize(C,"string");case"number":return stylize(""+O,"number");case"boolean":return stylize(""+O,"boolean")}if(O===null){return stylize("null","null")}if(O instanceof Document){return(new XMLSerializer()).serializeToString(O)}var I=Object.keys(O);var P=y?Object.getOwnPropertyNames(O):I;if(typeof O==="function"&&P.length===0){var D=O.name?": "+O.name:"";return stylize("[Function"+D+"]","special")}if(u(O)&&P.length===0){return stylize(""+O,"regexp")}if(x(O)&&P.length===0){return stylize(O.toUTCString(),"date")}var E,M,J;if(v(O)){M="Array";J=["[","]"]}else{M="Object";J=["{","}"]}if(typeof O==="function"){var H=O.name?": "+O.name:"";E=" [Function"+H+"]"}else{E=""}if(u(O)){E=" "+O}if(x(O)){E=" "+O.toUTCString()}if(P.length===0){return J[0]+E+J[1]}if(L<0){if(u(O)){return stylize(""+O,"regexp")}else{return stylize("[Object]","special")}}w.push(O);var G=P.map(function(R){var Q,S;if(O.__lookupGetter__){if(O.__lookupGetter__(R)){if(O.__lookupSetter__(R)){S=stylize("[Getter/Setter]","special")}else{S=stylize("[Getter]","special")}}else{if(O.__lookupSetter__(R)){S=stylize("[Setter]","special")}}}if(I.indexOf(R)<0){Q="["+R+"]"}if(!S){if(w.indexOf(O[R])<0){if(L===null){S=z(O[R])}else{S=z(O[R],L-1)}if(S.indexOf("\n")>-1){if(v(O)){S=S.split("\n").map(function(T){return"  "+T}).join("\n").substr(2)}else{S="\n"+S.split("\n").map(function(T){return"   "+T}).join("\n")}}}else{S=stylize("[Circular]","special")}}if(typeof Q==="undefined"){if(M==="Array"&&R.match(/^\d+$/)){return S}Q=JSON.stringify(""+R);if(Q.match(/^"([a-zA-Z_][a-zA-Z_0-9]*)"$/)){Q=Q.substr(1,Q.length-2);Q=stylize(Q,"name")}else{Q=Q.replace(/'/g,"\\'").replace(/\\"/g,'"').replace(/(^"|"$)/g,"'");Q=stylize(Q,"string")}}return Q+": "+S});w.pop();var N=0;var F=G.reduce(function(Q,R){N++;if(R.indexOf("\n")>=0){N++}return Q+R.length+1},0);if(F>50){G=J[0]+(E===""?"":E+"\n ")+" "+G.join(",\n  ")+" "+J[1]}else{G=J[0]+E+" "+G.join(", ")+" "+J[1]}return G}catch(K){return"[No string representation]"}}return z(A,(typeof B==="undefined"?2:B))};var b=function(v,w){if("logging" in n.config){var u=n.config.logging.marker||"FORGE"}else{var u="FORGE"}v="["+u+"] "+(v.indexOf("\n")===-1?"":"\n")+v;o.priv.call("logging.log",{message:v,level:w});if(typeof console!=="undefined"){switch(w){case 10:if(console.debug!==undefined&&!(console.debug.toString&&console.debug.toString().match("alert"))){console.debug(v)}break;case 30:if(console.warn!==undefined&&!(console.warn.toString&&console.warn.toString().match("alert"))){console.warn(v)}break;case 40:case 50:if(console.error!==undefined&&!(console.error.toString&&console.error.toString().match("alert"))){console.error(v)}break;default:case 20:if(console.info!==undefined&&!(console.info.toString&&console.info.toString().match("alert"))){console.info(v)}break}}};var m=function(u,v){if(u in n.logging.LEVELS){return n.logging.LEVELS[u]}else{n.logging.__logMessage("Unknown configured logging level: "+u);return v}};var r=function(v){var y=function(z){if(z.message){return z.message}else{if(z.description){return z.description}else{return""+z}}};if(v){var x="\nError: "+y(v);try{if(v.lineNumber){x+=" on line number "+v.lineNumber}if(v.fileName){var u=v.fileName;x+=" in file "+u.substr(u.lastIndexOf("/")+1)}}catch(w){}if(v.stack){x+="\r\nStack trace:\r\n"+v.stack}return x}return""};n.logging={LEVELS:{ALL:0,DEBUG:10,INFO:20,WARNING:30,ERROR:40,CRITICAL:50},debug:function(v,u){n.logging.log(v,u,n.logging.LEVELS.DEBUG)},info:function(v,u){n.logging.log(v,u,n.logging.LEVELS.INFO)},warning:function(v,u){n.logging.log(v,u,n.logging.LEVELS.WARNING)},error:function(v,u){n.logging.log(v,u,n.logging.LEVELS.ERROR)},critical:function(v,u){n.logging.log(v,u,n.logging.LEVELS.CRITICAL)},log:function(v,u,y){if(typeof(y)==="undefined"){var y=n.logging.LEVELS.INFO}try{var w=m(n.config.logging.level,n.logging.LEVELS.ALL)}catch(x){var w=n.logging.LEVELS.ALL}if(y>=w){b(k(v,false,10)+r(u),y)}}};n.internal={ping:function(v,w,u){o.priv.call("internal.ping",{data:[v]},w,u)},call:o.priv.call,addEventListener:o.addEventListener,listeners:o.listeners};var s={};o.currentOrientation=s;o.currentConnectionState=s;o.addEventListener("internal.orientationChange",function(u){if(o.currentOrientation!=u.orientation){o.currentOrientation=u.orientation;o.priv.receive({event:"event.orientationChange"})}});o.addEventListener("internal.connectionStateChange",function(u){if(u.connected!=o.currentConnectionState.connected||u.wifi!=o.currentConnectionState.wifi){o.currentConnectionState=u;o.priv.receive({event:"event.connectionStateChange"})}});n.event={menuPressed:{addListener:function(v,u){o.addEventListener("event.menuPressed",v)}},backPressed:{addListener:function(v,u){o.addEventListener("event.backPressed",function(){v(function(){o.priv.call("event.backPressed_closeApplication",{})})})},preventDefault:function(v,u){o.priv.call("event.backPressed_preventDefault",{},v,u)},restoreDefault:function(v,u){o.priv.call("event.backPressed_restoreDefault",{},v,u)}},messagePushed:{addListener:function(v,u){o.addEventListener("event.messagePushed",v)}},orientationChange:{addListener:function(v,u){o.addEventListener("event.orientationChange",v);if(s&&o.currentOrientation!==s){o.priv.receive({event:"event.orientationChange"})}}},connectionStateChange:{addListener:function(v,u){o.addEventListener("event.connectionStateChange",v);if(s&&o.currentConnectionState!==s){o.priv.receive({event:"event.connectionStateChange"})}}},appPaused:{addListener:function(v,u){o.addEventListener("event.appPaused",v)}},appResumed:{addListener:function(v,u){o.addEventListener("event.appResumed",v)}}};n.reload={updateAvailable:function(v,u){o.priv.call("reload.updateAvailable",{},v,u)},update:function(v,u){o.priv.call("reload.update",{},v,u)},pauseUpdate:function(v,u){o.priv.call("reload.pauseUpdate",{},v,u)},applyNow:function(v,u){n.logging.error("reload.applyNow has been disabled, please see docs.trigger.io for more information.");u({message:"reload.applyNow has been disabled, please see docs.trigger.io for more information.",type:"UNAVAILABLE"})},applyAndRestartApp:function(v,u){o.priv.call("reload.applyAndRestartApp",{},v,u)},switchStream:function(v,w,u){o.priv.call("reload.switchStream",{streamid:v},w,u)},updateReady:{addListener:function(v,u){o.addEventListener("reload.updateReady",v)}},updateProgress:{addListener:function(v,u){o.addEventListener("reload.updateProgress",v)}}};n.tools={UUID:function(){return"xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g,function(x){var w=Math.random()*16|0;var u=x=="x"?w:(w&3|8);return u.toString(16)}).toUpperCase()},getURL:function(v,w,u){o.priv.call("tools.getURL",{name:v.toString()},w,u)}};var p=[];var g=false;o.priv.get=function(){var u=JSON.stringify(p);p=[];return u};var f=[],l="zero-timeout-message";function d(u){f.push(u);window.postMessage(l,"*")}function c(u){setTimeout(u,0)}function e(u){if(u.source==window&&u.data==l){if(u.stopPropagation){u.stopPropagation()}if(f.length){f.shift()()}}}if(window.postMessage){if(window.addEventListener){window.addEventListener("message",e,true)}else{if(window.attachEvent){window.attachEvent("onmessage",e)}}window.setZeroTimeout=d}else{window.setZeroTimeout=c}var i=function(){if(g&&!window.forge._flushing){window.forge._flushing=true;window.forge._flushingInterval=setInterval(function(){window.location.href="forge://go"},100);c(function(){window.location.href="forge://go"})}};o.priv.send=function(u){p.push(u);i()};document.addEventListener("DOMContentLoaded",function(){g=true;i()},false);n._get=o.priv.get;n._receive=function(){var u=arguments;c(function(){o.priv.receive.apply(this,u)})};window.forge=n})();(function () {
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

})();