# MLBpayrollVSrecordBOT
Twitter bot that posts the two teams most overperforming and underperforming expectations of payroll.

This bot relies heavily on the great work of the rtweet package.  However, in order to create and post via a bot from R you must have a developer account with Twitter and gain access to the API.  Twitter API v2 is very different from earlier version(s) and lacks much of the functionality.  The rtweet package is still catching up to those changes.

Includes code to post figure (as .png) showing linear relationship (or lack thereof) between win percentage (record) and payroll for the entire league.  However, rtweet does not yet have the functionality to post images under Twitter API v2.  Code will be updated as soon as functionality is added.
