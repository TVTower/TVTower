![TVTower - Ein Tribut an Mad TV | A tribute to Mad TV.](https://cloud.githubusercontent.com/assets/2625226/5182437/c1ddaea0-74a2-11e4-8cbf-0e66ad375505.png)
=======


###Deutsch
Du bist Manager eines Fernsehsenders in diesem __kostenlosen Spiel__ . Lenke was gesendet wird und wann. Verdiene Geld durch Werbeeinnahmen und treibe die Konkurrenz in den Bankrott. Hole Zuschauer vor die Flimmerkiste in dem Du branntheisse Nachrichtenstories sendest und mit spannenden Livesendungen Millionen von Mitmenschen am Einschlafen hinterst. Fertigprodukte aus Hollywood sind nicht so dein Ding? Tja, Eigenproduktionen koennten Quotenhits werden - oder aber teure Millionengraeber.

###English
In this __free game__ you are the manager of a television channel. Control what gets broadcasted and when. Earn Money with commercial breakups and drive your opponents into bankruptcy. Broadcast top stories in your news block or live shows keeping your audience from falling asleep. You dislike convenience products made in Hollywood - no problem - running your own products might lead to new stars of the ratings - or a costly white elephant.

####Spielen / How to Play
execute (mark executable before, if needed)
- Linux (1): TVTowerdownload/TVTower_Linux32 (PulseAudio)
- Linux (2): TVTowerdownload/TVTower_Linux64 (NG-build, PulseAudio, not available in older releases)
- Linux (3): TVTowerdownload/TVTower_Linux32_noPulseAudio (without libpulseaudio-dependency)
- Windows (1): TVTowerdownload/TVTower_Win32.exe
- Windows (2): TVTowerdownload/TVTower_Win32_DirectX7.bat (force DX7 if misconfigured before)
- Windows (3): TVTowerdownload/TVTower_Win32_DirectX9.bat (dito)
- Windows (4): TVTowerdownload/TVTower_Win32_DirectX11.bat (dito)
- Windows (5): TVTowerdownload/TVTower_Win32_OpenGL.bat (dito)
- Mac: TVTowerdownload/TVTower.app

Older releases (including up to 0.3.2) only contain `TVTower/TVTower_noPulseAudio` (Linux 32Bit) and no NG/64Bit-build. Also the naming scheme does not contain the OS (so `TVTower.exe` instead of `TVTower_Win32.exe`)


#####Linux
Users of Ubuntu 64Bit wanting to run the 32bit variants might install all dependencies via `sudo apt-get install libxxf86vm1:i386 libfreetype6:i386 libasound2:i386 libpulse0:i386 libgl1-mesa-glx:i386 libasound2-data:i386 libasound2-plugins:i386`.

Users of ArchLinux (or Manjaro Linux) in 64 bit might have problems running TVTower (32 bit). If you run these distros in a VM or with an Intel GPU the graphics context is bugged and leads to an segfault. This does _not_ happen with "NG"-builds of TVTower (issue still under research).
  
#####Windows/Mac
Should run without further requirements


####Für weitere Details | For further details:
- Homepage (+Downloads Linux/Mac/Linux): http://www.tvtower.org
- Forum: http://www.gamezworld.de/phpforum

![Screenshot](https://cloud.githubusercontent.com/assets/2625226/5182430/b714aa28-74a2-11e4-9409-e99083dc677e.png)

***

LICENCE
=======

TVTower uses a "restricted" zLib/LibPNG-licence:

This software is provided 'as-is'. No warranty is given.
The authors cannot be held liable for any damages arising from
the use of this software.

Permission is granted to anyone to use this software for any
purpose, and to alter it and redistribute it freely, subject to
the following restrictions:

	1. Any commercial usage requires explicit permission from
	   the original authors.

	2. The origin of this software must not be misrepresented;
	   you must not claim that you wrote the original software.
	   If you use this software in a product, an acknowledgment
	   in the product is required.

	3. Altered source or binary versions of this software must
	   be plainly marked as such, and must not be misrepresented
	   as being the original software.

	4. This notice may not be removed or altered from any source
	   distribution.
