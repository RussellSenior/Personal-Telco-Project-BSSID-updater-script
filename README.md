Personal-Telco-Project-BSSID-updater-script
===========================================

A perl script that automates the scraping of PTP related network data from wigle.net

The script is currently broken, in that it fails to follow up query results that return
only the first 100 responses.  One of the queries currently returns about 800.  The script 
needs to grab the "next" link until there are no more results.

To function, the user must provide their own auth cookie string and sid code near the top 
of the script.  These can be found by registering a wigle account and then sniffing a 
browser sesssion.  It may be necessary or helpful to turn off gzip compression in your 
browser prior to doing so, unless wireshark has become more clever than when I did it last.

The ptp-bssid-with-notes file is a tab-delimited version the current state of our node data
suitable for integration with an existing wiki page:

  https://personaltelco.net/wiki/PersonalTelcoBssids

Yes, this is incredibly hacky.  However, it was effective.
