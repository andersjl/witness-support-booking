# Witness Support Booking


Copyright (c) 2013 Anders Lindeberg

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This is a simple Ruby-on-Rails application for witness support organizations
to define need for witness support, and for volunteers to register and book
their support sessions.

I.e., it is *not intended for booking witness support*, but rather "witness
supporters".

It should be straightforward to convert this to a more general volunteer
booking application, but there are already a lot of those.  The raison d'être
for this application is exactly that it is *not* general.

It is tailored to the needs at Swedish courts.  See "Customization" below for
how to tailor it to your needs.

## Installation

### Development

The Ruby version and all gem dependencies are defined in the `Gemfile`.  If
you have the correct ruby, simply fork, cd to the application directory, and

    bundle install
    bundle exec rake db:reset
    bundle exec rake db:populate
    rails server

The `db:populate` task populates the database with sample data to get you
going.  To be able to log in, look in `lib/tasks/sample_data.rake` for the
passwords.

### Test

After installing for development,

    bundle exec rake db:test:prepare

and you are ready to run the test suite, see "Testing" below.

### Production

Depends on your production environment, of course.  To install at Heroku is
almost just a `git push`, but note that the default configuration is to use
SSL and read the key from the environment variable
`WITNESS_SUPPORT_BOOKING_SECRET`.

After installing an empty database, start the web server and use the browser
to register yourself as a user.  Then start a rails console and

    User.first.update_attribute :role, "master"

You can now log in, change the default court name and link, create other
courts, promote registered users to administrate their court's witness support
etc.

## Testing

There is an extensive Rspec test suite,

    bundle exec rspec spec

These tests rely heavily on the application being configured for the need at
Swedish courts.  Any serious customization (see "Customization" below) should
include an extensive rewrite of the test suite to make it more general,
especially independent of the set of standard court sessions during a day.

## Core concepts

The concepts modeled are as below.  "ID" means that the attribute(s) are
unique for an instance.  The database id is something quite different.

### Court

Just a name (ID) and a link to a court.

### User

A user ID is the combination of a court and an email.  A volunteer that
supports witnesses at more than one court has several totally independent
users in the application, one for each court.  The email is not used in the
application and can actually be any string.

A user has one of four roles, "disabled", "normal", "admin", or "master".  A
disabled user has signed up but cannot do anything, a normal user is a witness
support volunteer, an admin user defines the needs for witness support at one
court, and a master user can do anything at any court.

### Court Session

The ID is the combination of a court and a start time.  It also has a need
attribute, the number of volunteers required.

(In the database the start time is split into the date and seconds from
midnight in local time.  See "Customization" below for why.)

### Court Day Note

The ID is the combination of a court and a date.  A text giving any relevant
information.

### Booking

This is a simple many-to-many relationship, the ID is the combination of a
user and a court session.

## Customization

### Localization

In `config/application.rb` you should change `config.time_zone` and
`config.i18n.default_locale` to suit your country and language, and download
the corresponding file(s) to `config/locales`.

The applicaion uses the JQuery Datepicker.  To avoid loading tons of
javascript, only the required localizations of datepicker should be loaded by
inserting a line

    //= require jquery.ui.datepicker-xx

(where "xx" is your language) in `app/assets/javascripts/application.js`. You
must also edit `app/assets/javascripts/court_days.js` to actually use the 
relevant datepicker localization.

### Language

Some files under `app/views` have language specific variants.  (E.g.
`app/views/static_pages/about.sv.html.erb`.)  Either translate the Swedish
file or, in case you cannot read Swedish, try to figure out what your language
specific variant should contain from the corresponding unlocalized file.
(E.g. `app/views/static_pages/about.html.erb`.)

You should also translate one of (preferably) `config/locales/app_sv.yml` or 
`config/locales/app_en.yml`.

### Court Session

The current implementation is tailored to the Swedish courts where it is used.
It has a fixed schedule with two sessions each weekday, AM and PM.  They are
identified by the start times 29700 (08:15 AM) and 44100 (12:15 PM).  This 
schedule is hardcoded in the views, but *not in the controllers and models*.

There are various obvious ways to customize the court sessions.  You can have
a fixed schedule with three or four sessions a day, or you can make a UI that
accepts arbitrary session start times and adapts to that.  Anyway you will
need to rewrite the UI, probably susbstituting something more sophisticated
for the present Bootstrap-based.

If you find that you need to change the controllers or models to get the
schedule you need - *treat that as a bug*.

The only existing connection between the schedule and the localization should
be the keys `court_session.name29700` and `court_session.name44100`, which are
used to find the session names and are computed in the views as e.g.
`"court_session.name#{ session.start}.short"`.

### Other models

No customization (except translation of `config/locales/app_sv.yml`)
anticipated.

