ARCH		=x86_64
VARIANT		=debug
SOURCES		=$(wildcard src/*.d)
INSTDIR		=$(HOME)/bin
EXEEXT		=
APP		=jetbrains$(EXEEXT)
LINKS		=clion$(EXEEXT) \
		 idea$(EXEEXT) \
		 pycharm$(EXEEXT) \
		 rider$(EXEEXT)

OS		=$(shell uname | grep -Pi 'cygwin|msys' >/dev/null 2>&1 && echo windows || echo posix)

ifeq "$(OS)" "windows"
  EXEEXT	=.exe
endif

$(APP): $(SOURCES)
	dub build --arch=$(ARCH) --build=$(VARIANT)

install: $(APP)
	cp -v $(APP) "$(INSTDIR)"
	for link in $(LINKS); do ln -sf "$(INSTDIR)/$(APP)" "$(INSTDIR)/$${link}"; done

clean:
	rm -f *.exe dub.selections.json

realclean distclean: clean
	rm -rf .dub
