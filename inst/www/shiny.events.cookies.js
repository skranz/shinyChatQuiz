function shinyEventsSendCookies(eventId, cookieIds) {
  eventId = typeof eventId !== 'undefined' ? eventId : 'sendCookiesEvent';
  var cookies;
  if (typeof cookieIds === "undefined") {
    cookies = Cookies.getJSON();
  } else {
    cookies = {};
    for (var i = 0; i < cookieIds.length; i++) {
      cookies[cookieIds[i]] = Cookies.getJSON(cookieIds[i]);
    }
  }
  Shiny.onInputChange(eventId,
    {eventId: eventId, id: eventId, cookies: cookies, nonce: Math.random()}
  );
}

function shinyEventsSendCookie(cookieId, eventId) {
  eventId = typeof eventId !== 'undefined' ? eventId : 'sendCookieEvent';
  var cookie = Cookies.getJSON(cookieId);
  Shiny.onInputChange(eventId,
    {eventId: eventId, id: cookieId, cookieId: cookieId, cookie: cookie, nonce: Math.random()}
  );
}


