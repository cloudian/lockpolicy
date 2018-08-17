PWD=$(shell pwd)
VER=1.0
NAME=Cloudian-LockPolicy
PNAME=$(NAME)-$(VER)
RPMTOP=~/rpmbuild/
SPEC=lockpolicy


clean: 
	rm -rf $(PNAME) $(PNAME)*rpm 


diff: clean
	git diff > diffs.txt
	nedit diffs.txt &


install: 
	echo "destdir=$(DESTDIR)"
	mkdir -p $(DESTDIR)/usr/bin
	install -m 755 *.sh $(DESTDIR)/usr/bin/
	install -m 755 *.pl $(DESTDIR)/usr/bin/
	

rpms: clean
	#begin standard prep
	mkdir -p $(PNAME)
	cp Makefile $(PNAME)/Makefile
	cp *.pl $(PNAME)/
	cp *.sh $(PNAME)/
	touch $(PNAME)/configure
	chmod 755 $(PNAME)/configure
	#end standard prep
	
	tar -cvp $(PNAME) -f - | gzip > $(RPMTOP)/SOURCES/$(PNAME).tar.gz
	rpmbuild -ba ./$(SPEC).spec --target noarch
	mv -vf $(RPMTOP)/RPMS/noarch/$(NAME)-* .
	mv -vf $(RPMTOP)/SRPMS/$(NAME)-* .


