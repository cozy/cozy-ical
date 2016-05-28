cozy-ical
=========

[![Build Status](https://travis-ci.org/cozy/cozy-ical.png?branch=master)](https://travis-ci.org/cozy/cozy-ical)

## Description

*cozy-ical* is a simple library to deal with the iCal format. It makes life
easier to parse iCal files and to build them.

## Warning: API backward-compatibilty breaks with the 1.0.0 version

With 1.0.0 version every component of Cozy-Ical parameters of
components construction must be given through an option object. See example
below for details.

## Usage

### Build a calendar

```javascript
var VCalendar = require('cozy-ical').VCalendar;
var VEvent = require('cozy-ical').VEvent;
var VTodo = require('cozy-ical').VTodo;
var VAlarm = require('cozy-ical').VAlarm;

var cal = new VCalendar({
  organization: 'Cozy Cloud',
  title: 'Cozy Calendar'
});

var date = new Date(2013, 5, 9, 15, 0, 0);
var vtodo = new VTodo({
  stampDate: date,
  startDate: date,
  summary: 'john',
  description: 'my description',
  uid: "9615"
});

var startDate = new Date(2013, 5, 9, 15, 0, 0);
var endDate = new Date(2013, 5, 10, 15, 0, 0);
var vevent = new VEvent({
  stampDate: startDate,
  startDate: startDate,
  endDate: endDate,
  description: "desc",
  location: "loc",
  uid: "3615"
});

vtodo.addAlarm({
  action: VAlarm.EMAIL_ACTION,
  trigger: "-P3D",
  description: 'alarm for todo',
  summary: 'john',
  attendees: []
});
cal.add(vtodo);
cal.add(vevent);

cal.toString();
```

output:

    BEGIN:VCALENDAR
    VERSION:2.0
    PRODID:-//Cozy Cloud//NONSGML Cozy Calendar//EN
    BEGIN:VTODO
    UID:9615
    DTSTAMP:20130609T130000Z
    DESCRIPTION:my description
    DTSTART:20130609T150000Z
    SUMMARY:john
    BEGIN:VALARM
    ACTION:EMAIL
    TRIGGER:-P3D
    DESCRIPTION:alarm for todo
    SUMMARY:john
    END:VALARM
    END:VTODO
    BEGIN:VEVENT
    UID:3615
    DTSTAMP:20130609T130000Z
    DTSTART:20130609T150000Z
    DTEND:20130610T150000Z
    DESCRIPTION:desc
    LOCATION:loc
    END:VEVENT
    END:VCALENDAR

### Parsing


```javascript
var calString = `BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Cozy Cloud//NONSGML Cozy Agenda//EN
BEGIN:VTODO
DTSTAMP:20130609T150000Z
SUMMARY:my description
UID:john
BEGIN:VALARM
ACTION:DISPLAY
REPEAT:1
TRIGGER:20130609T150000Z
END:VALARM
END:VTODO
END:VCALENDAR`;

parser = new ICalParser();
parser.parseString(calString, function(err, cal) {
  console.log(cal.name);
  console.log(cal.getRawValue('PRODID'));
  console.log(cal.subComponents[0].name);
  console.log(cal.subComponents[0].getRawValue('SUMMARY'));
});
```

output:

    VCALENDAR
    -//Cozy Cloud//NONSGML Cozy Agenda//EN
    VTODO
    my description

## Notes on iCal support
This library is meant to support all iCal features as defined in [RFC 5545](https://tools.ietf.org/html/rfc5545). Thus it's not fully supporting everything yet, here is the list of unsupported fields:

### vEvent
* ATTACH
* CLASS
* COMMENT
* CONTACT
* CREATED
* EXDATE
* GEO
* LAST-MOD
* PRIORITY
* RECURRENCE-ID
* RELATED-TO
* RESOURCES
* RDATE
* RS-STATUS
* SEQ
* STATUS
* TRANSPARENCY
* URL

### vTodo
* ATTACH
* ATTENDEE
* CATEGORIES
* CLASS
* COMMENT
* CONTACT
* COMPLETED
* CREATED
* DESCRIPTION
* EXDATE
* GEO
* LAST-MOD
* LOCATION
* ORGANIZER
* PRECENT
* PRIORITY
* RDATE
* RECURID
* RELATED
* RESOURCES
* RRULE
* RSTATUS
* SEQ
* STATUS
* URL

### vAlarm
* TRIGGER related to END

### vJournal
* not supported at all

### vFreeBusy
* not supported at all

### vTimezone
* not supported at all

## Test the parsing

If you want to test the parsing of an iCalendar file, just run:
```
    node index.js xxxx.ics
```

## What is Cozy?

![Cozy Logo](https://raw.github.com/cozy/cozy-setup/gh-pages/assets/images/happycloud.png)

[Cozy](https://cozy.io) is a platform that brings all your web services in the
same private space.  With it, your web apps and your devices can share data
easily, providing you
with a new experience. You can install Cozy on your own hardware where no one
profiles you. You install only the applications you want. You can build your
own one too.

## Community

You can reach the Cozy community via various support:

* IRC #cozycloud on irc.freenode.net
* Post on our [Forum](https://forum.cozy.io)
* Post issues on the [Github repos](https://github.com/cozy/)
* Via [Twitter](https://twitter.com/mycozycloud)
