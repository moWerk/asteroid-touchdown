# xz, not zstd: rpm on SailfishOS 3.4 can not unpack zstd payloads
%define _binary_payload w6.xzdio

Name:       harbour-asteroid-touchdown
Summary:    Touchdown, a tilt controlled lunar lander
Version:    1.2.0
Release:    1
License:    GPLv3+
URL:        https://github.com/moWerk/asteroid-touchdown
Source0:    %{name}-%{version}.tar.bz2
BuildArch:  noarch
Requires:   sailfishsilica-qt5 >= 0.10.9
Requires:   libsailfishapp-launcher
Requires:   nemo-qml-plugin-configuration-qt5
Requires:   qt5-qtdeclarative-import-sensors
Requires:   libkeepalive
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  desktop-file-utils

%description
Touchdown is a lunar lander game: tilt the device to fire the engines
and set the ship down on the pad. Ported from AsteroidOS.

%if 0%{?_chum}
Title: Touchdown
Type: desktop-application
DeveloperName: moWerk
Categories:
 - Game
 - ArcadeGame
Custom:
  Repo: https://github.com/moWerk/asteroid-touchdown
PackageIcon: https://raw.githubusercontent.com/moWerk/asteroid-touchdown/sailfishos/store/icon-172x172.png
AIRating: V
AINote: The SailfishOS port was written by an LLM (Claude), directed and play-tested by the author on real devices; every commit carries an LLMGD disclosure line (see the README). The title art is AI-generated.
Screenshots:
 - https://raw.githubusercontent.com/moWerk/asteroid-touchdown/sailfishos/store/screenshot-start-1080x2400.jpg
 - https://raw.githubusercontent.com/moWerk/asteroid-touchdown/sailfishos/store/screenshot-action-1080x2400.jpg
 - https://raw.githubusercontent.com/moWerk/asteroid-touchdown/sailfishos/store/screenshot-gameover-1080x2400.jpg
Links:
  Homepage: https://github.com/moWerk/asteroid-touchdown/tree/sailfishos
  Bugtracker: https://github.com/moWerk/asteroid-touchdown/issues
%endif

%prep
%setup -q -n %{name}-%{version}

%build
%qmake5
%make_build

%install
%qmake5_install
desktop-file-install --delete-original \
    --dir %{buildroot}%{_datadir}/applications \
    %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
