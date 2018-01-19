## Feedme Data

_Feed me, Jefferson_ is really about data and clever analysis of that data. 

It's one thing to build a web server and a user interface that can let users click on random pictures of food, it's an entirely different thing to serve up meaningful pictures of food that will help them figure out what they're hungry for in as few clicks as possible. 

The initial user interface and webservers were thrown together with some random images of food just so that we could start collecting our own food preferences and analyzing them. 

We can customize the log format, and feedback requests (to ourselves) to collect additional data, but at the moment all we really need to do is show that we can analyze basic webserver access logs to extract some meaning in the data.

### Apache Server Access Logs

The initial [`access_log`](access_log) contains clicks from three separate devices each running a single session (a total of three sesssions) concurrently. We can customize the details included in the access log, but requests to `/hunger.json` should really contain all of the details we need as is.

* query string parameters
    * searchSession -- a random number generated for an instance of a user search session (this should be different every time the same visitor returns)
    * chosen -- which of the two pictures of food presented the user thought looked more appetizing
    * notChosen -- which of the two pictures presented the user didn't click on because it looked less appetizing
* ip address -- this is sensitive data that we need to deal with in the future (the EU data directive considers it personal information)
* user agent -- this is pretty unique to a user (or at least a users device) and when combined with an ip address and hashed could provide a fairly persistent, semi annonymous proxy for a distinct individual/device across sessions

### Abstract Real World Relations

In the real world we have real people with real tastes/preferences that tend not to change too much over time, but appetites/moods that come and go or change quickly depending on a number of contextual details. 

For instance, many people prefer _breakfast food_ in the morning and _dinner food_ in the evening, but what breakfast and dinner food means differs from person to person -- in other words, appetite could partially be a function of personal taste and time of day.

As another example of changing appetites, many people have cravings that increase over time until those cravings are satiated, but sometimes during the process of satisfying a craving, we often over-eat that thing which we crave and we grow sick of it and won't want it for a while. So our appetite for something may partly be a function of how recently we've consumed it and how much of it we've consumed. 

Both of the above examples would require us to model personal preferences -- which would itself require at the very least some minimum ability to distinctly identify and track individuals and their behavior over time. Short of providing authentication and user accounts where users explicitly give us their consent to track these details for the purposes of giving them better personalized recommendations, we can to some extent use their device finger print (a hashed combination of user agent and ip address) to semi anonymously track and identify them over time. We would expect the tastes/preferences associated with this id to be somewhat stable over time, but once again, for the moods or appetites associated with individual searches (sessions) to jump around a lot, but generally be centered around the individuals more stable long term tastes.

The general model in my head is very much one based on _collaborative filtering_. People who like _pizza_ may also like _ice cream_, but more importantly, people who would rather have _pizza_ than _ice cream_ right now, would probably rather have a _hamburger_ than _cake_ right now. Rather than simply using collaborative filtering to map out a space of foods based on the people who like them, we intend to map out that food space based on both people __and__ their ephemeral appetites. 