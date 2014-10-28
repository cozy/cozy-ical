cozy-ical
=========

[![Build
Status](https://travis-ci.org/aenario/cozy-ical.png?branch=master)](https://travis-ci.org/aenario/cozy-ical)

## Description

*cozy-ical* is a simple library to deal with the iCal format. It makes life
easier to parse iCal files and to build them.

## Warning: API breaks whith the 1.0.0 version

With 1.0.0 version every component of Cozy-Ical parameters of
components construction must be given through an option object. See example
below for details.

## Usage

### Build a calendar

```javascript
var VCalendar = require('cozy-ical').VCalendar;
var VEvent = require('cozy-ical').VEvent;
var VTodo = require('cozy-ical').VTodo;

var cal = new VCalendar({
  organization: 'Cozy Cloud', 
  title: 'Cozy Calendar'
});

var date = new Date(2013, 5, 9, 15, 0, 0);
var vtodo = new VTodo({
  startDate: date, 
  summary: 'jhon', 
  description: 'my description'
});

var startDate = new Date(2013, 5, 9, 15, 0, 0);
var endDate = new Date(2013, 5, 10, 15, 0, 0);
var vevent = new VEvent({
  startDate: startDate,
  endDate: endDate,
  description: "desc",
  location:"loc",
   summary: "3615"
});

vtodo.addAlarm(date);
cal.add(vtodo);
cal.add(vevent);

cal.toString();
```

output:

    BEGIN:VCALENDAR
    VERSION:2.0
    PRODID:-//Cozy Cloud//NONSGML Cozy Agenda//EN
    BEGIN:VTODO
    DTSTAMP:20130609T150000Z
    SUMMARY:my description
    UID:jhon
    BEGIN:VALARM
    ACTION:DISPLAY
    REPEAT:1
    TRIGGER:20130609T150000Z
    END:VALARM
    END:VTODO
    BEGIN:VEVENT
    DESCRIPTION:desc
    DTSTART:20130609T150000Z
    DTEND:20130610T150000Z
    LOCATION:loc
    UID:3615
    END:VEVENT
    END:VCALENDAR

### Parsing


```javascript
var calString = "BEGIN:VCALENDAR
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
END:VCALENDAR";

parser = new ICalParser();
parser.parseString(calString, function(err, cal) {
  console.log(cal.name);
  console.log(cal.fields.PRODID);
  console.log(cal.fields.subCompontents[0].name);
  console.log(cal.fields.subCompontents[0].fields.SUMMARY);
});
```

output:

    VCALENDAR
    -//Cozy Cloud//NONSGML Cozy Agenda//EN
    VTODO
    my description

## What is Cozy?

![Cozy Logo](https://raw.github.com/mycozycloud/cozy-setup/gh-pages/assets/images/happycloud.png)

[Cozy](http://cozy.io) is a platform that brings all your web services in the
same private space.  With it, your web apps and your devices can share data
easily, providing you
with a new experience. You can install Cozy on your own hardware where no one
profiles you. You install only the applications you want. You can build your
own one too.

## Community 

You can reach the Cozy community via various support:

* IRC #cozycloud on irc.freenode.net
* Post on our [Forum](https://groups.google.com/forum/?fromgroups#!forum/cozy-cloud)
* Post issues on the [Github repos](https://github.com/mycozycloud/)
* Via [Twitter](http://twitter.com/mycozycloud)
