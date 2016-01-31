* check_cert_expiration_date.sh:
This script checks a SSL certificate for expiration date.
As arguments to the script you should set the domain name to check and the days prior to alarm.
The return will be OK (exit 0) or ERROR (exit 1).

openssl tool is required.

Note:
The function convert_to_mjd was published by 'randyding' member of linuxquestions.org. You can find the post here:
http://www.linuxquestions.org/questions/programming-9/compare-date-uusing-shell-programming-please-276744/#post1403252
