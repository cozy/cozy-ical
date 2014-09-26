moment = require 'moment-timezone'
timezones = require './timezones'

module.exports = (Alarm) ->
    {VCalendar, VTodo, VAlarm, VTimezone} = require './index'

    Alarm.getICalCalendar = (name='Cozy Agenda') ->
        calendar = new VCalendar 'Cozy Cloud', name

    Alarm::timezoneToIcal = () ->
        date = new time.Date @trigg
        vtimezone = new VTimezone date, @timezone
        vtimezone

    Alarm::toIcal = ->
        # Cozy alarms are VAlarm nested in implicit VTodo,
        # with trigg == VTodo.DTSTART ; and VAlarm.trigger == PT0M.

        # If recurrent alarms : timezone = (if @rrule then @timezone else 'GMT')
        timezone = 'GMT' # only UTC.
        startDate = moment.tz(@trigg, timezone)
        vtodo = new VTodo startDate, @id, @description, @details

        if @action in ['DISPLAY', 'BOTH']
            vtodo.addAlarm('DISPLAY', @description)

        if @action in ['EMAIL', 'BOTH']
            vtodo.addAlarm('EMAIL', 
                "#{@description} #{@details}",
                'example@example.com',#TODO : get the user address.
                @description)
        
        vtodo

    Alarm.fromIcal = (vtodo) ->
        alarm = new Alarm()
        alarm.id = vtodo.fields["UID"] if vtodo.fields["UID"]
        alarm.description = vtodo.fields["SUMMARY"] or
                            vtodo.fields["DESCRIPTION"]
        alarm.details = vtodo.fields["DESCRIPTION"] or
                        vtodo.fields["SUMMARY"]

        alarm.trigg = moment(vtodo.fields['DTSTART'], VAlarm.icalDTUTCFormat).toISOString() # TODO defensive !?

        valarms = vtodo.subComponents.filter (c) -> c.name is 'VALARM'
        if valarms # TODO : if no action ?
            alarm.action == valarms[0].fields['ACTION']

        alarm

    Alarm.extractAlarms = (component, timezone) ->
        timezone = 'UTC' unless timezones[timezone]
        alarms = []
        component.walk (component) ->
            if component.name is 'VTODO'
                alarms.push Alarm.fromIcal component, timezone
        alarms
