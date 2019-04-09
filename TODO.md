# TODO | UncleKryon-server

- [ ] Download option to download mp3s to /stock, in case URLs change.
- [ ] 2019 aums
- [ ] 2018 aums
- [x] 2017 aums
- [x] 2016 aums
- [ ] 2015 aums
- [ ] 2014 aums
- [ ] 2013 aums
- [ ] 2012 aums
- [ ] 2011 aums
- [ ] 2010 aums
- [ ] 2009 aums
- [ ] 2008 aums
- [ ] 2007 aums
- [ ] 2006 aums
- [ ] 2002-2005 aums
- [ ] [The Parables of Kryon aums](http://www.kryon.com/cartprodimages/downloadParables.html)
- [ ] [The Lightworker's Handbook Channeling Series aums](http://www.kryon.com/k_25b.html)
- [ ] [Lemurian Sisterhood aums](https://amberwolfphd.com/lemurian-sisterhood/ls-audio-and-transcripts)
- [ ] Option to convert YAML files to JSON for server/app.
- [ ] Server option to continuously check [Kryon aums download page](http://audio.kryon.com/en/); maybe also do for Lemurian Sisterhood? One command checks all sites and separate commands check each individual site (for debugging).
- [ ] If update something by hand, need manual option to send push notifications to apps and update server's DB.

## Create systemd (fedora) service

Create a systemd service that runs once. Then have the server code run internally every X time.

Could attach it to rails server instead?

Helpful links:

- [Understanding & administering systemd](https://docs.fedoraproject.org/en-US/quick-docs/understanding-and-administering-systemd/)
- [systemd unit file basics](https://fedoramagazine.org/systemd-getting-a-grip-on-units/)
- [Packaging::Systemd#Unit_Files](https://fedoraproject.org/wiki/Packaging:Systemd#Unit_Files)

Folders to add:

- /fedora/(unclekryon.service)
