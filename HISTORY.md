Note on history
===============

I wanted to change my work email to private, so I've rebuild the repository ground up. 
I'd already pushed stuff to GitHub, so I recreated the repo their.
Original `git log` was:

	commit 4ac89601de389fb9763e98e741ac6e30fd100bd8 (HEAD -> master, origin/master, origin/HEAD)
	Author: Doeke Zanstra <doeke@archipunt.nl>
	Date:   Fri Dec 29 16:43:28 2017 +0100

	    Bugfixes and added automated tests
    
	    - Version 0.4
	    - Renamed `--opt-out` to `--forbidden`, use `-` to allow all
	    - Re-added `--no-header`
	    - Atomic logging
	    - Logging now call, caller
	    - Renamed `test` folder to `test-files`

	commit 9459b9ad185af14690bbeebaa7bada8244802f79
	Author: Doeke Zanstra <doeke@archipunt.nl>
	Date:   Tue Dec 26 17:06:35 2017 +0100

	    Some polishing
    
	    - added EXIT trap
	    - works now completely from stdin/out
	    - added --no-header option
	    - renamed blacklist to opt-out
	    - script version
	    - working with a temp-directory now
	    - setup: added log rotate option

	commit b2126422d3fe9be4f04c6952e48a301b22994389
	Author: Doeke Zanstra <doeke@archipunt.nl>
	Date:   Tue Dec 26 14:46:43 2017 +0100

	    Fixed some bugs, and added logging

	commit 271e7a9bbc32ea08f2562254850400a79d1c9f04
	Author: Doeke Zanstra <doeke@archipunt.nl>
	Date:   Mon Dec 25 18:09:02 2017 +0100

	    Oops
    
	    Because of `setup.sh`, the `.sh` extensions are not necessary in the git config.

	commit 6222cf5a06d7bb1d2223279d644e794c16c9778b
	Author: Doeke Zanstra <doeke@archipunt.nl>
	Date:   Mon Dec 25 18:07:27 2017 +0100

	    Added setup and test-files

	commit 47f6ca73d57468bbeaa9a072f9dbd55647f9adc1
	Author: Doeke Zanstra <doeke@archipunt.nl>
	Date:   Mon Dec 25 18:05:47 2017 +0100

	    First version of the osagitfilter

	commit bbfd6ff6dadd57b86b41542e177bdde4bcc86af0
	Author: Doeke Zanstra <doeke@archipunt.nl>
	Date:   Mon Dec 25 17:36:17 2017 +0100

	    My initial git-ascr-filter.sh
    
	    Put in for sentimental reasons

	commit f44a9b7a1e49d4a60b6514521accee6c4cada94e
	Author: Doeke Zanstra <doekman@icloud.com>
	Date:   Mon Dec 25 11:43:40 2017 +0100

	    Initial commit
