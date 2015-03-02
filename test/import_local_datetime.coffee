path = require 'path'
should = require 'should'
moment = require 'moment-timezone'

{ICalParser, VCalendar, VAlarm, VTodo, VEvent} = require '../src/index'

dateFormat = 'YYYY-MM-DD HH:mm:ss Z'

# Local date time are datetime with no timezone information
# e.g. DTSTART:20150328T095500
describe.only "Import ICS with local date time (no timezone indicator)", ->

    DEFAULT_TIMEZONE = 'Europe/Moscow'

    it "shouldn't return an error", (done) ->
        parser = new ICalParser()
        fixturesPath = path.resolve __dirname, 'fixtures'
        filePath = "#{fixturesPath}/locale_datetime.ics"
        options = defaultTimezone: DEFAULT_TIMEZONE
        parser.parseFile filePath, options, (err, result) =>
            should.not.exist err
            @result = result
            should.exist @result
            @result.should.have.property 'subComponents'
            @result.subComponents.length.should.equal 1
            done()

    it 'and there should be one event', ->
        @event = @result.subComponents[0]
        should.exist @event
        @event.should.have.property 'model'

    it "and the event should have the proper timezone", ->
        {model} = @event
        expectedStart = moment
            .tz '2015-03-28 09:55:00', DEFAULT_TIMEZONE
            .tz 'UTC'
            .format()
        moment model.startDate
            .tz 'UTC'
            .format()
            .should.equal expectedStart

        expectedEnd = moment
            .tz '2015-03-28 11:56:00', DEFAULT_TIMEZONE
            .tz 'UTC'
            .format()
        moment model.endDate
            .tz 'UTC'
            .format()
            .should.equal expectedEnd

