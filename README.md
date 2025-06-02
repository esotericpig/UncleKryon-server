# UncleKryon-server

Server (and Hacker) for the Uncle Kryon mobile apps.

Tasks include sending push notifications, building the database, and scraping the websites for the data.

## Contents
- [Setup](#setup)
- [Hacking](#hacking)
- [License](#license)

## [Setup](#contents)

**Nokogiri:**

[Installing Nokogiri.](https://www.nokogiri.org/tutorials/installing_nokogiri.html)

Alternatively, you can run one of the rake tasks:

```
$ bundle exec rake nokogiri_apt   # Ubuntu / Debian
$ bundle exec rake nokogiri_dnf   # Fedora / CentOS / Red Hat
$ bundle exec rake nokogiri_other
```

## [Hacking](#contents)

```
$ git clone 'https://github.com/esotericpig/UncleKryon-server.git'
$ cd UncleKryon-server
$ bundle install
$ bundle exec rake -T
```

## [License](#contents)
[GNU GPL v3+](LICENSE)

> UncleKryon-server (https://github.com/esotericpig/UncleKryon-server)  
> Copyright (c) 2017-2022 Bradley Whited  
> 
> UncleKryon-server is free software: you can redistribute it and/or modify  
> it under the terms of the GNU General Public License as published by  
> the Free Software Foundation, either version 3 of the License, or  
> (at your option) any later version.  
> 
> UncleKryon-server is distributed in the hope that it will be useful,  
> but WITHOUT ANY WARRANTY; without even the implied warranty of  
> MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the  
> GNU General Public License for more details.  
> 
> You should have received a copy of the GNU General Public License  
> along with UncleKryon-server.  If not, see <https://www.gnu.org/licenses/>.  
