// Placeholders.js 1.1 (commit 2b55a0092feadb0270b16d2358ad3521a17650a6) via https://github.com/jamesallardice/Placeholders.js/blob/master/Placeholders.min.js

var Placeholders=function(){function m(a){a.createTextRange?(a=a.createTextRange(),a.move("character",0),a.select()):a.selectionStart&&(a.focus(),a.setSelectionRange(0,0))}function r(){var a;if(this.value===this.getAttribute("placeholder"))if(k.hideOnFocus){if(this.className=this.className.replace(/\bplaceholderspolyfill\b/,""),this.value="",a=this.getAttribute("data-placeholdertype"))this.type=a}else m(this)}function n(){var a;if(""===this.value&&(this.className+=" placeholderspolyfill",this.value=this.getAttribute("placeholder"),a=this.getAttribute("data-placeholdertype")))this.type="text"}function s(){var a=this.getElementsByTagName("input"),c=this.getElementsByTagName("textarea"),e=a.length,i=e+c.length,g,f,d;for(d=0;d<i;d+=1)g=d<e?a[d]:c[d-e],f=g.getAttribute("placeholder"),g.value===f&&(g.value="")}function t(a){l=this.value;return!(l===this.getAttribute("placeholder")&&-1<u.indexOf(a.keyCode))}function v(){var a;if(this.value!==l&&(this.className=this.className.replace(/\bplaceholderspolyfill\b/,""),this.value=this.value.replace(this.getAttribute("placeholder"),""),a=this.getAttribute("data-placeholdertype")))this.type=a;""===this.value&&(n.call(this),m(this))}function j(a,c,e){if(a.addEventListener)return a.addEventListener(c,e.bind(a),!1);if(a.attachEvent)return a.attachEvent("on"+c,e.bind(a))}function o(a){k.hideOnFocus||(j(a,"keydown",t),j(a,"keyup",v));j(a,"focus",r);j(a,"blur",n)}function p(){var a=document.getElementsByTagName("input"),c=document.getElementsByTagName("textarea"),e=a.length,i=e+c.length,g,f,d,b;for(g=0;g<i;g+=1)if(f=g<e?a[g]:c[g-e],b=f.getAttribute("placeholder"),-1<q.indexOf(f.type)&&b&&(d=f.getAttribute("data-currentplaceholder"),b!==d)){if(f.value===d||f.value===b||!f.value)f.value=b,f.className+=" placeholderspolyfill";d||o(f);f.setAttribute("data-currentplaceholder",b)}}var q="text search url tel email password number".split(" "),k={live:!1,hideOnFocus:!1},u=[37,38,39,40],l;return{init:function(a){var c,e,i;if("undefined"===typeof document.createElement("input").placeholder){for(c in a)a.hasOwnProperty(c)&&(k[c]=a[c]);a=document.createElement("style");a.type="text/css";c=document.createTextNode(".placeholderspolyfill { color:#999 !important; }");a.styleSheet?a.styleSheet.cssText=c.nodeValue:a.appendChild(c);document.getElementsByTagName("head")[0].appendChild(a);Array.prototype.indexOf||(Array.prototype.indexOf=function(a,b){e=b||0;for(i=this.length;e<i;e+=1)if(this[e]===a)return e;return-1});Function.prototype.bind||(Function.prototype.bind=function(a){if(typeof this!=="function")throw new TypeError("Function.prototype.bind - what is trying to be bound is not callable");var b=Array.prototype.slice.call(arguments,1),d=this,c=function(){},e=function(){return d.apply(this instanceof c?this:a,b.concat(Array.prototype.slice.call(arguments)))};c.prototype=this.prototype;e.prototype=new c;return e});a=document.getElementsByTagName("input");c=document.getElementsByTagName("textarea");var g=a.length,f=g+c.length,d,b,h;for(d=0;d<f;d+=1)if(b=d<g?a[d]:c[d-g],h=b.getAttribute("placeholder"),-1<q.indexOf(b.type)&&h){if("password"===b.type)try{b.type="text",b.setAttribute("data-placeholdertype","password")}catch(l){}b.setAttribute("data-currentplaceholder",h);if(""===b.value||b.value===h)b.className+=" placeholderspolyfill",b.value=h;b.form&&(h=b.form,h.getAttribute("data-placeholdersubmit")||(j(h,"submit",s),h.setAttribute("data-placeholdersubmit","true")));o(b)}k.live&&setInterval(p,100);return!0}return!1},refresh:p}}();


//////////////////////////////////////////////////////////////////////

// Resize Events 0.7, http://irama.org/web/dhtml/resize-events/

var ResizeEvents={baseTextHeight:null,currentTextHeight:null,baseWindowWidth:null,baseWindowHeight:null,currentWindowWidth:null,currentWindowHeight:null,initialised:false,intervalReference:null,textSizeTestElement:null,eventElement:$(document),conf:{textResizeEvent:'x-text-resize',windowResizeEvent:'x-window-resize',windowWidthResizeEvent:'x-window-width-resize',windowHeightResizeEvent:'x-window-height-resize',initialResizeEvent:'x-initial-sizes',pollFrequency:500,textSizeTestElId:'text-resize'}};(function($){ResizeEvents.bind=function(events,handler){$(function(){if(ResizeEvents.initialised!==true){ResizeEvents.initialise()}});ResizeEvents.eventElement.bind(events,handler)};ResizeEvents.initialise=function(){if(ResizeEvents.initialised===true){return}ResizeEvents.textSizeTestElement=$('<span id="'+ResizeEvents.conf.textSizeTestElId+'" style="position: absolute; left: -9999px; bottom: 0; '+'font-size: 100%; font-family: Courier New, mono; margin: 0; padding: 0;">&nbsp;</span>').get(0);$('body').append(ResizeEvents.textSizeTestElement);windowWidthNow=$(window).width();windowHeightNow=$(window).height();textHeightNow=getTextHeight();ResizeEvents.baseTextHeight=textHeightNow;ResizeEvents.currentTextHeight=textHeightNow;ResizeEvents.baseWindowWidth=windowWidthNow;ResizeEvents.currentWindowWidth=windowWidthNow;ResizeEvents.baseWindowHeight=windowHeightNow;ResizeEvents.currentWindowHeight=windowHeightNow;if(ResizeEvents.intervalReference==null){ResizeEventsPoll();ResizeEvents.intervalReference=window.setInterval('ResizeEventsPoll()',ResizeEvents.conf.pollFrequency)}ResizeEvents.eventElement.trigger(ResizeEvents.conf.initialResizeEvent,[emPixelNow,textHeightNow,windowWidthNow,windowHeightNow]);ResizeEvents.initialised=true};ResizeEventsPoll=function(){windowWidthNow=$(window).width();windowHeightNow=$(window).height();textHeightNow=getTextHeight();emPixelNow=windowWidthNow/textHeightNow;widthChanged=false;if(ResizeEvents.currentWindowWidth!=windowWidthNow){ResizeEvents.eventElement.trigger(ResizeEvents.conf.windowWidthResizeEvent,[emPixelNow,textHeightNow,windowWidthNow,windowHeightNow]);ResizeEvents.eventElement.trigger(ResizeEvents.conf.windowResizeEvent,[emPixelNow,textHeightNow,windowWidthNow,windowHeightNow]);ResizeEvents.currentWindowWidth=windowWidthNow;widthChanged=true}if(ResizeEvents.currentWindowHeight!=windowHeightNow){ResizeEvents.eventElement.trigger(ResizeEvents.conf.windowHeightResizeEvent,[emPixelNow,textHeightNow,windowWidthNow,windowHeightNow]);if(!widthChanged){ResizeEvents.eventElement.trigger(ResizeEvents.conf.windowResizeEvent,[emPixelNow,textHeightNow,windowWidthNow,windowHeightNow])}ResizeEvents.currentWindowHeight=windowHeightNow}if(ResizeEvents.currentTextHeight!=textHeightNow){ResizeEvents.eventElement.trigger(ResizeEvents.conf.textResizeEvent,[emPixelNow,textHeightNow,windowWidthNow,windowHeightNow]);ResizeEvents.currentTextHeight=textHeightNow}};getTextHeight=function(){return ResizeEvents.textSizeTestElement.offsetHeight+''}})(jQuery);

//////////////////////////////////////////////////////////////////////

// Swiftype JS

if (Swiftype && Swiftype.key) {
    $(document).ready(function() {
	// add a container for search results, unless one's already there
	if ($('#st-results-container').length == 0) {
	    var results_div = document.createElement('div');
	    results_div.setAttribute('id', 'st-results-container');
	    document.body.appendChild(results_div);
	}
    });

    (function() {
	Swiftype.inputElement = '#search';
	Swiftype.resultContainingElement = '#st-results-container';
	Swiftype.attachElement = '#search';
	Swiftype.renderStyle = "overlay";

	if (typeof(page_id) !== 'undefined' && page_id == 'search-page') {
            Swiftype.renderStyle = "inline";
	}

	var script = document.createElement('script');
	script.type = 'text/javascript';
	script.async = true;
	script.src = "//swiftype.com/embed.js";
	var entry = document.getElementsByTagName('script')[0];
	entry.parentNode.insertBefore(script, entry);
    }());
}

//////////////////////////////////////////////////////////////////////


$(document).ready(function() {
    page_id = $('body').attr('id') || page_id;
    Placeholders.init();

    function positionFooter() {
	return;
	var footer = $("#footer");
	var container = $('#main-container');
	if ((($(document.body).height() + footer.height()) < $(window).height() && footer.css("position") == "fixed") || ($(document.body).height() < $(window).height() && footer.css("position") != "fixed")) {
	    if (footer.length) {
		var diff = footer.offset().top - (container.offset().top + container.height());
		container.css({'padding-bottom': diff + 'px'});
		footer.css({ position: "fixed", bottom: "0", width: "100%" });
	    }
	} else {
	    container.css({'padding-bottom': '0'});
	    if (footer.length) {
		footer.css({ position: "static" });
	    }
	}
    }
    positionFooter();
    $(window).scroll(positionFooter);
    $(window).resize(positionFooter);
    $(window).load(positionFooter);

    ResizeEvents.eventElement.bind(
	'x-initial-sizes x-text-resize x-zoom-resize x-window-resize x-window-width-resize x-window-height-resize',
	positionFooter);

    if (page_id == 'index-page') {

	if (!("autofocus" in document.createElement("input"))) {
	    $("#search").focus();
	}

    } else if (page_id == 'resource-page') {

	// enable pretty tooltips for primary core links
	$('h2 a').tooltip();
	$('.core-email-primary-link a').tooltip();

	$('div.core h2 > span').click(function (event) {
	    alert("Sorry, this core doesn't have a website. Try contacting them by email or phone.");
	});

	// Google Analytics support for outgoing core links
	// delayed clicks based on http://support.google.com/googleanalytics/bin/answer.py?hl=en&answer=55527

	var _gaq = _gaq || [];

if (0) {

	$('.core h2 a').click(function(event) {
	    var current_page_url = window.location.href;
	    var current_core_name = $(this).parents('h2').text();
	    var link_url = $(this).attr('href');
	    try {
		event.preventDefault();
		_gaq.push(['_trackEvent', 'resource_page', 'click_web', current_core_name + ' | ' + link_url]);
		setTimeout('document.location = "' + link_url + '"', 100);
	    } catch(err){};
	});

	$('.core .core-email, .core .core-email-primary-link').click(function(event) {
	    var current_page_url = window.location.href;
	    var current_core_name = $(this).parents('div.core').find('h2').text();
	    var link_url = $(this).attr('href');
	    var email = $(this).text();
	    var event_action = 'click_email';
	    if ($(this).hasClass('.core-email-primary-link')) {
		event_action = 'click_email_primary';
	    }
	    try {
		event.preventDefault();
		_gaq.push(['_trackEvent', 'resource_page', event_action, current_core_name + ' | ' + email]);
		setTimeout('document.location = "' + link_url + '"', 100);
	    } catch(err){};
	});
}


	// core location filter
	// show if we have at least 2 locations and 2 cores
	if ($('#core-location-filter a').length >= 3 && // length is # of cores + "all"
	    $('.core').length >= 2) {

	    $('#core-location-filter').show();
	    $('#core-location-filter a').each(function (i, button) {
		var wanted_class = $(button).data('wanted-class') || '';
		$(button).append(' (' + $('.core' + wanted_class).length + ')');
	    });

	    $('#core-location-filter a').click(function (event) {
		if (!$(event.target).hasClass('active')) {      // run if not enabled
		    $('.core:hidden').show();      // show all options
		    $(event.target).addClass('active primary'); //   set button color
		    var wanted_class = $(event.target).data('wanted-class');
		    if (wanted_class) {
			$('.core:not(' + wanted_class + ')').hide();
		    }
		}

		// remove button color on other buttons
		$('#core-location-filter a').not(event.target).removeClass('active primary');
	    });
	}

    } else if (page_id == 'search-page') {

	var vars = [];
	var url  = window.location.href.slice(window.location.href.indexOf('?') + 1);
	url = url.replace(/#.*/, '');
	var hashes = url.split('&');
	for(var i = 0; i < hashes.length; i++) {
            hash = hashes[i].split('=');
            vars.push(hash[0]);
            vars[hash[0]] = hash[1];
	}
	if (vars['q']) {
	    var search_string = unescape(vars['q']);
	    $('#search').val(search_string);
	    if (! window.location.hash) {
		window.location.hash = 'stp=1&stq=' + vars['q'];
	    }
	}

    }

});
