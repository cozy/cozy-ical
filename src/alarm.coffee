moment = require 'moment-timezone'

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
            uid: @id
            stampDate: moment.tz moment(), 'UTC'
            summary: @description

        if @action in ['DISPLAY', 'BOTH']
            vtodo.addAlarm
                action: 'DISPLAY'
                description: @description
                trigger: 'PT0M'

        if @action in ['EMAIL', 'BOTH'] and @getAttendeesEmail?
            mappedAttendees = @getAttendeesEmail().map (email) ->
                return "mailto:#{email}"
            vtodo.addAlarm
                action: 'EMAIL'
                description: @description
                attendee: mappedAttendees
                summary: @description
                trigger: 'PT0M'

        return vtodo

    Alarm.fromIcal = (vtodo) ->
        alarm = new Alarm()
        todoModel = vtodo.model
        alarm.id = todoModel.uid if todoModel.uid?
        alarm.description = todoModel.summary or todoModel.description

        if not alarm.description
            console.log 'No alarm.description from iCal.'
            return undefined

        try # .trigg is required.
            timezone = vtodo.timezone

            if timezone isnt 'UTC'
                alarm.trigg = moment.tz todoModel.startDate, timezone
                    .toISOString()
            else
                alarm.trigg = moment.tz todoModel.startDate, 'UTC'
                    .toISOString()
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
                    return 'BOTH'

                # Filter action and convert to cozy specific 'BOTH' if needed.
                action = valarm.model.action
                if action is 'DISPLAY'
                    if actions['EMAIL']?
                        return 'BOTH'
                    else
                        actions[action] = true
                if action is 'EMAIL'
                    if actions['DISPLAY']?
                        return 'BOTH'
                    else actions[action] = true

                return actions
            , {} # initialize actions set.

            actions = Object.keys actions # Convert set to array.

            if actions.length is 0
                console.log 'iCal VTodo hasn\'t alarm compatibles.'
                return undefined
            else
                actions = actions.shift() if actions.length is 1
                alarm.action = actions

        alarm.tags = ['my calendar']
        return alarm

    Alarm.extractAlarms = (component) ->
        alarms = []
        component.walk (component) ->
            if component.name is 'VTODO'
                alarm = Alarm.fromIcal component
                alarms.push alarm if alarm? # to skip unreadable VTodo.
        return alarms
