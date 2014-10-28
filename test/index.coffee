main = require '../lib/index'
{ICalParser, VCalendar, VAlarm, VTodo, VEvent} = main
{decorateAlarm, decorateEvent} = main
should = require 'should'
moment = require 'should'

helpers = null
describe "Calendar export/import", ->

    describe 'ical helpers', ->

        describe 'get vCalendar string', ->
            it 'should return default vCalendar string', ->
                cal = new VCalendar
                    organization: 'Cozy Cloud'
                    title: 'Cozy Agenda'
                cal.toString().should.equal """
                    BEGIN:VCALENDAR
                    VERSION:2.0
                    PRODID:-//Cozy Cloud//NONSGML Cozy Agenda//EN
                    END:VCALENDAR""".replace(/\n/g, '\r\n')

        describe 'get vAlarm string', ->
            it 'should return default vAlarm string', ->
                valarm = new VAlarm
                    trigger: '-PT10M'
                    action: 'DISPLAY'
                    description: 'Wake UP!' # description
                    # attendee, summary .. ?

                valarm.toString().should.equal """
                    BEGIN:VALARM
                    ACTION:DISPLAY
                    TRIGGER:-PT10M
                    DESCRIPTION:Wake UP!
                    END:VALARM""".replace(/\n/g, '\r\n')

        describe 'get vTodo string', ->
            it 'should return default vTodo string', ->
                date = new Date 2013, 5, 9, 15, 0, 0
                vtodo = new VTodo
                    startDate: date
                    uid: "3615",  #uid
                    summary: "ma description" # summary
                    #description
                vtodo.toString().should.equal """
                    BEGIN:VTODO
                    DTSTART:20130609T150000Z
                    SUMMARY:ma description
                    DURATION:PT30M
                    UID:3615
                    END:VTODO""".replace(/\n/g, '\r\n')

        describe 'get vEvent string', ->
            it 'should return default vEvent string', ->
                startDate = new Date 2013, 5, 9, 15, 0, 0
                endDate = new Date 2013, 5, 10, 15, 0, 0
                vevent = new VEvent
                    startDate: startDate
                    endDate: endDate
                    summary: "desc"
                    location: "loc"
                    uid: "3615"
                vevent.toString().should.equal """
                    BEGIN:VEVENT
                    SUMMARY:desc
                    LOCATION:loc
                    UID:3615
                    DTSTART:20130609T150000Z
                    DTEND:20130610T150000Z
                    END:VEVENT""".replace(/\n/g, '\r\n')

        describe 'get vCalendar with alarms', ->
            it 'should return ical string', ->
                date = new Date 2013, 5, 9, 15, 0, 0

                cal = new VCalendar
                    organization: 'Cozy Cloud'
                    title: 'Cozy Agenda'

                vtodo = new VTodo
                    startDate: date
                    uid: 'superuser'
                    summary: 'ma description'
                    action: 'DISPLAY'
                vtodo.addAlarm
                    startDate: date
                    action: 'DISPLAY'

                cal.add vtodo
                cal.toString().should.equal """
                    BEGIN:VCALENDAR
                    VERSION:2.0
                    PRODID:-//Cozy Cloud//NONSGML Cozy Agenda//EN
                    BEGIN:VTODO
                    DTSTART:20130609T150000Z
                    SUMMARY:ma description
                    DURATION:PT30M
                    UID:superuser
                    BEGIN:VALARM
                    ACTION:DISPLAY
                    TRIGGER:PT0M
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

                    event = result.subComponents[1]
                    desc = event.fields['DESCRIPTION']
                    desc.indexOf('tellement complet qu').should.not.equal -1
                    should.exist event.fields['RRULE']

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
                    TRIGGER;VALUE=DATE-TIME:20130609T150000Z
                    END:VALARM
                    END:VTODO
                    END:VCALENDAR"""
                , (err, result) ->
                    should.not.exist err
                    #result.toString().should.equal expectedContent
                    done()

        describe 'decorators', ->

            Alarm = class Alarm
            Event = class Event

            it 'should decorate without error', ->
                decorateAlarm Alarm
                decorateEvent Event

            it 'should add Alarm.extractAlarms', (done) ->

                new ICalParser().parseString """
                    BEGIN:VCALENDAR
                    VERSION:2.0
                    PRODID:-//Cozy Cloud//NONSGML Cozy Agenda//EN
                    BEGIN:VTODO
                    SUMMARY:this is a title
                    UID:3615
                    BEGIN:VALARM
                    ACTION:DISPLAY
                    REPEAT:1
                    TRIGGER;VALUE=DATE-TIME:20130609T150000Z
                    END:VALARM
                    END:VTODO
                    END:VCALENDAR
                """, (err, comp) =>
                    should.not.exist err
                    @alarm = Alarm.extractAlarms(comp, 'BadTimezone')[0]
                    @alarm.id.should.equal '3615'
                    @alarm.description.should.equal 'this is a title'
                    done()

            it 'and Alarm::toIcal()', ->
                ical = @alarm.toIcal()
                ical.fields['SUMMARY'].should.equal ical.fields['DESCRIPTION']


            it 'should add Event.extractEvents', (done) ->

                new ICalParser().parseFile 'test/google.ics', (err, comp) =>
                    should.not.exist err
                    events = Event.extractEvents(comp)
                    @event = events[1]
                    # @event.timezone.should.equal 'Europe/Paris'
                    @event.description.should.equal 'Un événement'
                    @event.start.should.equal 'Tue Jul 30 2013 12:30:00' # UTC
                    should.exist @event.details

                    event2 = events[0]
                    event2.start.should.equal 'Wed Jul 31 2013 16:00:00' # UTC
                    should.exist event2.rrule
                    done()

            it 'and Event::toIcal()', ->
                ical = @event.toIcal()
                ical.fields['DESCRIPTION'].should.equal """
                    description de l'événement
                """
