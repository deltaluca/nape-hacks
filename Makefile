.PHONY: test
test:
	haxe -cp src -lib nape -swf test.swf -swf-version 10 --no-inline -debug -D NAPE_ASSERT -main Main
	debugfp test.swf

swc:
	haxe -cp src -cp / -cp $(NAPE_EXTERNS) --macro "include('nape.hacks')" -swf hacks.swc -swf-version 10 --dead-code-elimination -D nape_swc

haxelib:
	cd src ; \
	rm -f nape-hackslib.zip ; \
	zip -r nape-hackslib . ; \
	haxelib test nape-hackslib.zip

tar:
	rm -rf nape-hacks.tar.gz
	tar cvfz nape-hacks.tar.gz src Makefile version
