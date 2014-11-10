should = require 'should'
{VAlarm} = require '../src/index'
{MissingFieldError, FieldConflictError, InvalidValueError} = require '../src/errors'

describe "vAlarm", ->

    describe "Validation", ->
        it "should throw an error if a mandatory property 'action' is missing", ->
            options =
                trigger: 'PT30M'
            wrapper = -> alarm = new VAlarm options
            wrapper.should.throw MissingFieldError

        it "should throw an error if a mandatory property 'trigger' is missing", ->
            options =
                action: VAlarm.AUDIO_ACTION
            wrapper = -> alarm = new VAlarm options
            wrapper.should.throw MissingFieldError

        it "should throw an error if action is DISPLAY and 'description' is missing", ->
            options =
                trigger: 'PT30M'
                action: VAlarm.DISPLAY_ACTION
            wrapper = -> alarm = new VAlarm options
            wrapper.should.throw MissingFieldError

        it "should not throw an error if action is DISPLAY and all mandatory properties are found", ->
            options =
                trigger: 'PT30M'
                action: VAlarm.DISPLAY_ACTION
                description: 'My super description'
            wrapper = -> alarm = new VAlarm options
            wrapper.should.not.throw()

        it "should throw an error if action is not DISPLAY, EMAIL or AUDIO", ->
            options =
                trigger: 'PT30M'
                action: VAlarm.DISPLAY_ACTION
                description: 'My super description'
            wrapper = -> alarm = new VAlarm options
            wrapper.should.not.throw()

            options =
                trigger: 'PT30M'
                action: VAlarm.EMAIL_ACTION
                description: 'My super description'
                summary: 'My super summary'
                attendee: ['random@isp.tld']
            wrapper = -> alarm = new VAlarm options
            wrapper.should.not.throw()

            options =
                trigger: 'PT30M'
                action: VAlarm.AUDIO_ACTION
                description: 'My super description'
            wrapper = -> alarm = new VAlarm options
            wrapper.should.not.throw()

            options =
                trigger: 'PT30M'
                action: 'invalid action name'
                description: 'My super description'
            wrapper = -> alarm = new VAlarm options
            wrapper.should.throw InvalidValueError

        it "should throw an error if action is EMAIL and 'description' is missing", ->
            options =
                trigger: 'PT30M'
                action: VAlarm.EMAIL_ACTION
                summary: 'My super summary'
                attendee: ['random@isp.tld']
            wrapper = -> alarm = new VAlarm options
            wrapper.should.throw MissingFieldError

        it "should throw an error if action is EMAIL and 'summary' is missing", ->
            options =
                trigger: 'PT30M'
                action: VAlarm.EMAIL_ACTION
                description: 'My super description'
                attendee: ['random@isp.tld']
            wrapper = -> alarm = new VAlarm options
            wrapper.should.throw MissingFieldError

        it "should throw an error if action is EMAIL and 'attendee' is missing", ->
            options =
                trigger: 'PT30M'
                action: VAlarm.EMAIL_ACTION
                summary: 'My super summary'
                description: 'My super description'
            wrapper = -> alarm = new VAlarm options
            wrapper.should.throw MissingFieldError

        it "should not throw an error if action is EMAIL and all mandatory properties are found", ->
            options =
                trigger: 'PT30M'
                action: VAlarm.EMAIL_ACTION
                summary: 'My super summary'
                description: 'My super description'
                attendee: ['random@isp.tld']
            wrapper = -> alarm = new VAlarm options
            wrapper.should.not.throw()

    describe "Creating a vAlarm", ->
        it "should render properly", ->
            options =
                trigger: 'PT30M'
                action: VAlarm.EMAIL_ACTION
                summary: 'My super summary'
                description: 'My super description'
                attendee: ['random@isp.tld', 'random2@isp2.tld']
            alarm = new VAlarm options
            output = alarm.toString()
            output.should.equal """
                BEGIN:VALARM
                ACTION:#{options.action}
                TRIGGER:#{options.trigger}
                ATTENDEE:mailto:#{options.attendee[0]}
                ATTENDEE:mailto:#{options.attendee[1]}
                DESCRIPTION:#{options.description}
                SUMMARY:#{options.summary}
                END:VALARM""".replace /\n/g, '\r\n'

