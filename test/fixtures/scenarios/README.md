# Building a scenario

A scenario is an export from an iCal provider based on the same data set.

If you want to add a scenario for another iCal provider, create a calendar with the following elements, export it and submit a pull request.

Please note that in this document, date are in the format "year-month-day"

## Event 1
* On 2014-11-05 from 14:00 to 15:00 UTC (set the time in your own timezone)
* Title: "Dentist"
* Location: "Dentist office"
* Alarm 1:
    * type "message", 15 minute before
    * type "email", 1 day before

## Event 2
* On 2014-11-06 from 11:00 to 12:00 UTC (set the time in your own timezone)
* Title: "Recurring event"
* Description: "Crawling a hidden dungeon"
* Location: "Hidden dungeon"
* Recurrence option: weekly, until 2015-01-01

## Event 3
* On 2014-11-07, "all day" event
* Title: "Friend's birthday"
* Description: "Bring a present!"
* Location: "Friend's appartment"
* Reccurrence option: yearly, forever
* Attendees: randomgirl@provider.tld and randomguy.provider.tld
