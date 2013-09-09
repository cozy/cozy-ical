{ICalParser, VCalendar, VAlarm, VTodo, VEvent} = require '../lib/index'
should = require 'should'

helpers = null
describe "Calendar export/import", ->

    describe 'ical helpers', ->

        describe 'get vCalendar string', ->
            it 'should return default vCalendar string', ->
                cal = new VCalendar 'Cozy Cloud', 'Cozy Agenda'
                cal.toString().should.equal """
                    BEGIN:VCALENDAR
                    VERSION:2.0
                    PRODID:-//Cozy Cloud//NONSGML Cozy Agenda//EN
                    END:VCALENDAR""".replace(/\n/g, '\r\n')

        describe 'get vAlarm string', ->
            it 'should return default vAlarm string', ->
                date = new Date 2013, 5, 9, 15, 0, 0
                valarm = new VAlarm date
                valarm.toString().should.equal """
                    BEGIN:VALARM
                    ACTION:DISPLAY
                    REPEAT:1
                    TRIGGER:20130609T150000Z
                    END:VALARM""".replace(/\n/g, '\r\n')

        describe 'get vTodo string', ->
            it 'should return default vTodo string', ->
                date = new Date 2013, 5, 9, 15, 0, 0
                vtodo = new VTodo date, "3615", "ma description"
                vtodo.toString().should.equal """
                    BEGIN:VTODO
                    DTSTAMP:20130609T150000Z
                    SUMMARY:ma description
                    UID:3615
                    END:VTODO""".replace(/\n/g, '\r\n')

        describe 'get vEvent string', ->
            it 'should return default vEvent string', ->
                startDate = new Date 2013, 5, 9, 15, 0, 0
                endDate = new Date 2013, 5, 10, 15, 0, 0
                vevent = new VEvent startDate, endDate, "desc", "loc", "3615"
                vevent.toString().should.equal """
                    BEGIN:VEVENT
                    DESCRIPTION:desc
                    DTSTART:20130609T150000Z
                    DTEND:20130610T150000Z
                    LOCATION:loc
                    UID:3615
                    END:VEVENT""".replace(/\n/g, '\r\n')



        describe 'get vCalendar with alarms', ->
            it 'should return ical string', ->
                date = new Date 2013, 5, 9, 15, 0, 0
                cal = new VCalendar 'Cozy Cloud', 'Cozy Agenda'
                vtodo = new VTodo date, 'superuser', 'ma description'
                vtodo.addAlarm date
                cal.add vtodo
                cal.toString().should.equal """
                    BEGIN:VCALENDAR
                    VERSION:2.0
                    PRODID:-//Cozy Cloud//NONSGML Cozy Agenda//EN
                    BEGIN:VTODO
                    DTSTAMP:20130609T150000Z
                    SUMMARY:ma description
                    UID:superuser
                    BEGIN:VALARM
                    ACTION:DISPLAY
                    REPEAT:1
                    TRIGGER:20130609T150000Z
                    END:VALARM
                    END:VTODO
                    END:VCALENDAR""".replace(/\n/g, '\r\n')


        describe 'parse ical file', ->

            it 'should return a well formed vCalendar object', (done) ->
                parser = new ICalParser
                parser.parseFile 'test/calendar.ics', (err, result) ->
                    should.not.exist err
                    #result.toString().should.equal expectedContent
                    done()

            it 'should do the same for Apple calendar', (done) ->
                parser = new ICalParser
                parser.parseFile 'test/apple.ics', (err, result) ->
                    should.not.exist err
                    #result.toString().should.equal expectedContent
                    done()

            it 'should do the same for Google calendar', (done) ->
                parser = new ICalParser
                parser.parseFile 'test/google.ics', (err, result) ->
                    should.not.exist err
                    #result.toString().should.equal expectedContent
                    done()

        describe 'parse ical string', ->

            it 'should return a well formed vCalendar object', (done) ->
                parser = new ICalParser
                parser.parseString """
                    BEGIN:VCALENDAR
                    VERSION:2.0
                    PRODID:-//Cozy Cloud//NONSGML Cozy Agenda//EN
                    BEGIN:VTODO
                    DTSTAMP:20130609T150000Z
                    SUMMARY:ma description
                    UID:superuser
                    BEGIN:VALARM
                    ACTION:DISPLAY
                    REPEAT:1
                    TRIGGER:20130609T150000Z
                    END:VALARM
                    END:VTODO
                    END:VCALENDAR"""
                , (err, result) ->
                    should.not.exist err
                    #result.toString().should.equal expectedContent
                    done()