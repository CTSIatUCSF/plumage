// Placeholder.js via https://github.com/jamesallardice/Placeholders.js/blob/master/Placeholders.min.js

var Placeholders=function(){function i(a){var b=a.getElementsByTagName("input"),c=a.getElementsByTagName("textarea"),d=b.length,e=d+c.length,f,g,h;for(h=0;h<e;h++){f=h<d?b[h]:c[h-d];g=f.getAttribute("placeholder");if(f.value===g){f.value=""}}}function h(a){if(a.value===""){a.className=a.className+" placeholderspolyfill";a.value=a.getAttribute("placeholder")}}function g(a){if(a.value===a.getAttribute("placeholder")){a.className=a.className.replace(/\bplaceholderspolyfill\b/,"");a.value=""}}function f(a){if(a.addEventListener){a.addEventListener("focus",function(){g(a)},false);a.addEventListener("blur",function(){h(a)},false)}else if(a.attachEvent){a.attachEvent("onfocus",function(){g(a)});a.attachEvent("onblur",function(){h(a)})}}function e(){var b=document.getElementsByTagName("input"),c=document.getElementsByTagName("textarea"),d=b.length,e=d+c.length,g,h,i,j;for(g=0;g<e;g++){h=g<d?b[g]:c[g-d];j=h.getAttribute("placeholder");if(a.indexOf(h.type)===-1){if(j){i=h.getAttribute("data-currentplaceholder");if(j!==i){if(h.value===i||h.value===j||!h.value){h.value=j;h.className=h.className+" placeholderspolyfill"}if(!i){f(h)}h.setAttribute("data-currentplaceholder",j)}}}}}function d(){var b=document.getElementsByTagName("input"),c=document.getElementsByTagName("textarea"),d=b.length,e=d+c.length,g,h,j,k;for(g=0;g<e;g++){h=g<d?b[g]:c[g-d];k=h.getAttribute("placeholder");if(a.indexOf(h.type)===-1){if(k){h.setAttribute("data-currentplaceholder",k);if(h.value===""||h.value===k){h.className=h.className+" placeholderspolyfill";h.value=k}if(h.form){j=h.form;if(!j.getAttribute("data-placeholdersubmit")){if(j.addEventListener){j.addEventListener("submit",function(){i(j)},false)}else if(j.attachEvent){j.attachEvent("onsubmit",function(){i(j)})}j.setAttribute("data-placeholdersubmit","true")}}f(h)}}}}function c(a){var c=document.createElement("input"),f,g,h,i;if(typeof c.placeholder==="undefined"){f=document.createElement("style");f.type="text/css";g=document.createTextNode(".placeholderspolyfill { color:#999 !important; }");if(f.styleSheet){f.styleSheet.cssText=g.nodeValue}else{f.appendChild(g)}document.getElementsByTagName("head")[0].appendChild(f);if(!Array.prototype.indexOf){Array.prototype.indexOf=function(a,b){for(h=b||0,i=this.length;h<i;h++){if(this[h]===a){return h}}return-1}}d();if(a){b=setInterval(e,100)}}return false}var a=["hidden","datetime","date","month","week","time","datetime-local","range","color","checkbox","radio","file","submit","image","reset","button"],b;return{init:c,refresh:e}}()

//////////////////////////////////////////////////////////////////////

// Resize Events 0.7, http://irama.org/web/dhtml/resize-events/

var ResizeEvents={baseTextHeight:null,currentTextHeight:null,baseWindowWidth:null,baseWindowHeight:null,currentWindowWidth:null,currentWindowHeight:null,initialised:false,intervalReference:null,textSizeTestElement:null,eventElement:$(document),conf:{textResizeEvent:'x-text-resize',windowResizeEvent:'x-window-resize',windowWidthResizeEvent:'x-window-width-resize',windowHeightResizeEvent:'x-window-height-resize',initialResizeEvent:'x-initial-sizes',pollFrequency:500,textSizeTestElId:'text-resize'}};(function($){ResizeEvents.bind=function(events,handler){$(function(){if(ResizeEvents.initialised!==true){ResizeEvents.initialise()}});ResizeEvents.eventElement.bind(events,handler)};ResizeEvents.initialise=function(){if(ResizeEvents.initialised===true){return}ResizeEvents.textSizeTestElement=$('<span id="'+ResizeEvents.conf.textSizeTestElId+'" style="position: absolute; left: -9999px; bottom: 0; '+'font-size: 100%; font-family: Courier New, mono; margin: 0; padding: 0;">&nbsp;</span>').get(0);$('body').append(ResizeEvents.textSizeTestElement);windowWidthNow=$(window).width();windowHeightNow=$(window).height();textHeightNow=getTextHeight();ResizeEvents.baseTextHeight=textHeightNow;ResizeEvents.currentTextHeight=textHeightNow;ResizeEvents.baseWindowWidth=windowWidthNow;ResizeEvents.currentWindowWidth=windowWidthNow;ResizeEvents.baseWindowHeight=windowHeightNow;ResizeEvents.currentWindowHeight=windowHeightNow;if(ResizeEvents.intervalReference==null){ResizeEventsPoll();ResizeEvents.intervalReference=window.setInterval('ResizeEventsPoll()',ResizeEvents.conf.pollFrequency)}ResizeEvents.eventElement.trigger(ResizeEvents.conf.initialResizeEvent,[emPixelNow,textHeightNow,windowWidthNow,windowHeightNow]);ResizeEvents.initialised=true};ResizeEventsPoll=function(){windowWidthNow=$(window).width();windowHeightNow=$(window).height();textHeightNow=getTextHeight();emPixelNow=windowWidthNow/textHeightNow;widthChanged=false;if(ResizeEvents.currentWindowWidth!=windowWidthNow){ResizeEvents.eventElement.trigger(ResizeEvents.conf.windowWidthResizeEvent,[emPixelNow,textHeightNow,windowWidthNow,windowHeightNow]);ResizeEvents.eventElement.trigger(ResizeEvents.conf.windowResizeEvent,[emPixelNow,textHeightNow,windowWidthNow,windowHeightNow]);ResizeEvents.currentWindowWidth=windowWidthNow;widthChanged=true}if(ResizeEvents.currentWindowHeight!=windowHeightNow){ResizeEvents.eventElement.trigger(ResizeEvents.conf.windowHeightResizeEvent,[emPixelNow,textHeightNow,windowWidthNow,windowHeightNow]);if(!widthChanged){ResizeEvents.eventElement.trigger(ResizeEvents.conf.windowResizeEvent,[emPixelNow,textHeightNow,windowWidthNow,windowHeightNow])}ResizeEvents.currentWindowHeight=windowHeightNow}if(ResizeEvents.currentTextHeight!=textHeightNow){ResizeEvents.eventElement.trigger(ResizeEvents.conf.textResizeEvent,[emPixelNow,textHeightNow,windowWidthNow,windowHeightNow]);ResizeEvents.currentTextHeight=textHeightNow}};getTextHeight=function(){return ResizeEvents.textSizeTestElement.offsetHeight+''}})(jQuery);

//////////////////////////////////////////////////////////////////////

// Swiftype JS

if (Swiftype.key) {
    $(document).ready(function() {
	// add a container for search results, unless one's already there
	if ($('#st-results-container').length == 0) {
	    var results_div = document.createElement('div');
	    results_div.setAttribute('id', 'st-results-container');
	    document.body.appendChild(results_div);
	}
    });

    var Swiftype = window.Swiftype || {};
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
