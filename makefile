programName=emb-oled
confDir=etc/$(programName)
systemdServiceDir=etc/systemd/system
systemPath=/usr/local/bin

#Macro to check the exit code of a make expression and possibly not fail on warnings
RC      := test $$? -lt 100 


build: compile

install: build configure perlDeploy scriptsLink serviceEnable

perlDeploy:
	./Build installdeps
	./Build install

compile:
	#Build Perl modules
	perl Build.PL
	./Build

test:
	prove -Ilib -I. t/*.t

configure:
	mkdir -p /$(confDir)
	cp $(confDir)/server.conf /$(confDir)/server.conf
	cp $(systemdServiceDir)/$(programName).service /$(systemdServiceDir)/$(programName).service

unconfigure:
	rm -r /$(confDir) || $(RC)

serviceEnable:
	systemctl daemon-reload
	systemctl enable $(programName)
	systemctl start $(programName)

serviceDisable:
	systemctl stop $(programName)
	rm /$(systemdServiceDir)/$(programName).service
	systemctl daemon-reload

scriptsLink:
	cp scripts/oled_server $(systemPath)/
	cp scripts/oled_client.pl $(systemPath)/

scriptsUnlink:
	rm $(systemPath)/oled_server
	rm $(systemPath)/oled_client.pl

clean:
	./Build realclean

uninstall: unconfigure scriptsUnlink serviceDisable clean

