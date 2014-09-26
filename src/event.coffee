moment = require 'moment-timezone'
timezones = require './timezones'

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

    Event.fromIcal = (vevent) ->
        #, timezone = "UTC") ->

        event = new Event()
        # timezone = 'UTC' unless timezones[timezone]
        timezone = 'UTC'

        event.description = vevent.fields["SUMMARY"] or
                            vevent.fields["DESCRIPTION"]
        event.details = vevent.fields["DESCRIPTION"] or
                            vevent.fields["SUMMARY"]

        event.place = vevent.fields["LOCATION"]
        event.rrule = vevent.fields["RRULE"]
        
        # Cas tordus ? défensive ?

        if vevent.fields['DTSTART-VALUE'] is 'DATE'
            event.start = moment.tz(vevent.fields['DTSTART'], VEvent.icalDateFormat, 'GMT').format(Event.dateFormat)
            event.end = moment.tz(vevent.fields['DTEND'], VEvent.icalDateFormat, 'GMT').format(Event.dateFormat)
            # end ...
        else 
            timezone = vevent.fields['DTSTART-TZID']
            timezone = 'GMT' unless timezones[timezone] # Filter by timezone list ...?
            
            if event.rrule
            # if timezone is not 'GMT'
                event.timezone = timezone
                event.start = moment.tz(vevent.fields['DTSTART'], VEvent.icalDTFormat, timezone).format(Event.ambiguousDTFormat)
                event.end = moment.tz(vevent.fields['DTEND'], VEvent.icalDTFormat, timezone).format(Event.ambiguousDTFormat)

            else
                event.start = moment.tz(vevent.fields['DTSTART'], VEvent.icalDTUTCFormat, 'GMT').format(Event.utcDTFormat)
                event.end = moment.tz(vevent.fields['DTEND'], VEvent.icalDTUTCFormat, 'GMT').format(Event.utcDTFormat)

        # Alarms
        alarms = [] 
        vevent.subComponents.forEach (c) ->
            if c.name is not 'VALARM'
                return

            trigg = c.fields['TRIGGER']
            action = c.fields['ACTION']
            if (trigg and trigg.match(Event.alarmTriggRegex)     and action in ['EMAIL', 'DISPLAY'])
                alarms.push(trigg: trigg, action: action)
        
        if alarms
            event.alarms = alarms

        event

    Event.extractEvents = (component, timezone) ->
        events = []
        timezone = 'UTC' unless timezones[timezone]
        component.walk (component) ->
            if component.name is 'VEVENT'
                events.push Event.fromIcal component, timezone

        events
