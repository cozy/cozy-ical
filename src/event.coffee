moment = require 'moment-timezone'
timezones = require './timezones'
RRule = require('rrule').RRule

module.exports = (Event) ->
    {VCalendar, VEvent, VAlarm} = require './index'

    Event::toIcal = ->
        # Return undefined if mandatory elements miss.

        # Stay in event locale timezone for recurrent events.
        timezone = 'UTC' # Default for non recurrent events.
        if @rrule and @timezone
            timezone = @timezone
            # CAUTION recurrent event wihtout timezone is invalid.

        try
            event = new VEvent(
                moment.tz(@start, timezone),
                moment.tz(@end, timezone),
                @description, @place, @id, @details, 
                @start.length == 10, # allDay
                @rrule, @timezone)
        catch e then return undefined # all those elements are mandatory.
 
        @alarms?.forEach (alarm) =>
            if alarm.action in ['DISPLAY', 'BOTH']
                event.add new VAlarm(alarm.trigg, 'DISPLAY', @description)

            # if alarm.action in ['EMAIL', 'BOTH']
            #     event.add new VAlarm(alarm.trigg, 'EMAIL',
            #     "#{@description} #{@details}",
            #     'example@example.com',#TODO : get the user address.
            #     @description)


        return event

    Event.fromIcal = (vevent) ->
        # @return a valid Event object, or undefined.

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
                event.start = moment.tz(vevent.fields['DTSTART'], VEvent.icalDateFormat, 'GMT').format(Event.dateFormat)
                event.end = moment.tz(vevent.fields['DTEND'], VEvent.icalDateFormat, 'GMT').format(Event.dateFormat)
                # end ...
            else 
                timezone = vevent.fields['DTSTART-TZID']
                timezone = 'UTC' unless timezones[timezone] #Filter by timezone list ...
                
                if timezone != 'UTC'
                    start = moment.tz(vevent.fields['DTSTART'], VEvent.icalDTFormat, timezone)
                    end = moment.tz(vevent.fields['DTEND'], VEvent.icalDTFormat, timezone)

                else
                    start = moment.tz(vevent.fields['DTSTART'], VEvent.icalDTUTCFormat, 'UTC')
                    end = moment.tz(vevent.fields['DTEND'], VEvent.icalDTUTCFormat, 'UTC')
                
                # Format, only RRule doesn't use UTC
                if 'RRULE' of vevent.fields
                    event.timezone = timezone
                    event.start = start.format(Event.ambiguousDTFormat)
                    event.end = end.format(Event.ambiguousDTFormat)
                else
                    event.start = start.toISOString()
                    event.end = end.toISOString()

        catch e then return undefined

        if 'RRULE' of vevent.fields
            options = RRule.parseString vevent.fields["RRULE"]
            if options.freq == RRule.WEEKLY and not options.byweekday
        # rrule = rrule.split(';').filter((s) -> s.indexOf('DTSTART') != 0).join(';')
        
                options.byweekday = [[RRule.SU, RRule.MO, RRule.TU, RRule.WE,RRule.TH, RRule.FR, RRule.SA][moment(event.start).day()]]

            event.rrule = RRule.optionsToString options

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

    Event.extractEvents = (component) ->
        events = []
        component.walk (component) ->
            if component.name is 'VEVENT'
                events.push Event.fromIcal component

        events
