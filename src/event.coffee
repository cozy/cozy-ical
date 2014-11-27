moment = require 'moment-timezone'
{RRule} = require 'rrule'

module.exports = (Event) ->
    {VCalendar, VEvent, VAlarm} = require './index'

    # Return VEvent object or undefined if mandatory elements miss.
    Event::toIcal = (timezone = 'UTC') ->
        allDay = @start.length is 10

        # Recurring events must be in local timezone.
        if @rrule
            if @timezone?
                timezone = @timezone

            else if not allDay
                console.log "Recurring events need timezone."
                return undefined

        timezone = @timezone or timezone

        rrule = if @rrule? then RRule.parseString @rrule else null
        mappedAttendees = @attendees?.map (attendee) ->
            return email: attendee.email, status: attendee.status

        created = @created or null
        lastModification = @lastModification or null
        stampDate = @lastModification or moment().tz('UTC')
        stampDate = moment.tz(stampDate, 'UTC').toDate()

        try
            event = new VEvent
                stampDate: stampDate
                startDate: moment.tz @start, timezone
                endDate: moment.tz @end, timezone
                summary: @description
                location: @place
                uid: @id
                description: @details
                allDay: allDay
                rrule: rrule
                attendees: mappedAttendees
                timezone: timezone
                created: created
                lastModification: lastModification
        catch e
            console.log 'Can\'t parse event mandatory fields.'
            console.log e
            return undefined # all those elements are mandatory.

        @alarms?.forEach (alarm) =>
            if alarm.action in [VAlarm.DISPLAY_ACTION, 'BOTH']
                event.add new VAlarm
                    trigger: alarm.trigg
                    action: VAlarm.DISPLAY_ACTION
                    description: @description

            if alarm.action in [VAlarm.EMAIL_ACTION, 'BOTH'] \
            and @getAlarmAttendeesEmail?
                mappedAttendees = @getAlarmAttendeesEmail().map (email) ->
                    return email: email, status: 'ACCEPTED'
                console.log mappedAttendees
                event.add new VAlarm
                    trigger: alarm.trigg
                    action: VAlarm.EMAIL_ACTION
                    summary: @description
                    description: @details or ''
                    attendees: mappedAttendees

            # else : ignore other actions.

        return event

    # Return a valid Event object, or undefined.
    Event.fromIcal = (vevent, defaultCalendar = 'my calendar') ->
        event = new Event()
        {model} = vevent

        now =  moment().tz('UTC').toISOString()

        timezone = model.timezone or 'UTC'
        event.id = model.uid if model.uid?
        event.description = model.summary or ''
        event.details = model.description or ''
        event.place = model.location
        event.rrule = new RRule(model.rrule).toString()
        defaultCozyStatus = 'INVITATION-NOT-SENT'
        event.attendees = model.attendees?.map (attendee, index) ->
            status = attendee.details?.status or defaultCozyStatus
            status = defaultCozyStatus if status is 'NEEDS-ACTION'
            email = attendee.email
            id = index + 1
            contactid = null
            return {id, email, contactid, status}
        event.created = model.created if model.created?
        stampDate = moment.tz(model.stampDate, 'UTC').toISOString()
        event.lastModification = model.lastModification \
                                 or stampDate \
                                 or now

        if model.allDay
            event.start = moment.tz model.startDate, 'UTC'
                .format Event.dateFormat
            event.end = moment.tz model.endDate, 'UTC'
                .format Event.dateFormat
        else
            if timezone isnt 'UTC'
                start = moment.tz model.startDate, timezone
                end = moment.tz model.endDate, timezone
            else
                start = moment.tz model.startDate, 'UTC'
                end = moment.tz model.endDate, 'UTC'

            # Format, only RRule doesn't use UTC
            if model.rrule?
                event.timezone = timezone
                event.start = start.format Event.ambiguousDTFormat
                event.end = end.format Event.ambiguousDTFormat
            else
                event.start = start.toISOString()
                event.end = end.toISOString()

        # Alarms reminders.
        alarms = []
        vevent.subComponents.forEach (component) ->
            if component.name is not 'VALARM'
                return

            alarmModel = component.model
            trigg = alarmModel.trigger
            action = alarmModel.action

            if trigg and trigg.match(Event.alarmTriggRegex)
                alarms.push trigg: trigg, action: action

        event.alarms = alarms if alarms
        event.tags = [defaultCalendar]

        return event

    Event.extractEvents = (component, defaultCalendar = 'my calendar') ->
        events = []
        component.walk (component) ->
            if component.name is 'VEVENT'
                events.push Event.fromIcal component, defaultCalendar

        return events
