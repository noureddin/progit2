
docs/*.html: .realmake.sh ./*.asc ./*/*.asc ./*/*/*/*.asc
	bash .realmake.sh

switch_debug:
	perl -CDAS -pe s/^PROD=true/PROD=false/ -i .realmake.sh

switch_production:
	perl -CDAS -pe s/^PROD=false/PROD=true/ -i .realmake.sh

.PHONEY: switch_debug switch_production

