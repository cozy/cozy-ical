cozy-ical
=========

[![Build
Status](https://travis-ci.org/aenario/cozy-ical.png?branch=master)](https://travis-ci.org/aenario/cozy-ical)

## Description

*cozy-ical* is a simple library to 

## Usage

Build a calendar:

var date = new Date(2013, 5, 9, 15, 0, 0);
var cal = new VCalendar('Cozy Cloud', 'Cozy Calendar');
var vtodo = new VTodo(date, 'jhon', 'my description');

var startDate = new Date(2013, 5, 9, 15, 0, 0);
endDate = new Date(2013, 5, 10, 15, 0, 0);
vevent = new VEvent(startDate, endDate, "desc", "loc", "3615");
vtodo.addAlarm(date);
cal.add(vtodo);
cal.toString()

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
