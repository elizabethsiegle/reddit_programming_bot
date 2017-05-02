This Reddit slack bot uses the [Linklater](https://github.com/hlian/linklater) API to return a trending Reddit story (using this [Reddit API](https://github.com/intolerable/reddit)) related to programming, and whatever query you pass. 
So, /reddit javascript would return a hot JS story from Reddit (including its link, score, and more), and /reddit tennis would return a trending story about tennis from the programming section. 

To run, clone the repo, *stack build*, *stack exec redditbot*, and then open up a Ngrok tunnel. You'll need a [Slack incoming webhook](https://api.slack.com/incoming-webhooks), too.

Slack steps:
1. After going to *your apps* in the top righthand corner of https://api.slack.com, and selecting the bot you want (or creating a new one),select *incoming webhooks* to generate your web hook. Put this in a file called hook. ![webhook](https://cloud.githubusercontent.com/assets/8932430/25603467/0a42ce9e-2eca-11e7-9ad2-fdc7cb1b00d1.png) 
2. Right below that, you should this on the left-hand side.
![slashcommands](https://cloud.githubusercontent.com/assets/8932430/25603307/9a7197f4-2ec8-11e7-9e19-826e47ff3936.png)

Select *slash commands* underneath features.

3. Put your ngrok URL under *Request URL*, fill in some of the optional spots, and you're good to go!
![ngrokurl](https://cloud.githubusercontent.com/assets/8932430/25603293/701ea5b4-2ec8-11e7-8ae6-c39a720c165a.png)

You should end up with something like this:
![tennisfireballreddit](https://cloud.githubusercontent.com/assets/8932430/25603194/a82e942e-2ec7-11e7-8e63-5d68b6dd972e.png)
![haskellreddit](https://cloud.githubusercontent.com/assets/8932430/25603221/ce158076-2ec7-11e7-9a78-2f9fc2765709.png)

Try it out for yourself! 
