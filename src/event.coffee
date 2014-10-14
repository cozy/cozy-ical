moment = require 'moment-timezone'
timezones = require './timezones'
RRule = require('rrule').RRule

module.exports = (Event) ->
    {VCalendar, VEvent, VAlarm} = require './index'

    # Return VEvent object or undefined if mandatory elements miss.
    # CAUTION : skip Attendees and EMAIL reminders.
    Event::toIcal = ->
        allDay = @start.length is 10

        # Stay in event locale timezone for recurring events.
        timezone = 'UTC' # Default for non recurring events.
        if @rrule
            if @timezone?
                timezone = @timezone

            else if not allDay
                console.log "Recurring events need timezone."
                return undefined

        try
            event = new VEvent 
                moment.tz @start, timezone,
                moment.tz @end, timezone,
                @description, @place, @id, @details, 
                allDay,
                @rrule, @timezone
        catch e then return undefined # all those elements are mandatory.
 
        @alarms?.forEach (alarm) =>
            if alarm.action in ['DISPLAY', 'BOTH']
                event.add new VAlarm alarm.trigg, 'DISPLAY', @description

            # else : ignore other actions.

        return event

    # Return a valid Event object, or undefined.
    Event.fromIcal = (vevent) ->
        event = new Event()

        event.description = vevent.fields["SUMMARY"] or
                            vevent.fields["DESCRIPTION"]
        if not event.description
            return undefined

        event.details = vevent.fields["DESCRIPTION"] or
                            vevent.fields["SUMMARY"]

        event.place = vevent.fields["LOCATION"]

        rruleStr = vevent.fields["RRULE"]
        event.rrule = vevent.fields["RRULE"]

        

        try # .start and .end are required.
            if vevent.fields['DTSTART-VALUE'] is 'DATE'
                event.start = moment.tz(vevent.fields['DTSTART'], VEvent.icalDateFormat, 'GMT').format Event.dateFormat
                event.end = moment.tz(vevent.fields['DTEND'], VEvent.icalDateFormat, 'GMT').format Event.dateFormat

            else 
                timezone = vevent.fields['DTSTART-TZID']
                timezone = 'UTC' unless timezones[timezone] # Filter by timezone list.
                
                if timezone isnt 'UTC'
                    start = moment.tz vevent.fields['DTSTART'], VEvent.icalDTFormat, timezone
                    end = moment.tz vevent.fields['DTEND'], VEvent.icalDTFormat, timezone

                else
                    start = moment.tz vevent.fields['DTSTART'], VEvent.icalDTUTCFormat, 'UTC'
                    end = moment.tz vevent.fields['DTEND'], VEvent.icalDTUTCFormat, 'UTC'
                
                # Format, only RRule doesn't use UTC
                if vevent.fields['RRULE']?
                    event.timezone = timezone
                    event.start = start.format Event.ambiguousDTFormat
                    event.end = end.format Event.ambiguousDTFormat
                else
                    event.start = start.toISOString()
                    event.end = end.toISOString()

        catch e then return undefined

        if vevent.fields['RRULE']?
            try # RRule may fail.
                options = RRule.parseString vevent.fields["RRULE"]
                if options.freq is RRule.WEEKLY and not options.byweekday
                    options.byweekday = [
                        [RRule.SU 
                        RRule.MO 
                        RRule.TU 
                        RRule.WE
                        RRule.TH 
                        RRule.FR 
                        RRule.SA][moment(event.start).day()]
                    ]

                event.rrule = RRule.optionsToString options

            catch e then # skip rrule on errors.
                console.log "Fail RRULE parsing"
                console.log e

        # Alarms reminders.
        alarms = [] 
        vevent.subComponents.forEach (c) ->
            if c.name is not 'VALARM'
                return

            trigg = c.fields['TRIGGER']
            action = c.fields['ACTION']
            if (trigg and trigg.match(Event.alarmTriggRegex) and action in ['EMAIL', 'DISPLAY'])
                alarms.push trigg: trigg, action: action
        
        event.alarms = alarms if alarms 
        
        return event

    Event.extractEvents = (component) ->
        events = []
        component.walk (component) ->
            if component.name is 'VEVENT'
                events.push Event.fromIcal component

        return events
