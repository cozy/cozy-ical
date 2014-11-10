should = require 'should'
moment = require 'moment-timezone'

{VTodo, VAlarm} = require '../src/index'
{MissingFieldError, FieldConflictError, FieldDependencyError} = require '../src/errors'

DTSTAMP_FORMATTER = 'YYYYMMDD[T]HHmm[00Z]'

describe "vTodo", ->

    describe "Validation", ->
        it "should throw an error if a mandatory property 'uid' is missing", ->
            options =
                stampDate: new Date 2014, 11, 4, 9, 30
            wrapper = -> todo = new VTodo options
            wrapper.should.throw MissingFieldError

        it "should throw an error if a mandatory property 'stampDate' is missing", ->
            options =
                uid: 'abcd-1234'
            wrapper = -> todo = new VTodo options
            wrapper.should.throw MissingFieldError

        it "should not throw if all mandatory properties are found", ->
            options =
                uid: 'abcd-1234'
                stampDate: new Date 2014, 11, 4, 9, 30
            wrapper = -> todo = new VTodo options
            wrapper.should.not.throw()

        it "should throw an error if 'due' and 'duration' are both found", ->
            options =
                uid: 'abcd-1234'
                stampDate: new Date 2014, 11, 4, 9, 30
                due: new Date 2014, 11, 10
                duration: 'PT15M'
            wrapper = -> todo = new VTodo options
            wrapper.should.throw FieldConflictError

        it "should throw an error if 'duration' is found but 'startDate' is missing", ->
            options =
                uid: 'abcd-1234'
                stampDate: new Date 2014, 11, 4, 9, 30
                duration: 'PT15M'
            wrapper = -> todo = new VTodo options
            wrapper.should.throw FieldDependencyError

    describe "Creating a vTodo without alarm", ->
        it "should render properly", ->
            options =
                uid: 'abcd-1234'
                stampDate: new Date 2014, 11, 4, 9, 30

            formattedStampDate = moment(options.stampDate).format DTSTAMP_FORMATTER

            todo = new VTodo options
            output = todo.toString()
            output.should.equal """
                BEGIN:VTODO
                UID:#{options.uid}
                DTSTAMP:#{formattedStampDate}
                END:VTODO""".replace /\n/g, '\r\n'

    describe "Creating a vTodo with alarms", ->
        it "should render properly", ->
            options =
                uid: 'abcd-1234'
                stampDate: new Date 2014, 11, 4, 9, 30

            formattedStampDate = moment(options.stampDate).format DTSTAMP_FORMATTER

            todo = new VTodo options

            alarmOptions =
                action: VAlarm.EMAIL_ACTION
                trigger: 'PT30M'
                summary: 'My super summary'
                description: 'My super description'
                attendee: ['random@isp.tld', 'random2@isp2.tld']

            todo.addAlarm alarmOptions

            # renders the alarm to compute the expected result
            alarm = new VAlarm alarmOptions

            # changes the end of line char so it can be converted back
            alarmOutput = alarm.toString().replace /\r\n/g, '\n'

            output = todo.toString()
            output.should.equal """
                BEGIN:VTODO
                UID:#{options.uid}
                DTSTAMP:#{formattedStampDate}
                #{alarmOutput}
                END:VTODO""".replace /\n/g, '\r\n'
