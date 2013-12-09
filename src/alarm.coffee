time = require 'time'
moment = require 'moment'

module.exports = (Alarm) ->
    {VCalendar, VTodo, VAlarm, VTimezone} = require './index'

    Alarm.getICalCalendar = ->
        calendar = new VCalendar 'Cozy Cloud', 'Cozy Agenda'

    Alarm::timezoneToIcal = () ->
        date = new time.Date @trigg
        vtimezone = new VTimezone date, @timezone
        vtimezone

    Alarm::toIcal = (timezone) ->
        date = new time.Date @trigg
        date.setTimezone timezone, false
        vtodo = new VTodo date, @id, @description, @details
        vtodo.addAlarm date
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
        alarms = []
        component.walk (component) ->
            if component.name is 'VTIMEZONE'
                timezone = component.fields["TZID"]
            if component.name is 'VTODO'
                alarms.push Alarm.fromIcal component, timezone
        alarms
