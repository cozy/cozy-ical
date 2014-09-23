moment = require 'moment-timezone'
timezones = require './timezones'


icalDateToUTC = (date, tzid) ->
    isUTC = date[date.length - 1] is 'Z'
    mdate = moment date, "YYYYMMDDTHHmm00"
    if isUTC
        tdate = new time.Date mdate, 'UTC'
    else
        tdate = new time.Date mdate, tzid
        tdate.setTimezone 'UTC'
    return tdate


module.exports = (Event) ->
    {VCalendar, VEvent, VAlarm} = require './index'

    # Event::toIcal = (timezone = "UTC") ->
    Event::toIcal = ->
        # Stay in event locale timezone for recurrent events.
        timezone = (if @rrule then @timezone else 'GMT')

        event = new VEvent(
            moment.tz(@start, timezone),
            moment.tz(@end, timezone),
            @description, @place, @id, @details, 
            @start.length == 10, # allDay
            @rrule, @timezone)

        @alarms?.forEach (alarm) =>
            if alarm.action in ['DISPLAY', 'BOTH']
                event.add new VAlarm(alarm.trigg, 'DISPLAY', @description)

            if alarm.action in ['EMAIL', 'BOTH']
                event.add new VAlarm(alarm.trigg, 'EMAIL',
                "#{@description} #{@details}",
                'example@example.com',#TODO : get the user address.
                @description)


        return event

    Event.fromIcal = (vevent, timezone = "UTC") ->

        event = new Event()
        # timezone = 'UTC' unless timezones[timezone]
        timezone = 'UTC'

        event.description = vevent.fields["SUMMARY"] or
                            vevent.fields["DESCRIPTION"]
        event.details = vevent.fields["DESCRIPTION"] or
                            vevent.fields["SUMMARY"]

        event.place = vevent.fields["LOCATION"]
        event.rrule = vevent.fields["RRULE"]
        #
        # Punctual event start en end.

        #
        tzStart = vevent.fields['DTSTART-TZID'] or timezone
        tzStart = 'UTC' unless timezones[tzStart] # Filter by timezone list ...?
        # startDate = icalDateToUTC vevent.fields["DTSTART"], tzStart
        event.start = moment.tz(vevent.fields['DTSTART'], vevent.icalDTFormat, tzStart).toISOString()
        # TODO : handle full day ...

        
        tzEnd = vevent.fields["DTEND-TZID"] or timezone
        tzEnd = 'UTC' unless timezones[tzEnd]
        event.end = moment.tz(vevent.fields['DTEND'], vevent.icalDTFormat, tzEnd).toISOString()

        # recurrent events :
        if event.rrule
            event.timezone = tzStart
            event.start = event.start.slice(0, -1)
            event.end = event.end.slice(0,-1)

        # endDate = icalDateToUTC vevent.fields["DTEND"], tzEnd

        # event.start = startDate.toString().slice 0, 24
        # event.end = endDate.toString().slice 0, 24
        event

    Event.extractEvents = (component, timezone) ->
        events = []
        timezone = 'UTC' unless timezones[timezone]
        component.walk (component) ->
            if component.name is 'VEVENT'
                events.push Event.fromIcal component, timezone

        events
