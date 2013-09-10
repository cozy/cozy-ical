cozy-ical
=========

[![Build
Status](https://travis-ci.org/aenario/cozy-ical.png?branch=master)](https://travis-ci.org/aenario/cozy-ical)

## Description

*cozy-ical* is a simple library to deal with the iCal format. It makes life
easier to parse iCal files and to build them.

## Usage

### Build a calendar

```javascript
var VCalendar = require('cozy-ical').VCalendar;
var VEvent = require('cozy-ical').VEvent;
var VTodo = require('cozy-ical').VTodo;

var cal = new VCalendar('Cozy Cloud', 'Cozy Calendar');

var date = new Date(2013, 5, 9, 15, 0, 0);
var vtodo = new VTodo(date, 'jhon', 'my description');

var startDate = new Date(2013, 5, 9, 15, 0, 0);
var endDate = new Date(2013, 5, 10, 15, 0, 0);
var vevent = new VEvent(startDate, endDate, "desc", "loc", "3615");

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
  
  

