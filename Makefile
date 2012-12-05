.PHONY: test
test:
	haxe -cp src -lib nape -swf test.swf -swf-version 10 --no-inline -debug -D NAPE_ASSERT -main Main -D haxe3
	debugfp test.swf

swc:
	haxe -cp src -cp / -cp ../nape/externs --macro "include('nape.hacks')" -swf nape-hacks.swc -swf-version 10 --dce full -D nape_swc -D haxe3

haxelib:
	cd src ; \
	rm -f nape-hackslib.zip ; \
	zip -r nape-hackslib . ; \
	haxelib test nape-hackslib.zip

clean:
	rm nape-hacks.swc
	rm test.swf
