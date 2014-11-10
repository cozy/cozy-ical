should = require 'should'
{VCalendar} = require '../src/index'
{MissingFieldError} = require '../src/errors'

describe "vCalendar", ->

    describe "Validation", ->
        it "should throw an error if 'title' property is missing", ->
           options =
                organization: 'testorg'
            wrapper = => calendar = new VCalendar options
            wrapper.should.throw MissingFieldError

        it "should throw an error if 'organization' property is missing", ->
           options =
                title: 'testname'
            wrapper = => calendar = new VCalendar options
            wrapper.should.throw MissingFieldError

        it "should not throw an error if all mandatory properties are found", ->
            options =
                title: 'testname'
                organization: 'testorg'
            wrapper = => calendar = new VCalendar options
            wrapper.should.not.throw()

    describe "Creating a vCalendar object with options", ->
        it "should render to string properly", ->
            organization = 'testorg'
            title = 'testname'
            expectedVersion = '2.0'

            calendar = new VCalendar {organization, title}
            output = calendar.toString()
            output.should.equal """
                BEGIN:VCALENDAR
                VERSION:#{expectedVersion}
                PRODID:-//#{organization}//NONSGML #{title}//EN
                END:VCALENDAR""".replace /\n/g, '\r\n'
