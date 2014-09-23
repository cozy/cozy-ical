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

    Alarm.fromIcal = (valarm, timezone = "UTC") ->
        alarm = new Alarm()
        alarm.id = valarm.fields["UID"] if valarm.fields["UID"]
        alarm.description = valarm.fields["SUMMARY"] or
                            valarm.fields["DESCRIPTION"]
        alarm.details = valarm.fields["DESCRIPTION"] or
                        valarm.fields["SUMMARY"]

        date = valarm.fields["DTSTAMP"]
        date = moment(date, "YYYYMMDDTHHmm00")
        triggerDate = new time.Date new Date(date), timezone
        alarm.trigg = triggerDate.toString().slice(0, 24)
        alarm.timezone = timezone
        alarm

    Alarm.extractAlarms = (component, timezone) ->
        timezone = 'UTC' unless timezones[timezone]
        alarms = []
        component.walk (component) ->
            if component.name is 'VTIMEZONE' \
            and component.fields["TZID"]? \
            and timezones[component.fields["TZID"]]
                timezone = component.fields["TZID"]
            else if component.name is 'VTODO'
                alarms.push Alarm.fromIcal component, timezone
        alarms
