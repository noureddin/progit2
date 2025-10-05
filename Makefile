
docs/*.html: .realmake.sh .postprocess.pl ./preintro.md ./*.asc ./*/*.asc ./*/*/*/*.asc
	bash .realmake.sh

# switching between prod & debug

switch:
	@perl -CDAS -pe 's/(?<=^PROD=)\S+/"$$&" eq "true" ? "false" : "true"/e' -i .realmake.sh
	@perl -CDAS -ne 'print if /^PROD=/' .realmake.sh

switch_debug:
	perl -CDAS -pe s/^PROD=true/PROD=false/ -i .realmake.sh

switch_production:
	perl -CDAS -pe s/^PROD=false/PROD=true/ -i .realmake.sh

# pdf production -- requires prod

a4.pdf: a4-.pdf
a5.pdf: a5-.pdf

a4: a4.pdf
a5: a5.pdf
pdf: a4 a5

# NOTE: it easily takes more than 1.25G of RAM to produce each pdf file (of only the translated half of the book!)

a%-.pdf: htmlpdfprint res/* docs/progit-all.html
	@echo    htmlpdfprint docs/progit-all.html $@ a$*  #  $@ = output file; $* = 4 or 5
	@python3 htmlpdfprint docs/progit-all.html $@ a$* 2>/dev/null  # ignore (false) warnings

a%.pdf: a%-.pdf docs/progit-all.html pdfmarks.pl
	perl pdfmarks.pl $< $@
	# cp $< $@  # used for debugging, instead of the above line, to speed up the pdf building
	cp --force --link $@ docs/progit2-ar-$@

.PHONEY:  switch switch_debug switch_production  pdf a4 a5

