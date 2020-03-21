should = require 'should'
moment = require 'moment-timezone'
time = require 'time'
{RRule} = require 'rrule'
{VEvent} = require '../src/index'
{MissingFieldError, FieldConflictError} = require '../src/errors'

DTSTAMP_FORMATTER = 'YYYYMMDD[T]HHmm[00Z]'

describe "vEvent", ->

    describe "Validation", ->
        it "should throw an error if a mandatory property 'uid' is missing", ->
            options =
                stampDate: new Date 2014, 11, 4, 9, 30
                startDate: new Date 2014, 11, 4, 9, 30
            wrapper = -> event = new VEvent options
            wrapper.should.throw MissingFieldError

        it "should throw an error if a mandatory property 'stampDate' is missing", ->
            options =
                uid: 'abcd-1234'
                startDate: new Date 2014, 11, 4, 9, 30
            wrapper = -> event = new VEvent options
            wrapper.should.throw MissingFieldError

        it "should throw an error if a mandatory property 'startDate' is missing", ->
            options =
                uid: 'abcd-1234'
                stampDate: new Date 2014, 11, 4, 9, 30
            wrapper = -> event = new VEvent options
            wrapper.should.throw MissingFieldError

        it "should not throw an error if all mandatory properties are found", ->
            options =
                uid: 'abcd-1234'
                stampDate: new Date 2014, 11, 4, 9, 30
                startDate: new Date 2014, 11, 4, 9, 30
            wrapper = -> event = new VEvent options
            wrapper.should.not.throw()

        it "should throw an error if 'endDate' and 'duration' properties are both found", ->
            options =
                uid: 'abcd-1234'
                stampDate: new Date 2014, 11, 4, 9, 30
                startDate: new Date 2014, 11, 4, 9, 30
                endDate: new Date 2014, 11, 4, 10, 30
                duration: 'PT15M'
            wrapper = -> event = new VEvent options
            wrapper.should.throw FieldConflictError

    describe "Creating a vEvent for punctual event without timezone", ->
        it "should render properly", ->
            options =
                uid: '[id-1]'
                stampDate: Date.UTC 2014, 11, 4, 9, 30
                startDate: Date.UTC 2014, 11, 4, 9, 30
                endDate: Date.UTC 2014, 11, 4, 10, 30
                summary: 'Event summary'
                location: 'some place'
                created: '2014-11-10T14:00:00.000Z'
                lastModification: '2014-11-21T13:30:00.000Z'
            event = new VEvent options
            output = event.toString()
            output.should.equal """
                BEGIN:VEVENT
                UID:#{options.uid}
                DTSTAMP:20141204T093000Z
                DTSTART:20141204T093000Z
                DTEND:20141204T103000Z
                CREATED:20141110T140000Z
                LAST-MODIFIED:20141121T133000Z
                LOCATION:#{options.location}
                SUMMARY:#{options.summary}
                END:VEVENT""".replace /\n/g, '\r\n'

    describe "Creating a vEvent for a punctual event with a timezone", ->
        it "should render properly", ->
            options =
                uid: '[id-1]'
                stampDate: Date.UTC 2014, 11, 4, 9, 30
                startDate: Date.UTC 2014, 11, 4, 9, 30
                endDate: Date.UTC 2014, 11, 4, 10, 30
                summary: 'Event summary'
                timezone: 'Europe/Paris'

            event = new VEvent options
            output = event.toString()
            output.should.equal """
                BEGIN:VEVENT
                UID:#{options.uid}
                DTSTAMP:20141204T093000Z
                DTSTART;TZID=Europe/Paris:20141204T103000
                DTEND;TZID=Europe/Paris:20141204T113000
                SUMMARY:#{options.summary}
                END:VEVENT""".replace /\n/g, '\r\n'

    describe "Creating a vEvent for all-day event", ->
         it "should render properly", ->
            options =
                uid: '[id-1]'
                stampDate: Date.UTC 2014, 11, 4
                startDate: Date.UTC 2014, 11, 4
                endDate: Date.UTC 2014, 11, 4
                summary: 'Event summary'
                location: 'some place'
                allDay: true

            event = new VEvent options
            output = event.toString()
            output.should.equal """
                BEGIN:VEVENT
                UID:#{options.uid}
                DTSTAMP:20141204T000000Z
                DTSTART;VALUE=DATE:20141204
                DTEND;VALUE=DATE:20141204
                LOCATION:#{options.location}
                SUMMARY:#{options.summary}
                END:VEVENT""".replace /\n/g, '\r\n'

    describe "Creating a vEvent for recurring event", ->
        it "should render properly", ->
            # defines recurrence rule
            ruleOptions =
                freq: RRule.WEEKLY
                interval: 2
                until: new Date 2015, 1, 30
                byweekday: [0, 4]

            options =
                uid: '[id-1]'
                stampDate: Date.UTC 2014, 11, 4
                startDate: Date.UTC 2014, 11, 4
                rrule:
                    freq: ruleOptions.freq
                    interval: ruleOptions.interval
                    until: ruleOptions.until
                    byweekday: ruleOptions.byweekday
                summary: 'Event summary'
                timezone: 'Europe/Paris'

            # `options.rrule` is not used because RRule changes it when
            # it proceses it (resulting in it not being able to be used afterwards)
            rrule = new RRule
                freq: ruleOptions.freq
                interval: ruleOptions.interval
                until: ruleOptions.until
                byweekday: ruleOptions.byweekday

            event = new VEvent options
            output = event.toString()
            output.should.equal """
                BEGIN:VEVENT
                UID:#{options.uid}
                DTSTAMP:20141204T000000Z
                DTSTART;TZID=Europe/Paris:20141204T010000
                RRULE:#{rrule}
                SUMMARY:#{options.summary}
                END:VEVENT""".replace /\n/g, '\r\n'

    describe "Creating a vEvent for recurring all-day event", ->
        it "should render properly", ->
            # defines recurrence rule
            ruleOptions =
                freq: RRule.YEARLY
                until: new Date 2015, 1, 30

            options =
                uid: '[id-1]'
                stampDate: Date.UTC 2014, 11, 4
                startDate: Date.UTC 2014, 11, 4
                rrule:
                    freq: ruleOptions.freq
                    until: ruleOptions.until
                summary: 'Birthday event'
                timezone: 'Europe/Paris'
                allDay: true

            # `options.rrule` is not used because RRule changes it when
            # it proceses it (resulting in it not being able to be used afterwards)
            rrule = new RRule
                freq: ruleOptions.freq
                until: ruleOptions.until

            event = new VEvent options
            output = event.toString()
            output.should.equal """
                BEGIN:VEVENT
                UID:#{options.uid}
                DTSTAMP:20141204T000000Z
                DTSTART;VALUE=DATE:20141204
                RRULE:#{rrule}
                SUMMARY:#{options.summary}
                END:VEVENT""".replace /\n/g, '\r\n'

    describe "Creating a vEvent with attendees", ->
         it "should render properly", ->
            options =
                uid: '[id-1]'
                stampDate: Date.UTC 2014, 11, 4, 10, 0
                startDate: Date.UTC 2014, 11, 4, 10, 0
                endDate: Date.UTC 2014, 11, 4, 11, 0
                summary: 'Event summary'
                location: 'some place'
                attendees: [
                    email: 'test@provider.tld', details: status: 'NEEDS-ACTION'
                ]

            event = new VEvent options
            output = event.toString()
            expectedEmail = options.attendees[0].email
            output.should.equal """
                BEGIN:VEVENT
                UID:#{options.uid}
                DTSTAMP:20141204T100000Z
                DTSTART:20141204T100000Z
                DTEND:20141204T110000Z
                ATTENDEE;PARTSTAT=NEEDS-ACTION;CN=#{expectedEmail}:mailto:#{expectedEmail}
                LOCATION:#{options.location}
                SUMMARY:#{options.summary}
                END:VEVENT""".replace /\n/g, '\r\n'

    describe 'Timezone support for vEvents', ->
        it 'should support timezones, set on Date objects', ->
            startDate = new time.Date 2013, 5, 9, 15, 0, 0, 'Europe/Moscow'
            endDate = new time.Date 2013, 5, 10, 15, 0, 0, 'Europe/Moscow'
            vevent = new VEvent
                stampDate: Date.UTC 2013, 5, 9, 15
                startDate: startDate
                endDate: endDate
                summary: "desc"
                location: "loc"
                uid: "3615"
            vevent.toString().should.equal """
                BEGIN:VEVENT
                UID:3615
                DTSTAMP:20130609T150000Z
                DTSTART;TZID=Europe/Moscow:20130609T150000
                DTEND;TZID=Europe/Moscow:20130610T150000
                LOCATION:loc
                SUMMARY:desc
                END:VEVENT""".replace /\n/g, '\r\n'

        it 'should support timezones, set via property', ->
            startDate = new time.Date 2013, 5, 9, 11, 0, 0, 'UTC'
            endDate = new time.Date 2013, 5, 10, 11, 0, 0, 'UTC'
            vevent = new VEvent
                stampDate: Date.UTC 2013, 5, 9, 15
                startDate: startDate
                endDate: endDate
                summary: "desc"
                location: "loc"
                timezone: "Europe/Moscow"
                uid: "3615"

            vevent.toString().should.equal """
                BEGIN:VEVENT
                UID:3615
                DTSTAMP:20130609T150000Z
                DTSTART;TZID=Europe/Moscow:20130609T150000
                DTEND;TZID=Europe/Moscow:20130610T150000
                LOCATION:loc
                SUMMARY:desc
                END:VEVENT""".replace /\n/g, '\r\n'

        it 'should support whole day events with timezones', ->
            startDate = new time.Date 2013, 5, 9, 15, 0, 0
            endDate = new time.Date 2013, 5, 10, 15, 0, 0
            startDate.setTimezone 'Europe/Moscow'
            endDate.setTimezone 'Europe/Moscow'
            vevent = new VEvent
                stampDate: Date.UTC 2013, 5, 9, 15
                startDate: startDate
                endDate: endDate
                summary: "desc"
                location: "loc"
                timezone: "Europe/Moscow"
                uid: "3615"
                allDay: true
            vevent.toString().should.equal """
                BEGIN:VEVENT
                UID:3615
                DTSTAMP:20130609T150000Z
                DTSTART;VALUE=DATE:20130609
                DTEND;VALUE=DATE:20130610
                LOCATION:loc
                SUMMARY:desc
                END:VEVENT""".replace /\n/g, '\r\n'

    describe "Creating a vEvent with multiline DESCRIPTION", ->
        it "should render properly", ->
            options =
                uid: '[id-1]'
                stampDate: Date.UTC 2014, 11, 4, 9, 30
                startDate: Date.UTC 2014, 11, 4, 9, 30
                endDate: Date.UTC 2014, 11, 4, 10, 30
                summary: 'Event summary, should escape ";"'
                location: 'some place'
                description: 'Event description on, \n line 2,\n line 3.'
                created: '2014-11-10T14:00:00.000Z'
                lastModification: '2014-11-21T13:30:00.000Z'
            event = new VEvent options
            output = event.toString()
            output.should.equal """
                BEGIN:VEVENT
                UID:#{options.uid}
                DTSTAMP:20141204T093000Z
                DTSTART:20141204T093000Z
                DTEND:20141204T103000Z
                CREATED:20141110T140000Z
                DESCRIPTION:Event description on\\, \\n line 2\\,\\n line 3.
                LAST-MODIFIED:20141121T133000Z
                LOCATION:#{options.location}
                SUMMARY:Event summary\\, should escape "\\;"
                END:VEVENT""".replace /\n/g, '\r\n'

    describe "Creating a vEvent with an ORGANIZER", ->
        it "should render properly with the simple form", ->
            options =
                uid: '[id-1]'
                stampDate: Date.UTC 2014, 11, 4, 9, 30
                startDate: Date.UTC 2014, 11, 4, 9, 30
                endDate: Date.UTC 2014, 11, 4, 10, 30
                summary: 'Test'
                location: 'some place'
                created: '2014-11-10T14:00:00.000Z'
                lastModification: '2014-11-21T13:30:00.000Z'
                organizer: 'john.doe@test.com'
            event = new VEvent options
            output = event.toString()
            output.should.equal """
                BEGIN:VEVENT
                UID:#{options.uid}
                DTSTAMP:20141204T093000Z
                DTSTART:20141204T093000Z
                DTEND:20141204T103000Z
                CREATED:20141110T140000Z
                LAST-MODIFIED:20141121T133000Z
                LOCATION:#{options.location}
                ORGANIZER:mailto:john.doe@test.com
                SUMMARY:Test
                END:VEVENT""".replace /\n/g, '\r\n'

        it "should render properly with the complex form", ->
            options =
                uid: '[id-1]'
                stampDate: Date.UTC 2014, 11, 4, 9, 30
                startDate: Date.UTC 2014, 11, 4, 9, 30
                endDate: Date.UTC 2014, 11, 4, 10, 30
                summary: 'Test'
                location: 'some place'
                created: '2014-11-10T14:00:00.000Z'
                lastModification: '2014-11-21T13:30:00.000Z'
                organizer: displayName: 'John Doe', email: 'john.doe@test.com'
            event = new VEvent options
            output = event.toString()
            output.should.equal """
                BEGIN:VEVENT
                UID:#{options.uid}
                DTSTAMP:20141204T093000Z
                DTSTART:20141204T093000Z
                DTEND:20141204T103000Z
                CREATED:20141110T140000Z
                LAST-MODIFIED:20141121T133000Z
                LOCATION:#{options.location}
                ORGANIZER;CN=John Doe:mailto:john.doe@test.com
                SUMMARY:Test
                END:VEVENT""".replace /\n/g, '\r\n'
