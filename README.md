# UncleKryon-server
Server (and Hacker) for the Uncle Kryon Android project.
Tasks include sending push notifications, building the database, and parsing/hacking the websites for the data.

# temporary
Fedora:
- http://www.nokogiri.org/tutorials/installing_nokogiri.html
- sudo yum install -y gcc ruby-devel zlib-devel

Fedora Service:
- https://fedoraproject.org/wiki/Systemd#How_do_I_customize_a_unit_file.2F_add_a_custom_unit_file.3F

Folders to add:
- /fedora/(unclekryon.service)

[Compression]
Compress yaml for storage in apk:
So far, 7zip is the best, but just use normal settings, not ultra, for more compatibility.
xz is most compatible with Linux and what Fedora uses, but probably don't need to preserve Linux file props.
Use apache commons-compress for using 7zip in Android.

bzip2 --best -k kryon.yaml
zip -9 kryon.zip kryon.yaml
7za a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on kryon_ultra.7z kryon.yaml
xz -k kryon.yaml
lzma -k kryon.yaml
