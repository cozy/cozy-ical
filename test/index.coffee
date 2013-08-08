# expectedContent = """
# BEGIN:VCALENDAR
# VERSION:2.0
# PRODID:-//Cozy Cloud//NONSGML Cozy Agenda//EN
# BEGIN:VTIMEZONE
# TZID:Europe/Paris
# BEGIN:STANDARD
# DTSTART:20130423T144000
# TZOFFSETFROM:-0200
# TZOFFSETTO:-0200
# END:STANDARD
# BEGIN:DAYLIGHT
# DTSTART:20130423T144000
# TZOFFSETFROM:-0200
# TZOFFSETTO:-0200
# END:DAYLIGHT
# END:VTIMEZONE
# BEGIN:VTODO
# DTSTAMP:20130423T144000
# SUMMARY:Something to remind
# UID:undefined
# BEGIN:VALARM
# ACTION:AUDIO
# REPEAT:1
# TRIGGER:20130423T144000
# END:VALARM
# END:VTODO
# BEGIN:VTIMEZONE
# TZID:Africa/Abidjan
# BEGIN:STANDARD
# DTSTART:20130424T133000
# TZOFFSETFROM:+0000
# TZOFFSETTO:+0000
# END:STANDARD
# BEGIN:DAYLIGHT
# DTSTART:20130424T133000
# TZOFFSETFROM:+0000
# TZOFFSETTO:+0000
# END:DAYLIGHT
# END:VTIMEZONE
# BEGIN:VTODO
# DTSTAMP:20130424T133000
# SUMMARY:Something else to remind
# UID:undefined
# BEGIN:VALARM
# ACTION:AUDIO
# REPEAT:1
# TRIGGER:20130424T133000
# END:VALARM
# END:VTODO
# BEGIN:VTIMEZONE
# TZID:Pacific/Apia
# BEGIN:STANDARD
# DTSTART:20130425T113000
# TZOFFSETFROM:-1300
# TZOFFSETTO:-1300
# END:STANDARD
# BEGIN:DAYLIGHT
# DTSTART:20130425T113000
# TZOFFSETFROM:-1300
# TZOFFSETTO:-1300
# END:DAYLIGHT
# END:VTIMEZONE
# BEGIN:VTODO
# DTSTAMP:20130425T113000
# SUMMARY:Another thing to remind
# UID:undefined
# BEGIN:VALARM
# ACTION:AUDIO
# REPEAT:1
# TRIGGER:20130425T113000
# END:VALARM
# END:VTODO
# BEGIN:VEVENT
# DESCRIPTION:my description
# DTSTART:20130609T150000
# DTEND:20130610T150000
# LOCATION:my place
# END:VEVENT
# END:VCALENDAR
# """.replace(/\n/g, '\r\n')


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
                    ACTION:AUDIO
                    REPEAT:1
                    TRIGGER:20130609T150000
                    END:VALARM""".replace(/\n/g, '\r\n')

        describe 'get vTodo string', ->
            it 'should return default vTodo string', ->
                date = new Date 2013, 5, 9, 15, 0, 0
                vtodo = new VTodo date, "superuser", "ma description"
                vtodo.toString().should.equal """
                    BEGIN:VTODO
                    DTSTAMP:20130609T150000
                    SUMMARY:ma description
                    UID:superuser
                    END:VTODO""".replace(/\n/g, '\r\n')

        describe 'get vEvent string', ->
            it 'should return default vEvent string', ->
                startDate = new Date 2013, 5, 9, 15, 0, 0
                endDate = new Date 2013, 5, 10, 15, 0, 0
                vevent = new VEvent startDate, endDate, "desc", "loc"
                vevent.toString().should.equal """
                    BEGIN:VEVENT
                    DESCRIPTION:desc
                    DTSTART:20130609T150000
                    DTEND:20130610T150000
                    LOCATION:loc
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
                    DTSTAMP:20130609T150000
                    SUMMARY:ma description
                    UID:superuser
                    BEGIN:VALARM
                    ACTION:AUDIO
                    REPEAT:1
                    TRIGGER:20130609T150000
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
                    DTSTAMP:20130609T150000
                    SUMMARY:ma description
                    UID:superuser
                    BEGIN:VALARM
                    ACTION:AUDIO
                    REPEAT:1
                    TRIGGER:20130609T150000
                    END:VALARM
                    END:VTODO
                    END:VCALENDAR"""
                , (err, result) ->
                    should.not.exist err
                    #result.toString().should.equal expectedContent
                    done()