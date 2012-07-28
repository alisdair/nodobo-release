# Contents

* Introduction
* Recreation
* Database schema
* Anonymisation
* Software and studies

# Introduction

Nodobo-2011-01-v1 is the data gathered during a study of the mobile phone usage of 27 high-school students, from September 2010 to February 2011. This dataset includes 13035 call records, 83542 message records, 5292103 presence records, and other related data.

All code in this release is licensed under the terms in LICENSE.txt. We ask that if you use this dataset for research, you cite the most relevant Nodobo publication available. You can find a list of our publications on our website at:

  http://nodobo.com/

If you have any questions, or if you find any bugs in the code or discrepancies in the data, please contact us through the website.

Alisdair McDiarmid <alisdair@mcdiarmid.org>
James Irvine <j.m.irvine@strath.ac.uk>
University of Strathclyde


# Recreation

db.sqlite3.dump.bz2 is a bzipped SQL dump of the sqlite3 database. You can recreate the database by doing the following:

    bzcat db.sqlite3.dump.bz2 | sqlite3 db.sqlite3

The resulting db.sqlite3 file will be approximately 1GB. We have prepared a Ruby interface for this dataset, which enables casual investigation of the data. More details on using this are in the section on "nodobo.rb" below.


# Database schema

The following tables are used:

## Calls and Messages

* other_id: id of the other user on the call (NULL if not in the study)
* number: phone number of the other end of the call/message (related: Users#number)
* duration: length of the call in seconds
* length: number of characters in the message

## CellTowers

* cellid: GSM base transceiver station CID
* lac: location area code

## Devices

* imei: blank for this release of the data
* mac: Bluetooth MAC (related: Presences#mac)

## Presences

* other_id: user_id of the detected device (NULL if not in the study)
* mac: Bluetooth MAC (related: Devices#mac)
* bluetooth_class: reported class of the device
* name: human-readable name of the device

## Users

* name: "Anonymous" for this release of the data
* number: phone number of the study user (related: Calls#number, Messages#number)

## Wifis

* ssid: human-readable name of the base station
* bssid: base station MAC

## All tables

* The database schema follows ActiveRecord conventions: tables are plurals, foreign keys are singular_id, each table has an id primary key and created_at/updated_at timestamps.

* user_id is used to indicate which user recorded the interaction.

* Calls and messages tables have two timestamp columns. The call_timestamp/message_timestamp is the one recorded by the phone when the call/message was originally recorded. The timestamp column in the time at which the calldb/smsdb synchronisation occurred (which is less useful).

* Some tables have an "interaction" column. This was used for database synchronising and is left in for internal debugging purposes.


# Anonymisation

This section of the document describes how we transformed the data to anonymise its contents.

Note: we have not munged timestamps or added random noise to the data to achieve any kind of k-anonymity.

The following fields have been altered to remove personal information from the dataset:

* Call#number, Message#number, User#number
* Device#mac, Presence#mac
* Wifi#bssid
* Presence#name
* Wifi#ssid
* CellTower#cellid
* CellTower#lac

Each real value for these fields maps 1:1 to a randomly-generated anonymous value. The process for generating these values is as follows:

* Phone number: random number with the same number of digits; if original number is 3 or more digits, keep the original first 2 digits
* MAC address: 12 random hex digits
* Bluetooth name/Wifi ssid: random sequence of dictionary words, same number of words as original name
* Cell ID and LAC: random number with the same number of digits

## Location Information

For this release of the data, we have been fairly cautious about data anonymisation. In the future we may release the real CID/LAC/BSSID information, to better allow location and movement patterns to be estimated.


# Software and studies

Also included in the dataset download are programs for three sample studies. These are detailed below.

Each program can be run with ruby: for example, "ruby conversation-length.rb". The programs assume that your current working directory is the one with the database and the nodobo.rb code.

Software used:

* Ruby 1.8.7 or later, with gems: activerecord, sqlite3-ruby, progressbar
* gnuplot 4.4
* GraphViz 2.22


## Ruby interface: nodobo.rb

We have supplied a simple ActiveRecord interface to the database, "nodobo.rb". This gives classes and relations for each of the types of data in the dataset.

The interface can be used by running "irb -r ./nodobo.rb", or by using "require 'nodobo'" in your own programs. A sample irb session is given below:

    >> u = User.find(19)
    => #<User id: 19, name: "Anonymous", number: "07102745960", created_at: "2010-11-11 10:19:34", updated_at: "2010-11-11 10:19:34">
    >> u.calls.size
    => 976
    >> study_calls = u.calls.select {|c| c.other != nil }; study_calls.size
    => 133
    >> Hash[study_calls.group_by(&:other_id).map {|k,v| [k, v.size]}]
    => {16=>2, 19=>1, 25=>2, 14=>4, 21=>124}
    >> v = User.find(21)
    => #<User id: 21, name: "Anonymous", number: "07456622368", created_at: "2010-11-11 10:19:35", updated_at: "2010-11-11 10:19:35">
    >> v.calls.select {|c| c.other != nil }.size
    => 175

Note that this interface is not particularly efficient, and is intended for basic exploration of the data. We have added indices to the database to improve performance where possible, but many computations (especially those involving presence data) still require significant CPU time.


## Conversation Length

This study examines the number of messages in an SMS conversation. A recent publication with a smaller dataset found that most SMS conversations are two messages long, with the number of conversations rapidly decreasing as the conversation length increases. Our data reproduces this result.

Results are output to the csv directory, and plots can be shown with "gnuplot conversation-length.gnuplot".


## Daily/Hourly Stats

We binned calls, messages, and presence by hours of the day and days of the week. This shows how the study users use different aspects of their phones.

Results are output to the csv directory, and plots can be shown with "gnuplot daily-hourly-stats.gnuplot".


## Dichotomous Social Graph

Our most complex program is an initial attempt to estimate the social graph of the study users. This is achieved by using three dichotomous links between users: one each for calls, messages, and presence.

For calls and messages, a link exists between two users if A has contact B, and B has contacted A: reciprocal communications. For presence, a link exists if the users were in proximity on a certain percentage of days, for a certain number of minutes (these parameters default to 4/7 days and 30 minutes per day).

This study is by far the most computationally expensive, and with this naive implementation will take around an hour on a top-end workstation.

Results are output to "dichotomous-social-graph.dot", a dot-format network description, which can be inspected manually or rendered as a graph with GraphViz or other visualisation software.
