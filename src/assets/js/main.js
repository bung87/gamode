/**
 * main.js
 * http://www.codrops.com
 *
 * Licensed under the MIT license.
 * http://www.opensource.org/licenses/mit-license.php
 * 
 * Copyright 2015, Codrops
 * http://www.codrops.com
 */
;(function(window) {

	'use strict';

	/**
	 * some helper functions
	 */
	
	var
		getRandomNumber = function(min, max) {
			return Math.floor(Math.random() * (max - min + 1)) + min;
		},
		throttle = function(fn, delay) {
			var allowSample = true;

			return function(e) {
				if (allowSample) {
					allowSample = false;
					setTimeout(function() { allowSample = true; }, delay);
					fn(e);
				}
			};
		},
		// from https://davidwalsh.name/vendor-prefix
		prefix = (function () {
			var styles = window.getComputedStyle(document.documentElement, ''),
				pre = (Array.prototype.slice.call(styles).join('').match(/-(moz|webkit|ms)-/) || (styles.OLink === '' && ['', 'o']))[1],
				dom = ('WebKit|Moz|MS|O').match(new RegExp('(' + pre + ')', 'i'))[1];
			
			return {
				dom: dom,
				lowercase: pre,
				css: '-' + pre + '-',
				js: pre[0].toUpperCase() + pre.substr(1)
			};
		})();

	var support = {transitions : true},
		transEndEventNames = { 'WebkitTransition': 'webkitTransitionEnd', 'MozTransition': 'transitionend', 'OTransition': 'oTransitionEnd', 'msTransition': 'MSTransitionEnd', 'transition': 'transitionend' },
		
		transEndEventName = transEndEventNames['transition'],
		onEndTransition = function( el, callback, propTest ) {
			var onEndCallbackFn = function( ev ) {
				if( support.transitions ) {
					if( ev.target != this || propTest && ev.propertyName !== propTest && ev.propertyName !== prefix.css + propTest ) return;
					this.removeEventListener( transEndEventName, onEndCallbackFn );
				}
				if( callback && typeof callback === 'function' ) { callback.call(this); }
			};
			if( support.transitions ) {
				el.addEventListener( transEndEventName, onEndCallbackFn );
			}
			else {
				onEndCallbackFn();
			}
		},
		// the main component element/wrapper
		shzEl = document.querySelector('.container'),
		// the initial button
		shzCtrl = shzEl.querySelector('.button--start'),
		// the notes elements
		notes,
		// the note´s speed factor relative to the distance from the note element to the button. 
		// if notesSpeedFactor = 1, then the speed equals the distance (in ms)
		notesSpeedFactor = 4.5,
		// window sizes
		winsize = {width: window.innerWidth, height: window.innerHeight},
		// button offset
		shzCtrlOffset = shzCtrl.getBoundingClientRect(),
		// button sizes
		shzCtrlSize = {width: shzCtrl.offsetWidth, height: shzCtrl.offsetHeight},
		isAnimating = false,
		// tells us if the listening animation is taking place
		isOptimizing = false;


	function init() {
		// particlesJS("body", particlesjsConfig);
		// create the music notes elements - the musical symbols that will animate/move towards the listen button
		createNotes();
		// bind events
		initEvents();
	}

	/**
	 * creates [totalNotes] note elements (the musical symbols that will animate/move towards the listen button)
	 */
	function createNotes() {
		var notesEl = document.createElement('div'), notesElContent = '';
		notesEl.className = 'notes';
		notesElContent += '<div class="note">'+'enable system builtin game mode'+'</div>';
		notesElContent += '<div class="note">'+'disable win hotkeys'+'</div>';
		notesElContent += '<div class="note">'+'disable windows auto update'+'</div>';
		notesElContent += '<div class="note">'+'disable mouse enhance pointer precision'+'</div>';
		notesElContent += '<div class="note">'+'switch to maximum performance power plan'+'</div>';
		notesEl.innerHTML = notesElContent;
		shzEl.insertBefore(notesEl, shzEl.firstChild)

		// reference to the notes elements
		notes = [].slice.call(notesEl.querySelectorAll('.note'));
	}

	/**
	 * event binding
	 */
	function initEvents() {
		// click on the initial button
		shzCtrl.addEventListener('click', toggle);
		var viewLog = document.getElementById("view-log");
		viewLog.addEventListener('click', function () {
			window.api.viewLog();
		});

		// window resize: update window sizes and button offset
		window.addEventListener('resize', throttle(function(ev) {
			winsize = {width: window.innerWidth, height: window.innerHeight};
			shzCtrlOffset = shzCtrl.getBoundingClientRect();
		}, 10));
	}

	function toggle() {
		if(!isOptimizing){
			isAnimating = true;
			showNotes();
			optimize();
		} else {
			hideNotes();
			restore();
		}
		isOptimizing = !isOptimizing
	}


	function optimize() {

		// toggle classes (button content/text changes)
		classie.remove(shzCtrl, 'button--start');
		classie.add(shzCtrl, 'button--listen');
		setTimeout(function(){
			window.api.start();
			setTimeout(function(){
				isAnimating = false;
				document.getElementsByClassName("circle")[0].textContent = "restore";
			}, 2000);
			hideNotes();
		}, 0)
		classie.add(shzCtrl, 'button--animate');

	}

	/**
	 * stop the ripples and notes animations
	 */
	function restore() {
		// ripples stop...
		classie.remove(shzCtrl, 'button--animate');
		// music notes animation stops...
		
		setTimeout(function(){
			window.api.restore();
			document.getElementsByClassName("circle")[0].textContent = "start optimize";
		}, 0)
		
	}

	/**
	 * show the notes elements: first set a random position and then animate them towards the button
	 */
	function showNotes() {
		notes.forEach(function(note) {
			// first position the notes randomly on the page
			positionNote(note);
			// now, animate the notes torwards the button
			animateNote(note);
		});
	}

	/**
	 * fade out the notes elements
	 */
	function hideNotes() {
		notes.forEach(function(note) {
			note.style.opacity = 0;
		});
	}

	/**
	 * positions a note/symbol randomly on the page. The area is restricted to be somewhere outside of the viewport.
	 * @param {Element Node} note - the note element
	 */
	function positionNote(note) {
		// we want to position the notes randomly (translation and rotation) outside of the viewport
		var x = getRandomNumber(-2*(shzCtrlOffset.left + shzCtrlSize.width/2), 2*(winsize.width - (shzCtrlOffset.left + shzCtrlSize.width/2))), y,
			rotation = getRandomNumber(-30, 30);

		if( x > -1*(shzCtrlOffset.top + shzCtrlSize.height/2) && x < shzCtrlOffset.top + shzCtrlSize.height/2 ) {
			y = getRandomNumber(0,1) > 0 ? getRandomNumber(-2*(shzCtrlOffset.top + shzCtrlSize.height/2), -1*(shzCtrlOffset.top + shzCtrlSize.height/2)) : getRandomNumber(winsize.height - (shzCtrlOffset.top + shzCtrlSize.height/2), winsize.height + winsize.height - (shzCtrlOffset.top + shzCtrlSize.height/2));
		}
		else {
			y = getRandomNumber(-2*(shzCtrlOffset.top + shzCtrlSize.height/2), winsize.height + winsize.height - (shzCtrlOffset.top + shzCtrlSize.height/2));
		}

		// first reset transition if any
		note.style.WebkitTransition = note.style.transition = 'none';
		
		// apply the random transforms
		note.style.WebkitTransform = note.style.transform = 'translate3d(' + x + 'px,' + y + 'px,0) rotate3d(0,0,1,' + rotation + 'deg)';

		// save the translation values for later
		note.setAttribute('data-tx', Math.abs(x));
		note.setAttribute('data-ty', Math.abs(y));
	}

	/**
	 * animates a note torwards the button. Once that's done, it repositions the note and animates it again until the component is no longer listening.
	 * @param {Element Node} note - the note element
	 */
	function animateNote(note) {
		setTimeout(function() {
			if(!isAnimating ) return;
			// the transition speed of each note will be proportional to the its distance to the button
			// speed = notesSpeedFactor * distance
			var noteSpeed = notesSpeedFactor * Math.sqrt(Math.pow(note.getAttribute('data-tx'),2) + Math.pow(note.getAttribute('data-ty'),2));

			// apply the transition
			note.style.WebkitTransition = '-webkit-transform ' + noteSpeed + 'ms ease, opacity 0.8s';
			note.style.transition = 'transform ' + noteSpeed + 'ms ease-in, opacity 0.8s';
			
			// now apply the transform (reset the transform so the note moves to its original position) and fade in the note
			note.style.WebkitTransform = note.style.transform = 'translate3d(0,0,0)';
			note.style.opacity = 1;
			
			// after the animation is finished, 
			var onEndTransitionCallback = function() {
				// reset transitions and styles
				note.style.WebkitTransition = note.style.transition = 'none';
				note.style.opacity = 0;

				if(!isAnimating) return;

				positionNote(note);
				animateNote(note);
			};

			onEndTransition(note, onEndTransitionCallback, 'transform');
		}, 60);
	}


	init();

})(window);