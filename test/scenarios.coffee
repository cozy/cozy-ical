path = require 'path'
should = require 'should'
moment = require 'moment-timezone'
{RRule} = require 'rrule'

{ICalParser, VCalendar, VAlarm, VTodo, VEvent} = require '../src/index'

fixturesPath = path.resolve __dirname, 'fixtures/scenarios'

describe "Parse iCal files from scenarios", ->

    # This test suite will be applied to iCal files from various sources
    # All the expored files should come from the same data set
    applyTest = (fileName, organization, title) -> ->

        it "shouldn't return an error", (done) ->
            parser = new ICalParser()
            filePath = "#{fixturesPath}/#{fileName}.ics"
            parser.parseFile filePath, (err, result) =>
                should.not.exist err
                @result = result
                done()

        it "and all components should validate", ->
            validateComponent = (component) ->
                component.validate.bind(component).should.not.throw()
                for subComponent in component.subComponents
                    validateComponent subComponent
            validateComponent @result

        it "and the calendar properties should be correctly set", ->
            calendar = @result.model
            should.exist calendar.organization
            should.exist calendar.title
            calendar.organization.should.equal organization
            calendar.title.should.equal title

        it "and should have the correct numbers of each components", ->
            componentsType = @result.subComponents.map (component) ->
                return Object.getPrototypeOf(component).name

            @byType = {}
            componentsType.reduce (previous, current, index) =>
                @byType[current] ?= []
                @byType[current].push @result.subComponents[index]
            , {}

            @byType['VEVENT'].length.should.equal 3


        it "and the vEvent object for 'Dentist' should be correctly set", ->
            testingEvent = null
            for event in @byType['VEVENT']
                if event.model.summary is 'Dentist'
                    testingEvent = event

            model = testingEvent.model
            model.should.have.properties 'uid', 'stampDate'
            model.should.have.property 'summary', 'Dentist'
            model.should.have.property 'location', 'Dentist office'
            model.should.have.properties 'startDate', 'endDate'
            expectedStartDate = moment.tz('2014-11-05 14:00:00', 'UTC').toISOString()
            expectedEndDate = moment.tz('2014-11-05 15:00:00', 'UTC').toISOString()
            model.startDate.toISOString().should.equal expectedStartDate
            model.endDate.toISOString().should.equal expectedEndDate

        it "and the vEvent object for 'Dentist' should be correctly set", ->
            testingEvent = null
            for event in @byType['VEVENT']
                if event.model.summary is 'Dentist'
                    testingEvent = event

            should.exist testingEvent
            model = testingEvent.model
            model.should.have.properties 'uid', 'stampDate'
            model.should.have.property 'summary', 'Dentist'
            model.should.have.property 'location', 'Dentist office'
            model.should.have.properties 'startDate', 'endDate'
            expectedStartDate = moment.tz('2014-11-05 14:00:00', 'UTC').toISOString()
            expectedEndDate = moment.tz('2014-11-05 15:00:00', 'UTC').toISOString()
            model.startDate.toISOString().should.equal expectedStartDate
            model.endDate.toISOString().should.equal expectedEndDate
            model.should.have.property 'timezone', null

        it "and the vEvent object for 'Recurring event' should be correctly set", ->
            testingEvent = null
            for event in @byType['VEVENT']
                if event.model.summary is 'Recurring event'
                    testingEvent = event

            should.exist testingEvent
            model = testingEvent.model
            model.should.have.properties 'uid', 'stampDate'
            model.should.have.property 'summary', 'Recurring event'
            model.should.have.property 'description', 'Crawling a hidden dungeon'
            model.should.have.property 'location', 'Hidden dungeon'
            model.should.have.properties 'startDate', 'endDate'
            expectedStartDate = moment.tz('2014-11-06 11:00:00', 'UTC').toISOString()
            expectedEndDate = moment.tz('2014-11-06 12:00:00', 'UTC').toISOString()
            model.startDate.toISOString().should.equal expectedStartDate
            model.endDate.toISOString().should.equal expectedEndDate
            model.should.have.property 'timezone', 'Europe/Paris'
            model.should.have.property 'rrule'
            model.rrule.should.have.properties 'freq', 'until'
            model.rrule.freq.should.equal RRule.WEEKLY
            expectedUntilDate = moment.tz '2015-01-01 11:00:00', 'UTC'
            untilDate = moment.tz model.rrule.until, 'UTC'

            # we assert that start of the day should be the same because
            # each provider does what he wants here
            untilDate
                .startOf('day').toISOString()
                .should.equal expectedUntilDate.startOf('day').toISOString()

        it "and the vEvent object for 'Friend's birthday' should be correctly set", ->
            testingEvent = null
            for event in @byType['VEVENT']
                if event.model.summary is "Friend's birthday"
                    testingEvent = event

            should.exist testingEvent
            model = testingEvent.model
            model.should.have.properties 'uid', 'stampDate'
            model.should.have.property 'summary', "Friend's birthday"
            model.should.have.property 'description', "Bring a present!"
            model.should.have.property 'location', "Friend's appartment"
            model.should.have.properties 'startDate', 'endDate', 'allDay'
            model.allDay.should.be.ok
            expectedStartDate = moment.tz('2014-11-07', 'UTC').toISOString()
            expectedEndDate = moment.tz('2014-11-08', 'UTC').toISOString()
            model.startDate.toISOString().should.equal expectedStartDate
            model.endDate.toISOString().should.equal expectedEndDate
            model.should.have.property 'timezone', null
            model.should.have.property 'rrule'
            model.rrule.should.have.property 'freq'
            model.rrule.freq.should.equal RRule.YEARLY

            model.should.have.property 'attendees'
            # some providers arbitrarily add the organizer in the attendees list
            # so we can't fix value here
            model.attendees.length.should.be.within 2, 3
            expectedAtLeast = ['randomgirl@provider.tld', 'randomguy@provider.tld']
            for expected in expectedAtLeast
                (expected in model.attendees).should.be.ok

    describe "When an iCal file from Lightning is parsed", applyTest 'lightning', 'Mozilla.org', 'Mozilla Calendar V1.1'
    describe "When an iCal file from Apple Calendar is parsed", applyTest 'apple', 'Apple Inc.', 'Mac OS X 10.9.5'
    describe "When an iCal file from Google Calendar is parsed", applyTest 'google', 'Google Inc', 'Google Calendar 70.9054'
    describe "When an iCal file from Radicale is parsed", applyTest 'radicale', 'Radicale', 'Radicale Server'
    describe "When an iCal file from Cozycloud is parsed", applyTest 'cozycloud', 'Cozy Cloud', 'Cozy Agenda'
