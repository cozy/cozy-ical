time = require 'time'
moment = require 'moment'

module.exports = (Event) ->
    {VCalendar, VEvent} = require './index'

    Event::toIcal = (timezone = "UTC") ->
        startDate = new time.Date @start
        endDate   = new time.Date @end
        startDate.setTimezone timezone, false
        endDate.setTimezone timezone, false
        new VEvent startDate, endDate, @description, @place, @id

    Event.fromIcal = (vevent, timezone = "UTC") ->
        event = new Event()
        event.description = vevent.fields["DESCRIPTION"]
        event.description ?= vevent.fields["SUMMARY"]
        event.place = vevent.fields["LOCATION"]
        startDate = vevent.fields["DTSTART"]
        startDate = moment startDate, "YYYYMMDDTHHmm00"
        startDate = new time.Date new Date(startDate), timezone
        endDate = vevent.fields["DTEND"]
        endDate = moment endDate, "YYYYMMDDTHHmm00"
        endDate = new time.Date new Date(endDate), timezone
        event.timezone = timezone
        event.start = startDate.toString().slice(0, 24)
        event.end = endDate.toString().slice(0, 24)
        event

    Event.extractEvents = (component, timezone) ->
        events = []
        component.walk (component) ->
            if component.name is 'VTIMEZONE'
                timezone = component.fields["TZID"]
            if component.name is 'VEVENT'
                events.push Event.fromIcal component, timezone

        events
