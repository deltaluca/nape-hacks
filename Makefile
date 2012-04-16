swc:
	haxe -cp src -cp / -cp ../nape/externs --macro "include('nape.hacks')" -swf hacks.swc -swf-version 10 --dead-code-elimination

haxelib:
	cd src ; \
	rm -f nape-hackslib.zip ; \
	zip -r nape-hackslib . ; \
	haxelib test nape-hackslib.zip
