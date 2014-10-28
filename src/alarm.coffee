moment = require 'moment-timezone'
timezones = require './timezones'

module.exports = (Alarm) ->
    {VCalendar, VTodo, VAlarm, VTimezone} = require './index'

    Alarm.getICalCalendar = (name='Cozy Agenda') ->
        calendar = new VCalendar
            organization: 'Cozy Cloud'
            title: name

    # Cozy alarms are VAlarm nested in implicit VTodo,
    # with trigg is VTodo.DTSTART and VAlarm.trigger is PT0M.
    # Return VTodo object or undefined if mandatory elements miss.
    Alarm::toIcal = ->

        timezone = 'GMT' # only UTC.
        try startDate = moment.tz @trigg, timezone
        catch e
            console.log 'Can\'t parse alarm.trigg field.'
            console.log e
            return undefined

        vtodo = new VTodo
            startDate: startDate
            id: @id
            summary: @description

        if @action in ['DISPLAY', 'BOTH']
            vtodo.addAlarm
                action: 'DISPLAY'
                description: @description

        if @action in ['EMAIL', 'BOTH'] and @getAttendeesEmail?
            @getAttendeesEmail().forEach (email) =>
                vtodo.addAlarm
                    action: 'EMAIL'
                    description: "#{@description} " + (@details or '')
                    attendee: "mailto:#{email}"
                    summary: @description

        return vtodo

    Alarm.fromIcal = (vtodo) ->
        alarm = new Alarm()
        alarm.id = vtodo.fields["UID"] if vtodo.fields["UID"]
        alarm.description = vtodo.fields["SUMMARY"] or
                            vtodo.fields["DESCRIPTION"]

        if not alarm.description
            console.log 'No alarm.description from iCal.'
            return undefined

        try # .trigg is required.
            timezone = vtodo.fields['DTSTART-TZID']
            # Filter by timezone list.
            timezone = 'UTC' unless timezones[timezone]

            if timezone isnt 'UTC'
                alarm.trigg = moment.tz(
                    vtodo.fields['DTSTART'],
                    VAlarm.icalDTFormat,
                    timezone
                ).toISOString()

            else
                alarm.trigg = moment(
                    vtodo.fields['DTSTART'],
                    VAlarm.icalDTUTCFormat
                ).toISOString()
        catch e
            console.log 'Can\'t construct alarm.trigg from iCal.'
            console.log e
            return undefined

        valarms = vtodo.subComponents.filter (c) -> c.name is 'VALARM'
        if valarms.length is 0
            # Only VTodo with VAlarm can be usefull in cozy.
            console.log 'iCal VTodo hasn\'t VAlarm.'
            return undefined

        else
            # We clean here valarms list, to keep only ones with
            # - supported trigger duration,
            # - supported actions,
            # Also, handle cozy-specific 'BOTH' action.
            # Fill the set actions, with filtered actions.
            actions = valarms.reduce (actions, valarm) ->
                if actions['BOTH']? # We already got all actions we can handle.
                    return actions

                # Filter durations uncompatibles with cozy alarm object.
                if (valarm.fields['TRIGGER'] not in [
                    'PT0M', '-PT0M', 'PT0S', '-PT0S', '-PT0H', '-PT0H'])
                    return actions

                # Filter action and convert to cozy specific 'BOTH' if needed.
                action = valarm.fields['ACTION']

                if action is 'DISPLAY'
                    if actions['EMAIL']?
                        actions = 'BOTH': true
                    else
                        actions[action] = true
                if action is 'EMAIL'
                    if actions['DISPLAY']?
                        actions = 'BOTH': true
                    else actions[action] = true

                return actions
            , {} # initialize actions set.

            actions = Object.keys actions # Convert set to array.

            if actions.length is 0
                console.log 'iCal VTodo hasn\'t alarm compatibles.'
                return undefined

            else
                alarm.action = actions

        return alarm

    Alarm.extractAlarms = (component) ->
        alarms = []
        component.walk (component) ->
            if component.name is 'VTODO'
                alarm = Alarm.fromIcal component
                alarms.push alarm if alarm? # to skip unreadable VTodo.

        return alarms
