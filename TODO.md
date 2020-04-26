# TODO | UncleKryon-server

## [v1.0.0]
- [ ] Download option to download mp3s to /stock/, in case URLs change.
- [x] "World" option if no country/continent.
- [x] Option to change "updated_on" in /hax/ to all same date time.
- [ ] 2002-2019 aums
- [ ] [The Parables of Kryon aums](http://www.kryon.com/cartprodimages/downloadParables.html)
- [ ] [The Lightworker's Handbook Channeling Series aums](http://www.kryon.com/k_25b.html)
- [ ] [Lemurian Sisterhood aums](https://amberwolfphd.com/lemurian-sisterhood/ls-audio-and-transcripts)
- [ ] Add [Glossary](https://www.monikamuranyi.com/glossary)?
- [ ] Add Monika Muranyi artist & [articles](https://www.monikamuranyi.com/articles)?
- [ ] Add Kryon [announcements](https://www.kryon.com/announce2.html)?
- [ ] unclekryon srv (all/specific one)
    - Check `/dir/`; if there is a new one, send an email; update config file (ignored by git)
    - Run every X seconds w/ systemd service file
- [ ] unclekryon json (options)
    - Convert yaml hax data to json
- [ ] unclekryon up (options)
    - Upload/update database w/ new data (json)
- [ ] unclekryon push (options)
    - Push new data out to mobile

## Deprecated
- [ ] Option to convert YAML files to JSON/DB for server/app.
- [ ] Server option to check [Kryon aums download page](http://audio.kryon.com/en/); maybe also do for Lemurian Sisterhood? One command checks all sites and separate commands check each individual site (for debugging).
- [ ] Option to send push notifications to apps and update server's DB.
- [ ] Command line options:
    - [ ] hax kryon scroll main; hax lems aum main; hax ssb scroll year
        - lems = lemurian sisterhood; ssb = saytha sai baba
    - [ ] unclekryon srv
        - Uses site dir and current year; default is just help.
        - unclekryon srv (save to kryon_&lt;release&gt;.yaml &amp; to DB using config file for user/pass)
    - [ ] unclekryon up
        - unclekryon up --dir x --file x kryon/lems/ssb (upload kryon.yaml to database)
        - -l/-g take in arg of kryon/lems/ssb
        - unclekryon up --local /-l kryon (save to DB file for Android app)
        - unclekryon up --global/-g kryon (save to DB network; use config file for user/pass)
